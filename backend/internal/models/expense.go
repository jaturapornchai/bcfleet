package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Expense ค่าใช้จ่าย
type Expense struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID      string             `bson:"shop_id" json:"shop_id"`
	TripID      string             `bson:"trip_id,omitempty" json:"trip_id"`
	VehicleID   string             `bson:"vehicle_id" json:"vehicle_id"`
	DriverID    string             `bson:"driver_id" json:"driver_id"`
	Type        string             `bson:"type" json:"type"` // "fuel", "toll", "parking", "repair", "fine", "other"
	Description string             `bson:"description" json:"description"`
	Amount      float64            `bson:"amount" json:"amount"`

	FuelDetail *FuelDetail `bson:"fuel_detail,omitempty" json:"fuel_detail"`

	ReceiptURL string `bson:"receipt_url,omitempty" json:"receipt_url"`

	BCAccountEntry *BCAccountEntry `bson:"bc_account_entry,omitempty" json:"bc_account_entry"`

	RecordedBy string    `bson:"recorded_by" json:"recorded_by"`
	RecordedAt time.Time `bson:"recorded_at" json:"recorded_at"`
	CreatedAt  time.Time `bson:"created_at" json:"created_at"`
}

// FuelDetail รายละเอียดเติมน้ำมัน
type FuelDetail struct {
	Liters        float64 `bson:"liters" json:"liters"`
	PricePerLiter float64 `bson:"price_per_liter" json:"price_per_liter"`
	OdometerKm    int     `bson:"odometer_km" json:"odometer_km"`
	Station       string  `bson:"station" json:"station"`
	FuelType      string  `bson:"fuel_type" json:"fuel_type"` // "ดีเซล B7", "แก๊สโซฮอล์ 95"
}
