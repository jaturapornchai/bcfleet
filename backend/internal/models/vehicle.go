package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Vehicle ข้อมูลรถขนส่ง
type Vehicle struct {
	ID              primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID          string             `bson:"shop_id" json:"shop_id"`
	Plate           string             `bson:"plate" json:"plate"`
	Brand           string             `bson:"brand" json:"brand"`
	Model           string             `bson:"model" json:"model"`
	Type            string             `bson:"type" json:"type"`                       // "4ล้อ", "6ล้อ", "10ล้อ", "หัวลาก", "กระบะ"
	Year            int                `bson:"year" json:"year"`
	Color           string             `bson:"color" json:"color"`
	ChassisNo       string             `bson:"chassis_no" json:"chassis_no"`
	EngineNo        string             `bson:"engine_no" json:"engine_no"`
	FuelType        string             `bson:"fuel_type" json:"fuel_type"`             // "ดีเซล", "เบนซิน", "NGV", "EV"
	MaxWeightKg     int                `bson:"max_weight_kg" json:"max_weight_kg"`
	Ownership       string             `bson:"ownership" json:"ownership"`             // "own", "partner", "rental"
	PartnerID       string             `bson:"partner_id,omitempty" json:"partner_id"`
	Status          string             `bson:"status" json:"status"`                   // "active", "maintenance", "inactive"
	CurrentDriverID string             `bson:"current_driver_id,omitempty" json:"current_driver_id"`
	CurrentLocation *GeoPoint          `bson:"current_location,omitempty" json:"current_location"`
	MileageKm       int                `bson:"mileage_km" json:"mileage_km"`

	Insurance *InsuranceInfo `bson:"insurance,omitempty" json:"insurance"`
	Tax       *TaxInfo       `bson:"tax,omitempty" json:"tax"`
	Act       *ActInfo       `bson:"act,omitempty" json:"act"` // พ.ร.บ.

	MonitoringPrompt string `bson:"monitoring_prompt,omitempty" json:"monitoring_prompt"` // AI prompt สำหรับวิเคราะห์รถคันนี้เฉพาะ

	MaintenanceSchedule []MaintenanceItem `bson:"maintenance_schedule,omitempty" json:"maintenance_schedule"`
	Documents           []VehicleDocument `bson:"documents,omitempty" json:"documents"`

	CreatedAt time.Time  `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time  `bson:"updated_at" json:"updated_at"`
	DeletedAt *time.Time `bson:"deleted_at,omitempty" json:"deleted_at"`
}

// GeoPoint พิกัด GPS
type GeoPoint struct {
	Lat float64 `bson:"lat" json:"lat"`
	Lng float64 `bson:"lng" json:"lng"`
}

// InsuranceInfo ข้อมูลประกันภัย
type InsuranceInfo struct {
	Company  string    `bson:"company" json:"company"`
	PolicyNo string    `bson:"policy_no" json:"policy_no"`
	Type     string    `bson:"type" json:"type"` // "ชั้น1", "ชั้น2", "ชั้น3"
	Start    time.Time `bson:"start_date" json:"start_date"`
	End      time.Time `bson:"end_date" json:"end_date"`
	Premium  float64   `bson:"premium" json:"premium"`
}

// TaxInfo ข้อมูลภาษีรถ
type TaxInfo struct {
	DueDate  time.Time `bson:"due_date" json:"due_date"`
	LastPaid time.Time `bson:"last_paid" json:"last_paid"`
	Amount   float64   `bson:"amount" json:"amount"`
}

// ActInfo ข้อมูล พ.ร.บ.
type ActInfo struct {
	DueDate  time.Time `bson:"due_date" json:"due_date"`
	LastPaid time.Time `bson:"last_paid" json:"last_paid"`
	Amount   float64   `bson:"amount" json:"amount"`
}

// MaintenanceItem รายการซ่อมบำรุงตามรอบ
type MaintenanceItem struct {
	Item         string     `bson:"item" json:"item"`
	IntervalKm   *int       `bson:"interval_km,omitempty" json:"interval_km"`
	IntervalDays *int       `bson:"interval_days,omitempty" json:"interval_days"`
	LastDoneKm   int        `bson:"last_done_km" json:"last_done_km"`
	LastDoneDate *time.Time `bson:"last_done_date,omitempty" json:"last_done_date"`
}

// VehicleDocument เอกสารที่แนบกับรถ
type VehicleDocument struct {
	Type       string    `bson:"type" json:"type"` // "registration", "insurance_policy"
	URL        string    `bson:"url" json:"url"`
	UploadedAt time.Time `bson:"uploaded_at" json:"uploaded_at"`
}
