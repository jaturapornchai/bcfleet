package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Driver ข้อมูลคนขับรถ
type Driver struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID      string             `bson:"shop_id" json:"shop_id"`
	EmployeeID  string             `bson:"employee_id" json:"employee_id"`
	Name        string             `bson:"name" json:"name"`
	Nickname    string             `bson:"nickname" json:"nickname"`
	Phone       string             `bson:"phone" json:"phone"`
	IDCard      string             `bson:"id_card" json:"id_card"`
	Address     string             `bson:"address" json:"address"`
	DateOfBirth *time.Time         `bson:"date_of_birth,omitempty" json:"date_of_birth"`
	PhotoURL    string             `bson:"photo_url,omitempty" json:"photo_url"`

	License *DriverLicense `bson:"license,omitempty" json:"license"`
	DLTCard *DLTCard       `bson:"dlt_card,omitempty" json:"dlt_card"` // บัตรกรมขนส่ง

	Employment *Employment `bson:"employment,omitempty" json:"employment"`
	HealthCheck *HealthCheck `bson:"health_check,omitempty" json:"health_check"`

	AccidentHistory []AccidentRecord `bson:"accident_history,omitempty" json:"accident_history"`

	AssignedVehicleID string `bson:"assigned_vehicle_id,omitempty" json:"assigned_vehicle_id"`
	Status            string `bson:"status" json:"status"` // "active", "on_leave", "suspended", "resigned"

	Zones        []string `bson:"zones,omitempty" json:"zones"`
	VehicleTypes []string `bson:"vehicle_types,omitempty" json:"vehicle_types"`

	Performance *DriverPerformance `bson:"performance,omitempty" json:"performance"`
	Schedule    *DriverSchedule    `bson:"schedule,omitempty" json:"schedule"`

	CreatedAt time.Time  `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time  `bson:"updated_at" json:"updated_at"`
	DeletedAt *time.Time `bson:"deleted_at,omitempty" json:"deleted_at"`
}

// DriverLicense ใบอนุญาตขับขี่
type DriverLicense struct {
	Number     string    `bson:"number" json:"number"`
	Type       string    `bson:"type" json:"type"` // "ท.1", "ท.2", "ท.3", "ท.4"
	IssueDate  time.Time `bson:"issue_date" json:"issue_date"`
	ExpiryDate time.Time `bson:"expiry_date" json:"expiry_date"`
	PhotoURL   string    `bson:"photo_url,omitempty" json:"photo_url"`
}

// DLTCard บัตรประจำตัวผู้ขับรถ (กรมขนส่งทางบก)
type DLTCard struct {
	Number     string    `bson:"number" json:"number"`
	ExpiryDate time.Time `bson:"expiry_date" json:"expiry_date"`
	PhotoURL   string    `bson:"photo_url,omitempty" json:"photo_url"`
}

// Employment ข้อมูลการจ้างงาน
type Employment struct {
	Type           string    `bson:"type" json:"type"` // "permanent", "contract", "daily", "partner"
	StartDate      time.Time `bson:"start_date" json:"start_date"`
	Salary         float64   `bson:"salary" json:"salary"`
	DailyAllowance float64   `bson:"daily_allowance" json:"daily_allowance"`
	TripBonus      float64   `bson:"trip_bonus" json:"trip_bonus"`
	OvertimeRate   float64   `bson:"overtime_rate" json:"overtime_rate"`
}

// HealthCheck ตรวจสุขภาพ
type HealthCheck struct {
	LastDate time.Time `bson:"last_date" json:"last_date"`
	Result   string    `bson:"result" json:"result"`
	NextDue  time.Time `bson:"next_due" json:"next_due"`
	DrugTest string    `bson:"drug_test" json:"drug_test"`
}

// AccidentRecord ประวัติอุบัติเหตุ
type AccidentRecord struct {
	Date        time.Time `bson:"date" json:"date"`
	Description string    `bson:"description" json:"description"`
	Damage      string    `bson:"damage" json:"damage"` // "minor", "moderate", "major"
	Cost        float64   `bson:"cost" json:"cost"`
}

// DriverPerformance ผลงานคนขับ
type DriverPerformance struct {
	TotalTrips     int     `bson:"total_trips" json:"total_trips"`
	OnTimeRate     float64 `bson:"on_time_rate" json:"on_time_rate"`
	FuelEfficiency float64 `bson:"fuel_efficiency" json:"fuel_efficiency"` // km/L
	CustomerRating float64 `bson:"customer_rating" json:"customer_rating"` // 0-5
	AccidentCount  int     `bson:"accident_count" json:"accident_count"`
	ViolationCount int     `bson:"violation_count" json:"violation_count"`
	Score          int     `bson:"score" json:"score"` // 0-100
}

// DriverSchedule ตารางเวร
type DriverSchedule struct {
	Shift   string        `bson:"shift" json:"shift"` // "เช้า", "บ่าย", "ปกติ"
	DaysOff []string      `bson:"days_off" json:"days_off"`
	Leaves  []LeaveRecord `bson:"leaves,omitempty" json:"leaves"`
}

// LeaveRecord ประวัติการลา
type LeaveRecord struct {
	Type     string    `bson:"type" json:"type"` // "ลาป่วย", "ลากิจ", "ลาพักร้อน"
	From     time.Time `bson:"from" json:"from"`
	To       time.Time `bson:"to" json:"to"`
	Approved bool      `bson:"approved" json:"approved"`
}
