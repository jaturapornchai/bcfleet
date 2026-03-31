package ucp

import (
	"net/http"

	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// FulfillmentHandler จัดการ tracking และ POD
type FulfillmentHandler struct {
	tripSvc *service.TripService
	gpsSvc  *service.GPSService
}

// NewFulfillmentHandler สร้าง FulfillmentHandler
func NewFulfillmentHandler(tripSvc *service.TripService, gpsSvc *service.GPSService) *FulfillmentHandler {
	return &FulfillmentHandler{
		tripSvc: tripSvc,
		gpsSvc:  gpsSvc,
	}
}

// ---- Response Types ----

// TrackingResponse ข้อมูล tracking real-time
type TrackingResponse struct {
	TripID      string           `json:"trip_id"`
	TripNo      string           `json:"trip_no"`
	Status      string           `json:"status"`
	StatusTH    string           `json:"status_th"`
	DriverID    string           `json:"driver_id,omitempty"`
	VehicleID   string           `json:"vehicle_id,omitempty"`
	Origin      string           `json:"origin"`
	Location    *TrackingLocation `json:"location,omitempty"`
	Schedule    TrackingSchedule  `json:"schedule"`
	Progress    float64           `json:"progress_percent"` // 0-100
}

// TrackingLocation ตำแหน่ง GPS ปัจจุบัน
type TrackingLocation struct {
	Lat       float64 `json:"lat"`
	Lng       float64 `json:"lng"`
	SpeedKmh  float64 `json:"speed_kmh"`
	UpdatedAt string  `json:"updated_at"`
}

// TrackingSchedule ตารางเวลา
type TrackingSchedule struct {
	PlannedStart string `json:"planned_start"`
	PlannedEnd   string `json:"planned_end,omitempty"`
	ActualStart  string `json:"actual_start,omitempty"`
}

// PODResponse ข้อมูล Proof of Delivery
type PODResponse struct {
	TripID       string   `json:"trip_id"`
	TripNo       string   `json:"trip_no"`
	ReceiverName string   `json:"receiver_name"`
	Notes        string   `json:"notes"`
	Photos       []string `json:"photos"`
	SignatureURL string   `json:"signature_url"`
	DeliveredAt  string   `json:"delivered_at"`
}

// ConfirmRequest คำขอยืนยันรับสินค้า
type ConfirmRequest struct {
	ReceiverName string `json:"receiver_name" binding:"required"`
	Notes        string `json:"notes"`
	Rating       int    `json:"rating"` // 1-5
}

// ---- Handlers ----

// Track ติดตามงาน real-time
func (h *FulfillmentHandler) Track(c *gin.Context) {
	tripID := c.Param("id")
	shopID := resolveShopID(c)

	// GetByID: (ctx, shopID, id) → (*TripRow, error)
	trip, err := h.tripSvc.GetByID(c.Request.Context(), shopID, tripID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบงานนี้"})
		return
	}

	tracking := TrackingResponse{
		TripID:   trip.ID,
		Status:   trip.Status,
		StatusTH: translateTripStatus(trip.Status),
		Progress: calculateProgress(trip.Status),
	}

	if trip.TripNo != nil {
		tracking.TripNo = *trip.TripNo
	}
	if trip.DriverID != nil {
		tracking.DriverID = *trip.DriverID
	}
	if trip.VehicleID != nil {
		tracking.VehicleID = *trip.VehicleID
	}
	if trip.OriginName != nil {
		tracking.Origin = *trip.OriginName
	}

	// Schedule
	if trip.PlannedStart != nil {
		tracking.Schedule.PlannedStart = trip.PlannedStart.Format("2006-01-02 15:04")
	}
	if trip.PlannedEnd != nil {
		tracking.Schedule.PlannedEnd = trip.PlannedEnd.Format("2006-01-02 15:04")
	}
	if trip.ActualStart != nil {
		tracking.Schedule.ActualStart = trip.ActualStart.Format("2006-01-02 15:04")
	}

	// ดึงตำแหน่ง GPS ปัจจุบัน — GetVehicleLocations คืนทุกรถ กรองตาม vehicleID
	if trip.VehicleID != nil && *trip.VehicleID != "" {
		locations, err := h.gpsSvc.GetVehicleLocations(c.Request.Context(), shopID)
		if err == nil {
			for _, loc := range locations {
				if loc.VehicleID == *trip.VehicleID {
					tl := &TrackingLocation{}
					if loc.Lat != nil {
						tl.Lat = *loc.Lat
					}
					if loc.Lng != nil {
						tl.Lng = *loc.Lng
					}
					if loc.SpeedKmh != nil {
						tl.SpeedKmh = *loc.SpeedKmh
					}
					if loc.UpdatedAt != nil {
						tl.UpdatedAt = loc.UpdatedAt.Format("15:04:05")
					}
					tracking.Location = tl
					break
				}
			}
		}
	}

	c.JSON(http.StatusOK, tracking)
}

// GetPOD ดูหลักฐานส่งมอบ
func (h *FulfillmentHandler) GetPOD(c *gin.Context) {
	tripID := c.Param("id")
	shopID := resolveShopID(c)

	// GetPOD: (ctx, shopID, id) → (*models.ProofOfDelivery, error)
	pod, err := h.tripSvc.GetPOD(c.Request.Context(), shopID, tripID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบหลักฐานส่งมอบ"})
		return
	}

	// ดึง trip_no
	tripNo := tripID
	if trip, err := h.tripSvc.GetByID(c.Request.Context(), shopID, tripID); err == nil && trip.TripNo != nil {
		tripNo = *trip.TripNo
	}

	resp := PODResponse{
		TripID:       tripID,
		TripNo:       tripNo,
		ReceiverName: pod.ReceiverName,
		Notes:        pod.Notes,
		Photos:       pod.Photos,
		SignatureURL: pod.SignatureURL,
	}
	if !pod.Timestamp.IsZero() {
		resp.DeliveredAt = pod.Timestamp.Format("2006-01-02 15:04")
	}

	c.JSON(http.StatusOK, resp)
}

// Confirm ยืนยันรับสินค้า (ฝั่งลูกค้า)
func (h *FulfillmentHandler) Confirm(c *gin.Context) {
	tripID := c.Param("id")
	shopID := resolveShopID(c)

	var req ConfirmRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// ตรวจสอบสถานะ trip
	trip, err := h.tripSvc.GetByID(c.Request.Context(), shopID, tripID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบงานนี้"})
		return
	}

	if trip.Status != "delivering" && trip.Status != "completed" {
		c.JSON(http.StatusConflict, gin.H{
			"error":  "ไม่สามารถยืนยันได้ งานอยู่ในสถานะ: " + trip.Status,
			"status": trip.Status,
		})
		return
	}

	// อัปเดตสถานะเป็น completed ถ้ายังไม่ได้
	// UpdateStatus: (ctx, shopID, userID, id, req) → error
	if trip.Status != "completed" {
		statusReq := service.UpdateTripStatusRequest{Status: "completed"}
		if err := h.tripSvc.UpdateStatus(c.Request.Context(), shopID, "ucp_confirm", tripID, statusReq); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถยืนยันการรับสินค้าได้"})
			return
		}
	}

	tripNo := tripID
	if trip.TripNo != nil {
		tripNo = *trip.TripNo
	}

	c.JSON(http.StatusOK, gin.H{
		"trip_id":       tripID,
		"trip_no":       tripNo,
		"status":        "completed",
		"receiver_name": req.ReceiverName,
		"rating":        req.Rating,
		"message":       "ยืนยันรับสินค้าสำเร็จ ขอบคุณที่ใช้บริการ SML Fleet",
	})
}

// ---- Helpers ----

// resolveShopID ดึง shop_id จาก context หรือ query param
func resolveShopID(c *gin.Context) string {
	if shopID := c.GetString("shop_id"); shopID != "" {
		return shopID
	}
	return c.Query("shop_id")
}

// calculateProgress คำนวณ % ความคืบหน้า
func calculateProgress(status string) float64 {
	switch status {
	case "draft":
		return 0
	case "pending":
		return 5
	case "accepted":
		return 15
	case "started":
		return 30
	case "arrived":
		return 50
	case "delivering":
		return 75
	case "completed":
		return 100
	default:
		return 0
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
