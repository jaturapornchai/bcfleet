package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// WorkOrder ใบสั่งซ่อม
type WorkOrder struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID      string             `bson:"shop_id" json:"shop_id"`
	WONo        string             `bson:"wo_no" json:"wo_no"`
	VehicleID   string             `bson:"vehicle_id" json:"vehicle_id"`
	Type        string             `bson:"type" json:"type"`             // "preventive", "corrective", "emergency"
	Priority    string             `bson:"priority" json:"priority"`     // "low", "medium", "high", "critical"
	Status      string             `bson:"status" json:"status"`         // "draft", "pending_approval", "approved", "in_progress", "completed", "cancelled"
	ReportedBy  string             `bson:"reported_by" json:"reported_by"`
	ReportedType string            `bson:"reported_type" json:"reported_type"` // "driver", "system", "admin", "ai_agent"
	Description string             `bson:"description" json:"description"`
	Symptoms    string             `bson:"symptoms,omitempty" json:"symptoms"`
	MileageAtReport int            `bson:"mileage_at_report" json:"mileage_at_report"`

	ServiceProvider *ServiceProvider `bson:"service_provider,omitempty" json:"service_provider"`
	Parts           []WOPart        `bson:"parts,omitempty" json:"parts"`
	Labor           *LaborCost      `bson:"labor,omitempty" json:"labor"`
	TotalCost       float64         `bson:"total_cost" json:"total_cost"`

	ApprovedBy  string     `bson:"approved_by,omitempty" json:"approved_by"`
	ApprovedAt  *time.Time `bson:"approved_at,omitempty" json:"approved_at"`
	StartedAt   *time.Time `bson:"started_at,omitempty" json:"started_at"`
	CompletedAt *time.Time `bson:"completed_at,omitempty" json:"completed_at"`

	Photos *WOPhotos `bson:"photos,omitempty" json:"photos"`

	BCAccountEntry *BCAccountEntry `bson:"bc_account_entry,omitempty" json:"bc_account_entry"`

	CreatedAt time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}

// ServiceProvider ผู้ให้บริการซ่อม
type ServiceProvider struct {
	Type    string `bson:"type" json:"type"` // "internal", "external"
	Name    string `bson:"name" json:"name"`
	Phone   string `bson:"phone,omitempty" json:"phone"`
	Address string `bson:"address,omitempty" json:"address"`
}

// WOPart อะไหล่ในใบสั่งซ่อม
type WOPart struct {
	Name      string  `bson:"name" json:"name"`
	Qty       float64 `bson:"qty" json:"qty"`
	Unit      string  `bson:"unit" json:"unit"`
	UnitPrice float64 `bson:"unit_price" json:"unit_price"`
	Total     float64 `bson:"total" json:"total"`
	FromStock bool    `bson:"from_stock" json:"from_stock"`
}

// LaborCost ค่าแรง
type LaborCost struct {
	Hours float64 `bson:"hours" json:"hours"`
	Rate  float64 `bson:"rate" json:"rate"`
	Total float64 `bson:"total" json:"total"`
}

// WOPhotos รูปถ่ายก่อน/หลังซ่อม
type WOPhotos struct {
	Before []string `bson:"before,omitempty" json:"before"`
	After  []string `bson:"after,omitempty" json:"after"`
}

// BCAccountEntry เชื่อม BC Account
type BCAccountEntry struct {
	Synced         bool   `bson:"synced" json:"synced"`
	JournalID      string `bson:"journal_id,omitempty" json:"journal_id"`
	ExpenseAccount string `bson:"expense_account,omitempty" json:"expense_account"`
}

// PartsInventory สต๊อกอะไหล่
type PartsInventory struct {
	ID            primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID        string             `bson:"shop_id" json:"shop_id"`
	PartNo        string             `bson:"part_no" json:"part_no"`
	Name          string             `bson:"name" json:"name"`
	Category      string             `bson:"category" json:"category"`
	Unit          string             `bson:"unit" json:"unit"`
	QtyInStock    float64            `bson:"qty_in_stock" json:"qty_in_stock"`
	MinQty        float64            `bson:"min_qty" json:"min_qty"`
	UnitCost      float64            `bson:"unit_cost" json:"unit_cost"`
	Supplier      string             `bson:"supplier,omitempty" json:"supplier"`
	Location      string             `bson:"location,omitempty" json:"location"`
	LastRestocked *time.Time         `bson:"last_restocked,omitempty" json:"last_restocked"`
	CreatedAt     time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt     time.Time          `bson:"updated_at" json:"updated_at"`
}
