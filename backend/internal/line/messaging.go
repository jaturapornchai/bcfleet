package line

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

const (
	lineAPIBase = "https://api.line.me/v2/bot"
)

// MessagingClient ส่งข้อความกลับไปยัง LINE users
type MessagingClient struct {
	channelToken string
	httpClient   *http.Client
}

// NewMessagingClient สร้าง MessagingClient ใหม่
func NewMessagingClient(token string) *MessagingClient {
	return &MessagingClient{
		channelToken: token,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// ---- Message Types ----

// ReplyRequest โครงสร้าง request สำหรับ reply
type ReplyRequest struct {
	ReplyToken string        `json:"replyToken"`
	Messages   []interface{} `json:"messages"`
}

// PushRequest โครงสร้าง request สำหรับ push
type PushRequest struct {
	To       string        `json:"to"`
	Messages []interface{} `json:"messages"`
}

// TextMessage ข้อความธรรมดา
type TextMessage struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// FlexMessage Flex Message สำหรับ rich UI
type FlexMessage struct {
	Type        string      `json:"type"`
	AltText     string      `json:"altText"`
	Contents    interface{} `json:"contents"`
}

// FlexBubble bubble container
type FlexBubble struct {
	Type   string      `json:"type"`
	Body   *FlexBox    `json:"body,omitempty"`
	Footer *FlexBox    `json:"footer,omitempty"`
	Header *FlexBox    `json:"header,omitempty"`
}

// FlexBox container box
type FlexBox struct {
	Type     string        `json:"type"`
	Layout   string        `json:"layout"` // "vertical", "horizontal"
	Contents []interface{} `json:"contents"`
}

// FlexText text component
type FlexText struct {
	Type   string `json:"type"`
	Text   string `json:"text"`
	Weight string `json:"weight,omitempty"` // "bold"
	Size   string `json:"size,omitempty"`   // "sm", "md", "lg", "xl"
	Color  string `json:"color,omitempty"`
	Wrap   bool   `json:"wrap,omitempty"`
}

// FlexButton button component
type FlexButton struct {
	Type   string      `json:"type"`
	Style  string      `json:"style,omitempty"` // "primary", "secondary", "link"
	Action FlexAction  `json:"action"`
}

// FlexAction action สำหรับ button/interactive elements
type FlexAction struct {
	Type    string `json:"type"`   // "message", "postback", "uri"
	Label   string `json:"label"`
	Text    string `json:"text,omitempty"`
	Data    string `json:"data,omitempty"`
	URI     string `json:"uri,omitempty"`
}

// ---- Reply Methods ----

// ReplyText ตอบกลับด้วยข้อความธรรมดา
func (m *MessagingClient) ReplyText(replyToken, text string) error {
	req := ReplyRequest{
		ReplyToken: replyToken,
		Messages: []interface{}{
			TextMessage{Type: "text", Text: text},
		},
	}
	return m.doRequest(lineAPIBase+"/message/reply", req)
}

// ReplyFlex ตอบกลับด้วย Flex Message
func (m *MessagingClient) ReplyFlex(replyToken string, flex FlexMessage) error {
	req := ReplyRequest{
		ReplyToken: replyToken,
		Messages:   []interface{}{flex},
	}
	return m.doRequest(lineAPIBase+"/message/reply", req)
}

// ReplyMessages ตอบกลับด้วยหลาย messages (สูงสุด 5)
func (m *MessagingClient) ReplyMessages(replyToken string, messages []interface{}) error {
	if len(messages) > 5 {
		messages = messages[:5]
	}
	req := ReplyRequest{
		ReplyToken: replyToken,
		Messages:   messages,
	}
	return m.doRequest(lineAPIBase+"/message/reply", req)
}

// PushText ส่ง push message ข้อความธรรมดา
func (m *MessagingClient) PushText(userID, text string) error {
	req := PushRequest{
		To: userID,
		Messages: []interface{}{
			TextMessage{Type: "text", Text: text},
		},
	}
	return m.doRequest(lineAPIBase+"/message/push", req)
}

// PushFlex ส่ง push Flex Message
func (m *MessagingClient) PushFlex(userID string, flex FlexMessage) error {
	req := PushRequest{
		To:       userID,
		Messages: []interface{}{flex},
	}
	return m.doRequest(lineAPIBase+"/message/push", req)
}

// ---- Helper: Build Flex Messages ----

// BuildVehicleAvailabilityFlex สร้าง Flex สำหรับแสดงรถว่าง
func BuildVehicleAvailabilityFlex(plate, vehicleType, driverName string, price float64, altText string) FlexMessage {
	return FlexMessage{
		Type:    "flex",
		AltText: altText,
		Contents: FlexBubble{
			Type: "bubble",
			Header: &FlexBox{
				Type:   "box",
				Layout: "vertical",
				Contents: []interface{}{
					FlexText{Type: "text", Text: "รถว่างสำหรับท่าน", Weight: "bold", Size: "lg", Color: "#1DB446"},
				},
			},
			Body: &FlexBox{
				Type:   "box",
				Layout: "vertical",
				Contents: []interface{}{
					FlexText{Type: "text", Text: fmt.Sprintf("ทะเบียน: %s", plate), Size: "md", Weight: "bold"},
					FlexText{Type: "text", Text: fmt.Sprintf("ประเภท: %s", vehicleType), Size: "sm"},
					FlexText{Type: "text", Text: fmt.Sprintf("คนขับ: %s", driverName), Size: "sm"},
					FlexText{Type: "text", Text: fmt.Sprintf("ค่าขนส่ง: %.0f บาท", price), Size: "md", Color: "#FF6B35", Weight: "bold"},
				},
			},
			Footer: &FlexBox{
				Type:   "box",
				Layout: "horizontal",
				Contents: []interface{}{
					FlexButton{
						Type:  "button",
						Style: "primary",
						Action: FlexAction{
							Type:  "postback",
							Label: "จองเลย",
							Data:  fmt.Sprintf("action=book_vehicle&plate=%s", plate),
						},
					},
					FlexButton{
						Type:  "button",
						Style: "secondary",
						Action: FlexAction{
							Type:  "message",
							Label: "ต่อรองราคา",
							Text:  fmt.Sprintf("ขอต่อรองราคาสำหรับรถ %s", plate),
						},
					},
				},
			},
		},
	}
}

// BuildTripStatusFlex สร้าง Flex สำหรับแสดงสถานะเที่ยววิ่ง
func BuildTripStatusFlex(tripNo, status, driverName, plate, origin, destination string) FlexMessage {
	statusColor := "#1DB446"
	if status == "pending" {
		statusColor = "#FF9500"
	} else if status == "cancelled" {
		statusColor = "#FF3B30"
	}

	return FlexMessage{
		Type:    "flex",
		AltText: fmt.Sprintf("สถานะงาน %s", tripNo),
		Contents: FlexBubble{
			Type: "bubble",
			Body: &FlexBox{
				Type:   "box",
				Layout: "vertical",
				Contents: []interface{}{
					FlexText{Type: "text", Text: fmt.Sprintf("งาน %s", tripNo), Weight: "bold", Size: "md"},
					FlexText{Type: "text", Text: fmt.Sprintf("สถานะ: %s", translateTripStatus(status)), Color: statusColor, Weight: "bold"},
					FlexText{Type: "text", Text: fmt.Sprintf("คนขับ: %s", driverName), Size: "sm"},
					FlexText{Type: "text", Text: fmt.Sprintf("รถ: %s", plate), Size: "sm"},
					FlexText{Type: "text", Text: fmt.Sprintf("จาก: %s", origin), Size: "sm"},
					FlexText{Type: "text", Text: fmt.Sprintf("ถึง: %s", destination), Size: "sm"},
				},
			},
		},
	}
}

// translateTripStatus แปลงสถานะเป็นภาษาไทย
func translateTripStatus(status string) string {
	switch status {
	case "draft":
		return "ร่าง"
	case "pending":
		return "รอคนขับ"
	case "accepted":
		return "รับงานแล้ว"
	case "started":
		return "เริ่มงานแล้ว"
	case "arrived":
		return "ถึงที่รับสินค้า"
	case "delivering":
		return "กำลังส่งสินค้า"
	case "completed":
		return "ส่งมอบแล้ว"
	case "cancelled":
		return "ยกเลิก"
	default:
		return status
	}
}

// ---- Internal ----

func (m *MessagingClient) doRequest(url string, payload interface{}) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal error: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, url, bytes.NewBuffer(data))
	if err != nil {
		return fmt.Errorf("create request error: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+m.channelToken)

	resp, err := m.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("http request error: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("LINE API error status: %d", resp.StatusCode)
	}

	return nil
}
