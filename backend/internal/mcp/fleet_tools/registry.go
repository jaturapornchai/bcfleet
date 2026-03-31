package fleet_tools

import (
	"context"
	"fmt"
)

// ToolDefinition คำอธิบาย MCP tool
type ToolDefinition struct {
	Name        string      `json:"name"`
	Description string      `json:"description"`
	InputSchema interface{} `json:"inputSchema"`
}

// ToolHandler ฟังก์ชัน handler สำหรับแต่ละ tool
type ToolHandler func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error)

// ToolRegistry เก็บ tool definitions และ handlers
type ToolRegistry struct {
	tools    map[string]ToolHandler
	toolList []ToolDefinition
}

// NewToolRegistry สร้าง ToolRegistry ใหม่
func NewToolRegistry() *ToolRegistry {
	return &ToolRegistry{
		tools:    make(map[string]ToolHandler),
		toolList: make([]ToolDefinition, 0),
	}
}

// Register ลงทะเบียน tool พร้อม handler
func (r *ToolRegistry) Register(def ToolDefinition, handler ToolHandler) {
	r.tools[def.Name] = handler
	r.toolList = append(r.toolList, def)
}

// List คืน definitions ทั้งหมด
func (r *ToolRegistry) List() []ToolDefinition {
	return r.toolList
}

// Count คืนจำนวน tools ที่ลงทะเบียน
func (r *ToolRegistry) Count() int {
	return len(r.toolList)
}

// Call เรียก tool handler ด้วยชื่อ
func (r *ToolRegistry) Call(ctx context.Context, name, shopID string, params map[string]interface{}) (interface{}, error) {
	handler, ok := r.tools[name]
	if !ok {
		return nil, fmt.Errorf("tool not found: %s", name)
	}
	if params == nil {
		params = make(map[string]interface{})
	}
	return handler(ctx, shopID, params)
}

// --- helpers สำหรับ tools ดึงค่าจาก params ---

func getString(params map[string]interface{}, key string) string {
	v, ok := params[key]
	if !ok {
		return ""
	}
	s, _ := v.(string)
	return s
}

func getInt(params map[string]interface{}, key string, defaultVal int) int {
	v, ok := params[key]
	if !ok {
		return defaultVal
	}
	switch n := v.(type) {
	case int:
		return n
	case float64:
		return int(n)
	case int64:
		return int(n)
	}
	return defaultVal
}

func getBool(params map[string]interface{}, key string) bool {
	v, ok := params[key]
	if !ok {
		return false
	}
	b, _ := v.(bool)
	return b
}

func getFloat(params map[string]interface{}, key string, defaultVal float64) float64 {
	v, ok := params[key]
	if !ok {
		return defaultVal
	}
	switch n := v.(type) {
	case float64:
		return n
	case int:
		return float64(n)
	case int64:
		return float64(n)
	}
	return defaultVal
}

func getStringSlice(params map[string]interface{}, key string) []string {
	v, ok := params[key]
	if !ok {
		return nil
	}
	raw, ok := v.([]interface{})
	if !ok {
		return nil
	}
	result := make([]string, 0, len(raw))
	for _, item := range raw {
		if s, ok := item.(string); ok {
			result = append(result, s)
		}
	}
	return result
}
