package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PartnerVehicle ข้อมูลรถร่วม
type PartnerVehicle struct {
	ID     primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID string             `bson:"shop_id" json:"shop_id"`

	Owner   PartnerOwner      `bson:"owner" json:"owner"`
	Vehicle PartnerVehicleInfo `bson:"vehicle" json:"vehicle"`
	Driver  PartnerDriverInfo `bson:"driver" json:"driver"`
	Pricing PartnerPricing    `bson:"pricing" json:"pricing"`

	CoverageZones []string `bson:"coverage_zones" json:"coverage_zones"`
	Rating        float64  `bson:"rating" json:"rating"`
	TotalTrips    int      `bson:"total_trips" json:"total_trips"`
	Status        string   `bson:"status" json:"status"` // "active", "suspended", "inactive"

	WithholdingTax *WithholdingTax `bson:"withholding_tax,omitempty" json:"withholding_tax"`

	BCAccountCreditorID string `bson:"bc_account_creditor_id,omitempty" json:"bc_account_creditor_id"`

	CreatedAt time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}

// PartnerOwner ข้อมูลเจ้าของรถร่วม
type PartnerOwner struct {
	Name        string       `bson:"name" json:"name"`
	Company     string       `bson:"company,omitempty" json:"company"`
	TaxID       string       `bson:"tax_id,omitempty" json:"tax_id"`
	Phone       string       `bson:"phone" json:"phone"`
	LineID      string       `bson:"line_id,omitempty" json:"line_id"`
	BankAccount *BankAccount `bson:"bank_account,omitempty" json:"bank_account"`
	Address     string       `bson:"address,omitempty" json:"address"`
}

// BankAccount ข้อมูลบัญชีธนาคาร
type BankAccount struct {
	Bank        string `bson:"bank" json:"bank"`
	AccountNo   string `bson:"account_no" json:"account_no"`
	AccountName string `bson:"account_name" json:"account_name"`
}

// PartnerVehicleInfo ข้อมูลรถของเจ้าของรถร่วม
type PartnerVehicleInfo struct {
	Plate           string `bson:"plate" json:"plate"`
	Brand           string `bson:"brand" json:"brand"`
	Model           string `bson:"model" json:"model"`
	Type            string `bson:"type" json:"type"`
	Year            int    `bson:"year" json:"year"`
	MaxWeightKg     int    `bson:"max_weight_kg" json:"max_weight_kg"`
	FuelType        string `bson:"fuel_type" json:"fuel_type"`
	RegistrationURL string `bson:"registration_url,omitempty" json:"registration_url"`
	InsuranceURL    string `bson:"insurance_url,omitempty" json:"insurance_url"`
	ActURL          string `bson:"act_url,omitempty" json:"act_url"`
}

// PartnerDriverInfo ข้อมูลคนขับของรถร่วม
type PartnerDriverInfo struct {
	Name          string    `bson:"name" json:"name"`
	Phone         string    `bson:"phone" json:"phone"`
	LicenseType   string    `bson:"license_type" json:"license_type"`
	LicenseExpiry time.Time `bson:"license_expiry" json:"license_expiry"`
}

// PartnerPricing ราคารถร่วม
type PartnerPricing struct {
	Model    string             `bson:"model" json:"model"` // "per_trip", "per_km", "per_day"
	BaseRate float64            `bson:"base_rate" json:"base_rate"`
	PerKm    float64            `bson:"per_km,omitempty" json:"per_km"`
	Zones    map[string]float64 `bson:"zones,omitempty" json:"zones"` // zone → ราคา
}

// WithholdingTax หัก ณ ที่จ่าย
type WithholdingTax struct {
	Rate float64 `bson:"rate" json:"rate"` // 0.01 = 1%
	Type string  `bson:"type" json:"type"` // "ภ.ง.ด.3"
}
