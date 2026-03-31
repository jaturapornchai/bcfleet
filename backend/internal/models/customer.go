package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Customer ข้อมูลลูกค้า
type Customer struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID       string             `bson:"shop_id" json:"shop_id"`
	CustomerNo   string             `bson:"customer_no" json:"customer_no"`     // CUST-001
	Name         string             `bson:"name" json:"name"`                   // ชื่อบริษัท/ลูกค้า
	CustomerType string             `bson:"customer_type" json:"customer_type"` // "individual", "company"
	Phone        string             `bson:"phone" json:"phone"`
	LineUserID   string             `bson:"line_user_id,omitempty" json:"line_user_id"`
	Email        string             `bson:"email,omitempty" json:"email"`
	Company      string             `bson:"company,omitempty" json:"company"`
	TaxID        string             `bson:"tax_id,omitempty" json:"tax_id"`
	Address      string             `bson:"address,omitempty" json:"address"`
	Contacts     []CustomerContact  `bson:"contacts,omitempty" json:"contacts"`
	CreditTerms  *CreditTerms       `bson:"credit_terms,omitempty" json:"credit_terms"`
	Notes        string             `bson:"notes,omitempty" json:"notes"`
	Tags         []string           `bson:"tags,omitempty" json:"tags"`
	Status       string             `bson:"status" json:"status"` // "active", "inactive"
	CreatedBy    string             `bson:"created_by" json:"created_by"`
	CreatedAt    time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt    time.Time          `bson:"updated_at" json:"updated_at"`
	DeletedAt    *time.Time         `bson:"deleted_at,omitempty" json:"deleted_at"`
}

// CustomerContact ผู้ติดต่อของลูกค้า (หลายคนได้)
type CustomerContact struct {
	Name      string `bson:"name" json:"name"`
	Role      string `bson:"role" json:"role"`   // "ผู้จัดการ", "ฝ่ายจัดส่ง"
	Phone     string `bson:"phone" json:"phone"`
	LineID    string `bson:"line_id,omitempty" json:"line_id"`
	IsPrimary bool   `bson:"is_primary" json:"is_primary"`
}

// CreditTerms เงื่อนไขเครดิต
type CreditTerms struct {
	Enabled     bool    `bson:"enabled" json:"enabled"`
	DaysCredit  int     `bson:"days_credit" json:"days_credit"`   // 30, 60
	CreditLimit float64 `bson:"credit_limit" json:"credit_limit"` // วงเงิน
}
