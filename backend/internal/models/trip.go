package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Trip เที่ยววิ่ง
type Trip struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID    string             `bson:"shop_id" json:"shop_id"`
	TripNo    string             `bson:"trip_no" json:"trip_no"`
	Status    string             `bson:"status" json:"status"` // "draft", "pending", "accepted", "started", "arrived", "delivering", "completed", "cancelled"
	VehicleID string             `bson:"vehicle_id,omitempty" json:"vehicle_id"`
	DriverID  string             `bson:"driver_id,omitempty" json:"driver_id"`
	IsPartner bool               `bson:"is_partner" json:"is_partner"`
	PartnerID string             `bson:"partner_id,omitempty" json:"partner_id"`

	Origin       TripLocation   `bson:"origin" json:"origin"`
	Destinations []Destination  `bson:"destinations" json:"destinations"`
	Cargo        *CargoInfo     `bson:"cargo,omitempty" json:"cargo"`
	Schedule     *TripSchedule  `bson:"schedule,omitempty" json:"schedule"`
	Route        *RouteInfo     `bson:"route,omitempty" json:"route"`
	Costs        *TripCosts     `bson:"costs,omitempty" json:"costs"`
	POD          *ProofOfDelivery `bson:"pod,omitempty" json:"pod"`
	Checklist    *TripChecklist `bson:"checklist,omitempty" json:"checklist"`

	CreatedBy string    `bson:"created_by" json:"created_by"`
	CreatedAt time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}

// TripLocation ตำแหน่งต้นทาง/ปลายทาง
type TripLocation struct {
	Name         string  `bson:"name" json:"name"`
	Address      string  `bson:"address" json:"address"`
	Lat          float64 `bson:"lat" json:"lat"`
	Lng          float64 `bson:"lng" json:"lng"`
	ContactName  string  `bson:"contact_name,omitempty" json:"contact_name"`
	ContactPhone string  `bson:"contact_phone,omitempty" json:"contact_phone"`
}

// Destination จุดส่งของ (หลายจุดได้)
type Destination struct {
	Seq          int        `bson:"seq" json:"seq"`
	Name         string     `bson:"name" json:"name"`
	Address      string     `bson:"address" json:"address"`
	Lat          float64    `bson:"lat" json:"lat"`
	Lng          float64    `bson:"lng" json:"lng"`
	ContactName  string     `bson:"contact_name,omitempty" json:"contact_name"`
	ContactPhone string     `bson:"contact_phone,omitempty" json:"contact_phone"`
	Status       string     `bson:"status" json:"status"` // "pending", "arrived", "delivered"
	ArrivedAt    *time.Time `bson:"arrived_at,omitempty" json:"arrived_at"`
	DeliveredAt  *time.Time `bson:"delivered_at,omitempty" json:"delivered_at"`
	POD          *ProofOfDelivery `bson:"pod,omitempty" json:"pod"`
}

// CargoInfo ข้อมูลสินค้า
type CargoInfo struct {
	Description         string  `bson:"description" json:"description"`
	WeightKg            int     `bson:"weight_kg" json:"weight_kg"`
	VolumeCBM           float64 `bson:"volume_cbm,omitempty" json:"volume_cbm"`
	SpecialInstructions string  `bson:"special_instructions,omitempty" json:"special_instructions"`
}

// TripSchedule ตารางเวลา
type TripSchedule struct {
	PlannedStart time.Time  `bson:"planned_start" json:"planned_start"`
	PlannedEnd   time.Time  `bson:"planned_end" json:"planned_end"`
	ActualStart  *time.Time `bson:"actual_start,omitempty" json:"actual_start"`
	ActualEnd    *time.Time `bson:"actual_end,omitempty" json:"actual_end"`
}

// RouteInfo ข้อมูลเส้นทาง
type RouteInfo struct {
	DistanceKm      float64 `bson:"distance_km" json:"distance_km"`
	DurationMinutes int     `bson:"duration_minutes" json:"duration_minutes"`
	LongdoRouteID   string  `bson:"longdo_route_id,omitempty" json:"longdo_route_id"`
}

// TripCosts ค่าใช้จ่ายต่อเที่ยว
type TripCosts struct {
	Fuel            float64 `bson:"fuel" json:"fuel"`
	Toll            float64 `bson:"toll" json:"toll"`
	Other           float64 `bson:"other" json:"other"`
	DriverAllowance float64 `bson:"driver_allowance" json:"driver_allowance"`
	Total           float64 `bson:"total" json:"total"`
	Revenue         float64 `bson:"revenue" json:"revenue"`
	Profit          float64 `bson:"profit" json:"profit"`
}

// ProofOfDelivery หลักฐานส่งมอบ
type ProofOfDelivery struct {
	Photos       []string  `bson:"photos" json:"photos"`
	SignatureURL string    `bson:"signature_url" json:"signature_url"`
	ReceiverName string    `bson:"receiver_name" json:"receiver_name"`
	Notes        string    `bson:"notes" json:"notes"`
	Timestamp    time.Time `bson:"timestamp" json:"timestamp"`
}

// TripChecklist เช็คลิสต์ก่อน/หลังวิ่ง
type TripChecklist struct {
	PreTrip  *ChecklistResult `bson:"pre_trip,omitempty" json:"pre_trip"`
	PostTrip *ChecklistResult `bson:"post_trip,omitempty" json:"post_trip"`
}

// ChecklistResult ผลเช็คลิสต์
type ChecklistResult struct {
	Completed   bool            `bson:"completed" json:"completed"`
	Items       []ChecklistItem `bson:"items" json:"items"`
	CompletedAt *time.Time      `bson:"completed_at,omitempty" json:"completed_at"`
}

// ChecklistItem รายการตรวจสอบ
type ChecklistItem struct {
	Item   string `bson:"item" json:"item"`
	Status string `bson:"status" json:"status"` // "ok", "warning", "fail"
	Photo  string `bson:"photo,omitempty" json:"photo"`
}
