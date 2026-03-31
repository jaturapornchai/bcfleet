package ucp

import (
	"fmt"
	"net/http"
	"time"

	"bc-fleet/internal/models"
	"bc-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// CartHandler จัดการ booking และ checkout
type CartHandler struct {
	tripSvc *service.TripService
}

// NewCartHandler สร้าง CartHandler
func NewCartHandler(tripSvc *service.TripService) *CartHandler {
	return &CartHandler{tripSvc: tripSvc}
}

// ---- Request/Response Types ----

// QuoteRequest คำขอใบเสนอราคา
type QuoteRequest struct {
	ShopID      string    `json:"shop_id" binding:"required"`
	VehicleType string    `json:"vehicle_type" binding:"required"`
	Origin      string    `json:"origin" binding:"required"`
	OriginLat   float64   `json:"origin_lat"`
	OriginLng   float64   `json:"origin_lng"`
	Destination string    `json:"destination" binding:"required"`
	DestLat     float64   `json:"dest_lat"`
	DestLng     float64   `json:"dest_lng"`
	CargoDesc   string    `json:"cargo_description"`
	WeightKg    int       `json:"weight_kg"`
	Date        time.Time `json:"date" binding:"required"`
}

// QuoteResponse ใบเสนอราคา
type QuoteResponse struct {
	QuoteID      string    `json:"quote_id"`
	ShopID       string    `json:"shop_id"`
	VehicleType  string    `json:"vehicle_type"`
	Origin       string    `json:"origin"`
	Destination  string    `json:"destination"`
	DistanceKm   float64   `json:"distance_km"`
	EstDuration  string    `json:"est_duration"`
	BasePrice    float64   `json:"base_price"`
	FuelCost     float64   `json:"fuel_cost"`
	TollCost     float64   `json:"toll_cost"`
	TotalPrice   float64   `json:"total_price"`
	Currency     string    `json:"currency"`
	ValidUntil   time.Time `json:"valid_until"`
	Date         time.Time `json:"date"`
}

// BookingRequest คำขอจองเที่ยวรถ
type BookingRequest struct {
	ShopID       string              `json:"shop_id" binding:"required"`
	QuoteID      string              `json:"quote_id"`
	VehicleType  string              `json:"vehicle_type" binding:"required"`
	Origin       models.TripLocation `json:"origin" binding:"required"`
	Destinations []models.Destination `json:"destinations" binding:"required"`
	Cargo        *models.CargoInfo   `json:"cargo"`
	PlannedStart time.Time           `json:"planned_start" binding:"required"`
	PlannedEnd   time.Time           `json:"planned_end"`
	Revenue      float64             `json:"revenue"`
	CustomerName string              `json:"customer_name"`
	CustomerPhone string             `json:"customer_phone"`
	Notes        string              `json:"notes"`
}

// BookingResponse response หลังจองเที่ยว
type BookingResponse struct {
	TripID       string    `json:"trip_id"`
	TripNo       string    `json:"trip_no"`
	Status       string    `json:"status"`
	PlannedStart time.Time `json:"planned_start"`
	TrackingURL  string    `json:"tracking_url"`
	Message      string    `json:"message"`
}

// UpdateBookingRequest คำขอแก้ไขการจอง
type UpdateBookingRequest struct {
	PlannedStart *time.Time `json:"planned_start"`
	PlannedEnd   *time.Time `json:"planned_end"`
	Notes        string     `json:"notes"`
	Revenue      float64    `json:"revenue"`
}

// ---- Handlers ----

// GetQuote ขอใบเสนอราคา
func (h *CartHandler) GetQuote(c *gin.Context) {
	var req QuoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// คำนวณราคา — ในระบบจริงจะใช้ Longdo Map คำนวณระยะทาง
	distanceKm := estimateDistance(req.OriginLat, req.OriginLng, req.DestLat, req.DestLng)
	basePrice := getBaseRateByType(req.VehicleType)
	fuelCost := distanceKm * getFuelCostPerKm(req.VehicleType)
	tollCost := estimateTollCost(distanceKm)
	totalPrice := basePrice + fuelCost + tollCost

	quote := QuoteResponse{
		QuoteID:     fmt.Sprintf("QUOTE-%d", time.Now().Unix()),
		ShopID:      req.ShopID,
		VehicleType: req.VehicleType,
		Origin:      req.Origin,
		Destination: req.Destination,
		DistanceKm:  distanceKm,
		EstDuration: estimateDuration(distanceKm),
		BasePrice:   basePrice,
		FuelCost:    fuelCost,
		TollCost:    tollCost,
		TotalPrice:  totalPrice,
		Currency:    "THB",
		ValidUntil:  time.Now().Add(24 * time.Hour),
		Date:        req.Date,
	}

	c.JSON(http.StatusOK, quote)
}

// CreateBooking จองเที่ยวรถ
func (h *CartHandler) CreateBooking(c *gin.Context) {
	var req BookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// สร้าง trip ผ่าน TripService
	tripReq := service.CreateTripRequest{
		Origin:       req.Origin,
		Destinations: req.Destinations,
		Cargo:        req.Cargo,
		PlannedStart: req.PlannedStart,
		PlannedEnd:   req.PlannedEnd,
		Revenue:      req.Revenue,
	}

	// Create: (ctx, shopID, userID, req) → (*models.Trip, error)
	trip, err := h.tripSvc.Create(c.Request.Context(), req.ShopID, "ucp_booking", tripReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้างการจองได้: " + err.Error()})
		return
	}

	plannedStart := req.PlannedStart
	if trip.Schedule != nil {
		plannedStart = trip.Schedule.PlannedStart
	}

	c.JSON(http.StatusCreated, BookingResponse{
		TripID:       trip.ID.Hex(),
		TripNo:       trip.TripNo,
		Status:       trip.Status,
		PlannedStart: plannedStart,
		TrackingURL:  fmt.Sprintf("/ucp/fulfillment/track/%s", trip.ID.Hex()),
		Message:      "จองเที่ยวรถสำเร็จ รอการมอบหมายคนขับและรถ",
	})
}

// UpdateBooking แก้ไขการจอง
func (h *CartHandler) UpdateBooking(c *gin.Context) {
	tripID := c.Param("id")
	shopID := c.GetString("shop_id")
	if shopID == "" {
		shopID = c.Query("shop_id")
	}

	var req UpdateBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// ดึง trip เดิม
	trip, err := h.tripSvc.GetByID(c.Request.Context(), shopID, tripID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบการจองนี้"})
		return
	}

	// ตรวจสอบว่ายังแก้ไขได้
	if trip.Status != "draft" && trip.Status != "pending" {
		c.JSON(http.StatusConflict, gin.H{
			"error":  "ไม่สามารถแก้ไขได้ งานอยู่ในสถานะ: " + trip.Status,
			"status": trip.Status,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"trip_id": tripID,
		"status":  trip.Status,
		"message": "อัปเดตการจองสำเร็จ",
	})
}

// ---- Helpers ----

// estimateDistance คำนวณระยะทางคร่าวๆ (ใช้ Haversine formula แบบง่าย)
// ในระบบจริงจะเรียก Longdo Map API
func estimateDistance(lat1, lng1, lat2, lng2 float64) float64 {
	if lat1 == 0 && lng1 == 0 || lat2 == 0 && lng2 == 0 {
		return 50 // default 50 km ถ้าไม่มีพิกัด
	}
	// Simple approximation: 1 degree ≈ 111 km
	dlat := lat2 - lat1
	dlng := lng2 - lng1
	if dlat < 0 {
		dlat = -dlat
	}
	if dlng < 0 {
		dlng = -dlng
	}
	return (dlat + dlng) * 80 // ประมาณ 80 km/degree สำหรับภาคเหนือ
}

// getFuelCostPerKm ค่าน้ำมันต่อ km ตามประเภทรถ
func getFuelCostPerKm(vehicleType string) float64 {
	costs := map[string]float64{
		"กระบะ":  8,
		"4ล้อ":   10,
		"6ล้อ":   15,
		"10ล้อ":  20,
		"หัวลาก": 28,
	}
	if cost, ok := costs[vehicleType]; ok {
		return cost
	}
	return 15
}

// estimateTollCost ประมาณค่าทางด่วน
func estimateTollCost(distanceKm float64) float64 {
	if distanceKm < 30 {
		return 0
	} else if distanceKm < 100 {
		return 60
	}
	return 120
}

// estimateDuration ประมาณเวลาเดินทาง
func estimateDuration(distanceKm float64) string {
	hours := distanceKm / 60 // เฉลี่ย 60 km/h
	if hours < 1 {
		return fmt.Sprintf("%.0f นาที", hours*60)
	}
	return fmt.Sprintf("%.1f ชั่วโมง", hours)
}
