package line

import (
	"context"
	"fmt"
	"log"

	pgquery "sml-fleet/internal/repository/postgres"
)

// NotificationService ส่งแจ้งเตือนผ่าน LINE OA
type NotificationService struct {
	messaging    *MessagingClient
	customerQuery *pgquery.CustomerQuery
	tripQuery    *pgquery.TripQuery
}

// NewNotificationService สร้าง notification service
func NewNotificationService(messaging *MessagingClient, customerQuery *pgquery.CustomerQuery, tripQuery *pgquery.TripQuery) *NotificationService {
	return &NotificationService{
		messaging:    messaging,
		customerQuery: customerQuery,
		tripQuery:    tripQuery,
	}
}

// NotifyTripStatusChanged แจ้งลูกค้าเมื่อสถานะเที่ยวเปลี่ยน
func (n *NotificationService) NotifyTripStatusChanged(ctx context.Context, shopID, tripID, newStatus string) {
	trip, err := n.tripQuery.GetByID(ctx, shopID, tripID)
	if err != nil || trip == nil {
		return
	}

	customerID := ""
	if trip.CustomerID != nil {
		customerID = *trip.CustomerID
	}
	if customerID == "" {
		return
	}

	customer, err := n.customerQuery.GetByID(ctx, shopID, customerID)
	if err != nil || customer == nil || customer.LineUserID == nil || *customer.LineUserID == "" {
		return
	}

	statusThai := map[string]string{
		"pending":    "รอดำเนินการ",
		"accepted":   "รับงานแล้ว",
		"started":    "ออกเดินทางแล้ว",
		"arrived":    "ถึงจุดรับสินค้าแล้ว",
		"delivering": "กำลังส่งมอบ",
		"completed":  "ส่งมอบสำเร็จ",
		"cancelled":  "ยกเลิก",
	}

	statusText := statusThai[newStatus]
	if statusText == "" {
		statusText = newStatus
	}

	tripNo := ""
	if trip.TripNo != nil {
		tripNo = *trip.TripNo
	}

	msg := fmt.Sprintf("📦 แจ้งสถานะเที่ยว %s\nสถานะ: %s", tripNo, statusText)

	if newStatus == "started" {
		msg += "\n🚛 รถออกเดินทางแล้ว! ติดตามสถานะได้ตลอด"
	} else if newStatus == "completed" {
		msg += "\n✅ ส่งมอบเรียบร้อย ขอบคุณที่ใช้บริการ SML Fleet"
	}

	if err := n.messaging.PushText(*customer.LineUserID, msg); err != nil {
		log.Printf("[LINE Notify] push failed to %s: %v", *customer.LineUserID, err)
	}
}

// NotifyVehicleApproaching แจ้งลูกค้าเมื่อรถใกล้ถึง
func (n *NotificationService) NotifyVehicleApproaching(ctx context.Context, shopID, tripID string, distanceKm float64) {
	trip, err := n.tripQuery.GetByID(ctx, shopID, tripID)
	if err != nil || trip == nil {
		return
	}

	customerID := ""
	if trip.CustomerID != nil {
		customerID = *trip.CustomerID
	}
	if customerID == "" {
		return
	}

	customer, err := n.customerQuery.GetByID(ctx, shopID, customerID)
	if err != nil || customer == nil || customer.LineUserID == nil || *customer.LineUserID == "" {
		return
	}

	tripNo := ""
	if trip.TripNo != nil {
		tripNo = *trip.TripNo
	}

	msg := fmt.Sprintf("🚛 รถใกล้ถึงแล้ว!\nเที่ยว: %s\nระยะทาง: %.1f กม.\nประมาณอีก %d นาที",
		tripNo, distanceKm, int(distanceKm/0.8)) // ประมาณ 0.8 กม./นาที

	if err := n.messaging.PushText(*customer.LineUserID, msg); err != nil {
		log.Printf("[LINE Notify] approaching push failed: %v", err)
	}
}
