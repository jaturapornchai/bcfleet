package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GPSLog บันทึก GPS (high frequency — ทุก 30 วินาที)
type GPSLog struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID    string             `bson:"shop_id" json:"shop_id"`
	VehicleID string             `bson:"vehicle_id" json:"vehicle_id"`
	DriverID  string             `bson:"driver_id" json:"driver_id"`
	TripID    string             `bson:"trip_id,omitempty" json:"trip_id"`

	Location GeoJSON `bson:"location" json:"location"` // GeoJSON format

	SpeedKmh   float64   `bson:"speed_kmh" json:"speed_kmh"`
	Heading    int       `bson:"heading" json:"heading"`
	AccuracyM  float64   `bson:"accuracy_m" json:"accuracy_m"`
	BatteryPct int       `bson:"battery_pct" json:"battery_pct"`
	Timestamp  time.Time `bson:"timestamp" json:"timestamp"`
	CreatedAt  time.Time `bson:"created_at" json:"created_at"`
}

// GeoJSON สำหรับ MongoDB 2dsphere index
type GeoJSON struct {
	Type        string    `bson:"type" json:"type"`               // "Point"
	Coordinates []float64 `bson:"coordinates" json:"coordinates"` // [lng, lat]
}

// Alert แจ้งเตือน
type Alert struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID       string             `bson:"shop_id" json:"shop_id"`
	Type         string             `bson:"type" json:"type"` // "insurance_expiry", "tax_due", "act_due", "license_expiry", "maintenance_due", "geofence_alert", "speeding"
	Entity       string             `bson:"entity" json:"entity"`
	EntityID     string             `bson:"entity_id" json:"entity_id"`
	Title        string             `bson:"title" json:"title"`
	Message      string             `bson:"message" json:"message"`
	Severity     string             `bson:"severity" json:"severity"` // "info", "warning", "critical"
	DueDate      *time.Time         `bson:"due_date,omitempty" json:"due_date"`
	DaysRemaining int               `bson:"days_remaining" json:"days_remaining"`
	Status       string             `bson:"status" json:"status"` // "active", "acknowledged", "resolved"

	Notified *NotificationStatus `bson:"notified,omitempty" json:"notified"`

	AcknowledgedBy string     `bson:"acknowledged_by,omitempty" json:"acknowledged_by"`
	AcknowledgedAt *time.Time `bson:"acknowledged_at,omitempty" json:"acknowledged_at"`
	CreatedAt      time.Time  `bson:"created_at" json:"created_at"`
}

// NotificationStatus สถานะการแจ้งเตือน
type NotificationStatus struct {
	LINE  bool `bson:"line" json:"line"`
	Push  bool `bson:"push" json:"push"`
	Email bool `bson:"email" json:"email"`
}
