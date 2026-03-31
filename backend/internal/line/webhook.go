package line

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"io"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// WebhookHandler รับ events จาก LINE Messaging API
type WebhookHandler struct {
	channelSecret string
	channelToken  string
	aiAgent       *AIAgent
	messaging     *MessagingClient
}

// NewWebhookHandler สร้าง WebhookHandler ใหม่
func NewWebhookHandler(channelSecret, channelToken string, aiAgent *AIAgent) *WebhookHandler {
	return &WebhookHandler{
		channelSecret: channelSecret,
		channelToken:  channelToken,
		aiAgent:       aiAgent,
		messaging:     NewMessagingClient(channelToken),
	}
}

// WebhookBody โครงสร้าง body ที่ LINE ส่งมา
type WebhookBody struct {
	Destination string         `json:"destination"`
	Events      []WebhookEvent `json:"events"`
}

// WebhookEvent event แต่ละตัวจาก LINE
type WebhookEvent struct {
	Type       string      `json:"type"`
	ReplyToken string      `json:"replyToken"`
	Source     EventSource `json:"source"`
	Timestamp  int64       `json:"timestamp"`
	Message    *LineMessage `json:"message,omitempty"`
	Postback   *PostbackData `json:"postback,omitempty"`
}

// EventSource แหล่งที่มาของ event
type EventSource struct {
	Type    string `json:"type"` // "user", "group", "room"
	UserID  string `json:"userId"`
	GroupID string `json:"groupId,omitempty"`
	RoomID  string `json:"roomId,omitempty"`
}

// LineMessage ข้อความจาก LINE
type LineMessage struct {
	ID   string `json:"id"`
	Type string `json:"type"` // "text", "image", "sticker"
	Text string `json:"text,omitempty"`
}

// PostbackData ข้อมูล postback
type PostbackData struct {
	Data   string `json:"data"`
	Params map[string]string `json:"params,omitempty"`
}

// Handle รับ LINE webhook events
func (h *WebhookHandler) Handle(c *gin.Context) {
	// 1. อ่าน body
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cannot read body"})
		return
	}

	// 2. Verify signature
	if !h.verifySignature(body, c.GetHeader("X-Line-Signature")) {
		log.Printf("[LINE] invalid signature")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid signature"})
		return
	}

	// 3. Parse webhook body
	var wb WebhookBody
	if err := json.Unmarshal(body, &wb); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid json"})
		return
	}

	// 4. Process events
	for _, event := range wb.Events {
		go h.processEvent(event)
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// processEvent ประมวลผล event แต่ละตัว
func (h *WebhookHandler) processEvent(event WebhookEvent) {
	switch event.Type {
	case "message":
		h.handleMessage(event)
	case "follow":
		h.handleFollow(event)
	case "unfollow":
		h.handleUnfollow(event)
	case "postback":
		h.handlePostback(event)
	default:
		log.Printf("[LINE] unhandled event type: %s", event.Type)
	}
}

// handleMessage จัดการข้อความที่ผู้ใช้ส่งมา
func (h *WebhookHandler) handleMessage(event WebhookEvent) {
	if event.Message == nil {
		return
	}

	userID := event.Source.UserID
	replyToken := event.ReplyToken

	switch event.Message.Type {
	case "text":
		h.handleTextMessage(event.Message.Text, userID, replyToken)
	case "image":
		// ส่งข้อความตอบกลับว่ารับรูปได้แต่ยังไม่รองรับ
		if err := h.messaging.ReplyText(replyToken, "ขอบคุณสำหรับรูปภาพครับ กรุณาพิมพ์ข้อความเพื่อขอความช่วยเหลือ"); err != nil {
			log.Printf("[LINE] reply error: %v", err)
		}
	default:
		log.Printf("[LINE] unhandled message type: %s", event.Message.Type)
	}
}

// handleTextMessage จัดการข้อความตัวอักษร — ส่งไป AI agent
func (h *WebhookHandler) handleTextMessage(text, userID, replyToken string) {
	// shopID จะถูก resolve จาก userID ในระบบจริง
	// ตอนนี้ใช้ค่า default สำหรับ demo
	shopID := h.resolveShopID(userID)

	response, err := h.aiAgent.Chat(nil, shopID, userID, text)
	if err != nil {
		log.Printf("[LINE] AI agent error: %v", err)
		if replyErr := h.messaging.ReplyText(replyToken, "ขออภัยครับ เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง"); replyErr != nil {
			log.Printf("[LINE] reply error: %v", replyErr)
		}
		return
	}

	if err := h.messaging.ReplyText(replyToken, response); err != nil {
		log.Printf("[LINE] reply error: %v", err)
	}
}

// handleFollow จัดการเมื่อผู้ใช้ follow OA
func (h *WebhookHandler) handleFollow(event WebhookEvent) {
	welcomeMsg := "ยินดีต้อนรับสู่ SML Fleet ระบบจัดการรถขนส่งครับ!\n\n" +
		"สามารถถามข้อมูลได้เลย เช่น:\n" +
		"• มีรถ 6 ล้อว่างวันพรุ่งนี้ไหม\n" +
		"• ดูต้นทุนเที่ยวนี้\n" +
		"• แจ้งซ่อมรถ\n\n" +
		"หรือใช้เมนูด้านล่างเพื่อเข้าถึงฟีเจอร์ต่างๆ"

	if err := h.messaging.PushText(event.Source.UserID, welcomeMsg); err != nil {
		log.Printf("[LINE] welcome message error: %v", err)
	}
}

// handleUnfollow จัดการเมื่อผู้ใช้ unfollow
func (h *WebhookHandler) handleUnfollow(event WebhookEvent) {
	log.Printf("[LINE] user unfollowed: %s", event.Source.UserID)
}

// handlePostback จัดการ postback จาก Rich Menu หรือปุ่ม
func (h *WebhookHandler) handlePostback(event WebhookEvent) {
	if event.Postback == nil {
		return
	}

	data := event.Postback.Data
	userID := event.Source.UserID
	replyToken := event.ReplyToken

	switch data {
	case "action=check_vehicles":
		h.handleTextMessage("รถว่างมีอะไรบ้าง", userID, replyToken)
	case "action=book_trip":
		if err := h.messaging.ReplyText(replyToken, "กรุณาแจ้งรายละเอียดการจอง:\n• ประเภทรถ\n• วันที่ต้องการ\n• ต้นทาง\n• ปลายทาง"); err != nil {
			log.Printf("[LINE] reply error: %v", err)
		}
	case "action=track_trip":
		h.handleTextMessage("ติดตามสถานะงานปัจจุบัน", userID, replyToken)
	case "action=report_repair":
		if err := h.messaging.ReplyText(replyToken, "กรุณาแจ้งรายละเอียดการซ่อม:\n• ทะเบียนรถ\n• อาการ/ปัญหา\n• ถ่ายรูปรถ (ถ้ามี)"); err != nil {
			log.Printf("[LINE] reply error: %v", err)
		}
	case "action=view_costs":
		h.handleTextMessage("ดูต้นทุนขนส่งวันนี้", userID, replyToken)
	case "action=chat_ai":
		if err := h.messaging.ReplyText(replyToken, "สวัสดีครับ ฉันคือ AI ผู้ช่วยของ SML Fleet พิมพ์คำถามได้เลยครับ"); err != nil {
			log.Printf("[LINE] reply error: %v", err)
		}
	default:
		log.Printf("[LINE] unhandled postback: %s", data)
	}
}

// verifySignature ตรวจสอบ LINE signature
func (h *WebhookHandler) verifySignature(body []byte, signature string) bool {
	if signature == "" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(h.channelSecret))
	mac.Write(body)
	expected := base64.StdEncoding.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(expected), []byte(signature))
}

// resolveShopID แปลง LINE userID เป็น shop_id
// ในระบบจริงจะ query จาก DB ว่า LINE user นี้ผูกกับ shop ไหน
func (h *WebhookHandler) resolveShopID(userID string) string {
	// TODO: query mapping table LINE userID → shop_id
	return "shop_default"
}
