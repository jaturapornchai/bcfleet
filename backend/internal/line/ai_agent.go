package line

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

const (
	claudeAPIURL  = "https://api.anthropic.com/v1/messages"
	maxIterations = 10
	agentTimeout  = 120 * time.Second

	systemPromptThai = `คุณเป็นผู้ช่วย AI ของระบบขนส่ง SML Fleet สำหรับ SME ไทย

หน้าที่ของคุณ:
- ตอบคำถามเกี่ยวกับรถขนส่ง คนขับ และเที่ยววิ่ง
- ค้นหารถว่าง ตรวจสอบสถานะงาน
- ช่วยจองเที่ยวรถและคำนวณค่าขนส่ง
- แจ้งเตือนการซ่อมบำรุงและเอกสารหมดอายุ
- สรุปต้นทุนและรายงานผล

กฎการตอบ:
- ตอบเป็นภาษาไทยเสมอ กระชับ ตรงประเด็น
- ถ้าต้องการข้อมูลเพิ่มเติมให้ถามผู้ใช้
- ถ้าไม่แน่ใจให้บอกว่าไม่ทราบ อย่าเดา
- ใช้ตัวเลขที่แม่นยำจาก tools เท่านั้น
- ตอบสั้น ไม่เกิน 500 คำ เหมาะสำหรับ LINE`
)

// ToolRegistry interface สำหรับเรียก MCP tools
// (ใช้ interface เพื่อไม่ผูกกับ mcp package โดยตรง — ป้องกัน circular import)
type ToolRegistry interface {
	ListTools() []MCPTool
	CallTool(ctx context.Context, name string, args map[string]interface{}) (interface{}, error)
}

// MCPTool โครงสร้าง tool สำหรับส่งให้ Claude
type MCPTool struct {
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	InputSchema map[string]interface{} `json:"input_schema"`
}

// AIAgent ผู้ช่วย AI ที่ใช้ Claude + MCP tools
type AIAgent struct {
	anthropicKey string
	model        string
	mcpRegistry  ToolRegistry
	httpClient   *http.Client
}

// NewAIAgent สร้าง AIAgent ใหม่
func NewAIAgent(apiKey, model string, registry ToolRegistry) *AIAgent {
	return &AIAgent{
		anthropicKey: apiKey,
		model:        model,
		mcpRegistry:  registry,
		httpClient: &http.Client{
			Timeout: agentTimeout,
		},
	}
}

// ---- Claude API Structs ----

// ClaudeRequest โครงสร้าง request ไปยัง Claude API
type ClaudeRequest struct {
	Model     string          `json:"model"`
	MaxTokens int             `json:"max_tokens"`
	System    string          `json:"system"`
	Messages  []ClaudeMessage `json:"messages"`
	Tools     []MCPTool       `json:"tools,omitempty"`
}

// ClaudeMessage ข้อความใน conversation
type ClaudeMessage struct {
	Role    string        `json:"role"` // "user" หรือ "assistant"
	Content []ClaudeBlock `json:"content"`
}

// ClaudeBlock block ใน message
type ClaudeBlock struct {
	Type      string      `json:"type"`               // "text", "tool_use", "tool_result"
	Text      string      `json:"text,omitempty"`
	ID        string      `json:"id,omitempty"`        // สำหรับ tool_use
	Name      string      `json:"name,omitempty"`      // สำหรับ tool_use
	Input     interface{} `json:"input,omitempty"`     // สำหรับ tool_use
	ToolUseID string      `json:"tool_use_id,omitempty"` // สำหรับ tool_result
	Content   interface{} `json:"content,omitempty"`   // สำหรับ tool_result
}

// ClaudeResponse response จาก Claude API
type ClaudeResponse struct {
	ID           string         `json:"id"`
	Type         string         `json:"type"`
	Role         string         `json:"role"`
	Content      []ClaudeBlock  `json:"content"`
	Model        string         `json:"model"`
	StopReason   string         `json:"stop_reason"` // "end_turn", "tool_use", "max_tokens"
	Usage        ClaudeUsage    `json:"usage"`
}

// ClaudeUsage token usage
type ClaudeUsage struct {
	InputTokens  int `json:"input_tokens"`
	OutputTokens int `json:"output_tokens"`
}

// Chat ส่งข้อความและรับการตอบ (พร้อม tool calling loop)
func (a *AIAgent) Chat(ctx context.Context, shopID, userID, message string) (string, error) {
	if ctx == nil {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(context.Background(), agentTimeout)
		defer cancel()
	}

	// สร้าง system prompt ที่มี context ของ shop
	systemPrompt := fmt.Sprintf("%s\n\nShop ID: %s | User ID: %s", systemPromptThai, shopID, userID)

	// เตรียม messages
	messages := []ClaudeMessage{
		{
			Role:    "user",
			Content: []ClaudeBlock{{Type: "text", Text: message}},
		},
	}

	// ดึง tools จาก MCP registry
	var tools []MCPTool
	if a.mcpRegistry != nil {
		tools = a.mcpRegistry.ListTools()
	}

	// Tool calling loop — สูงสุด maxIterations รอบ
	for i := 0; i < maxIterations; i++ {
		req := ClaudeRequest{
			Model:     a.model,
			MaxTokens: 1024,
			System:    systemPrompt,
			Messages:  messages,
			Tools:     tools,
		}

		resp, err := a.callClaude(ctx, req)
		if err != nil {
			return "", fmt.Errorf("claude API error: %w", err)
		}

		// เพิ่ม assistant response เข้า history
		messages = append(messages, ClaudeMessage{
			Role:    "assistant",
			Content: resp.Content,
		})

		// ถ้า stop_reason != "tool_use" แสดงว่าตอบเสร็จแล้ว
		if resp.StopReason != "tool_use" {
			return a.extractTextResponse(resp.Content), nil
		}

		// มี tool_use — เรียก tools แล้วส่งผลกลับ
		toolResults, err := a.executeTools(ctx, shopID, resp.Content)
		if err != nil {
			log.Printf("[AI] tool execution error: %v", err)
			// ส่ง error กลับไปให้ Claude
			toolResults = a.buildErrorResults(resp.Content, err)
		}

		// เพิ่ม tool_result เข้า history
		messages = append(messages, ClaudeMessage{
			Role:    "user",
			Content: toolResults,
		})
	}

	return "ขออภัยครับ ระบบประมวลผลเกิน limit กรุณาถามใหม่", nil
}

// callClaude ส่ง request ไปยัง Claude API
func (a *AIAgent) callClaude(ctx context.Context, req ClaudeRequest) (*ClaudeResponse, error) {
	data, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, claudeAPIURL, bytes.NewBuffer(data))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", a.anthropicKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	resp, err := a.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Claude API status %d", resp.StatusCode)
	}

	var claudeResp ClaudeResponse
	if err := json.NewDecoder(resp.Body).Decode(&claudeResp); err != nil {
		return nil, fmt.Errorf("decode: %w", err)
	}

	return &claudeResp, nil
}

// executeTools เรียก MCP tools ตาม tool_use blocks
func (a *AIAgent) executeTools(ctx context.Context, shopID string, blocks []ClaudeBlock) ([]ClaudeBlock, error) {
	var results []ClaudeBlock

	for _, block := range blocks {
		if block.Type != "tool_use" {
			continue
		}

		// แปลง input เป็น map
		var args map[string]interface{}
		if block.Input != nil {
			inputBytes, err := json.Marshal(block.Input)
			if err == nil {
				json.Unmarshal(inputBytes, &args)
			}
		}
		if args == nil {
			args = make(map[string]interface{})
		}

		// เพิ่ม shop_id ใน args เสมอ
		args["shop_id"] = shopID

		log.Printf("[AI] calling tool: %s with args: %v", block.Name, args)

		// เรียก tool
		var resultContent interface{}
		if a.mcpRegistry != nil {
			result, err := a.mcpRegistry.CallTool(ctx, block.Name, args)
			if err != nil {
				resultContent = map[string]interface{}{
					"error": err.Error(),
				}
			} else {
				resultContent = result
			}
		} else {
			resultContent = map[string]interface{}{
				"error": "MCP registry not available",
			}
		}

		// ส่งผลกลับเป็น tool_result
		resultJSON, _ := json.Marshal(resultContent)
		results = append(results, ClaudeBlock{
			Type:      "tool_result",
			ToolUseID: block.ID,
			Content:   string(resultJSON),
		})
	}

	return results, nil
}

// buildErrorResults สร้าง tool_result สำหรับ error
func (a *AIAgent) buildErrorResults(blocks []ClaudeBlock, err error) []ClaudeBlock {
	var results []ClaudeBlock
	for _, block := range blocks {
		if block.Type != "tool_use" {
			continue
		}
		results = append(results, ClaudeBlock{
			Type:      "tool_result",
			ToolUseID: block.ID,
			Content:   fmt.Sprintf(`{"error": "%s"}`, err.Error()),
		})
	}
	return results
}

// extractTextResponse ดึงข้อความจาก response blocks
func (a *AIAgent) extractTextResponse(blocks []ClaudeBlock) string {
	for _, block := range blocks {
		if block.Type == "text" && block.Text != "" {
			return block.Text
		}
	}
	return "ขออภัยครับ ไม่สามารถประมวลผลได้ในขณะนี้"
}
