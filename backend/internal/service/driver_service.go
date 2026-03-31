package service

import (
	"context"
	"fmt"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/eventlog"
	"sml-fleet/internal/models"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateDriverRequest คำขอสร้างคนขับใหม่
type CreateDriverRequest struct {
	EmployeeID     string   `json:"employee_id"`
	Name           string   `json:"name" binding:"required"`
	Nickname       string   `json:"nickname"`
	Phone          string   `json:"phone" binding:"required"`
	IDCard         string   `json:"id_card"`
	Address        string   `json:"address"`
	EmploymentType string   `json:"employment_type"`
	Salary         float64  `json:"salary"`
	DailyAllowance float64  `json:"daily_allowance"`
	TripBonus      float64  `json:"trip_bonus"`
	Zones          []string `json:"zones"`
	VehicleTypes   []string `json:"vehicle_types"`
}

// UpdateDriverRequest คำขออัปเดตข้อมูลคนขับ
type UpdateDriverRequest struct {
	Name           string   `json:"name"`
	Nickname       string   `json:"nickname"`
	Phone          string   `json:"phone"`
	Address        string   `json:"address"`
	Status         string   `json:"status"`
	Salary         float64  `json:"salary"`
	DailyAllowance float64  `json:"daily_allowance"`
	TripBonus      float64  `json:"trip_bonus"`
	Zones          []string `json:"zones"`
	VehicleTypes   []string `json:"vehicle_types"`
}

// DriverService business logic สำหรับคนขับรถ
type DriverService struct {
	mongoRepo     *mongorepo.DriverRepo
	pgQuery       *pgquery.DriverQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

// NewDriverService สร้าง DriverService ใหม่
func NewDriverService(
	mongoRepo *mongorepo.DriverRepo,
	pgQuery *pgquery.DriverQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *DriverService {
	return &DriverService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// List ดึงรายการคนขับ (อ่านจาก PostgreSQL)
func (s *DriverService) List(ctx context.Context, shopID, status, zone string, page, limit int) ([]pgquery.DriverRow, int, error) {
	// zone filter ทำใน application layer (pgquery.List ไม่รับ zone)
	return s.pgQuery.List(ctx, shopID, status, page, limit)
}

// GetByID ดึงข้อมูลคนขับคนเดียว
func (s *DriverService) GetByID(ctx context.Context, shopID, id string) (*pgquery.DriverRow, error) {
	return s.pgQuery.GetByID(ctx, shopID, id)
}

// Create สร้างคนขับใหม่ (เขียน MongoDB → Event Log → Kafka)
func (s *DriverService) Create(ctx context.Context, shopID, userID string, req CreateDriverRequest) (*models.Driver, error) {
	if req.EmploymentType == "" {
		req.EmploymentType = "permanent"
	}

	driver := &models.Driver{
		ID:         primitive.NewObjectID(),
		ShopID:     shopID,
		EmployeeID: req.EmployeeID,
		Name:       req.Name,
		Nickname:   req.Nickname,
		Phone:      req.Phone,
		IDCard:     req.IDCard,
		Address:    req.Address,
		Employment: &models.Employment{
			Type:           req.EmploymentType,
			Salary:         req.Salary,
			DailyAllowance: req.DailyAllowance,
			TripBonus:      req.TripBonus,
		},
		Zones:        req.Zones,
		VehicleTypes: req.VehicleTypes,
		Status:       "active",
		Performance: &models.DriverPerformance{
			Score: 100,
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.mongoRepo.Insert(ctx, driver); err != nil {
		return nil, fmt.Errorf("insert driver: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "driver.created", "driver", driver.ID.Hex(), "create", userID, "admin", driver)

	s.kafkaProducer.Produce("fleet.drivers", database.KafkaEvent{
		Type:      "driver.created",
		ShopID:    shopID,
		EntityID:  driver.ID.Hex(),
		Payload:   driver,
		Timestamp: time.Now(),
	})

	return driver, nil
}

// Update อัปเดตข้อมูลคนขับ
func (s *DriverService) Update(ctx context.Context, shopID, userID, id string, req UpdateDriverRequest) error {
	update := bson.M{}
	if req.Name != "" {
		update["name"] = req.Name
	}
	if req.Nickname != "" {
		update["nickname"] = req.Nickname
	}
	if req.Phone != "" {
		update["phone"] = req.Phone
	}
	if req.Address != "" {
		update["address"] = req.Address
	}
	if req.Status != "" {
		update["status"] = req.Status
	}
	if req.Salary > 0 {
		update["employment.salary"] = req.Salary
	}
	if req.DailyAllowance > 0 {
		update["employment.daily_allowance"] = req.DailyAllowance
	}
	if req.TripBonus > 0 {
		update["employment.trip_bonus"] = req.TripBonus
	}
	if len(req.Zones) > 0 {
		update["zones"] = req.Zones
	}
	if len(req.VehicleTypes) > 0 {
		update["vehicle_types"] = req.VehicleTypes
	}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("update driver: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "driver.updated", "driver", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.drivers", database.KafkaEvent{
		Type:      "driver.updated",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// Delete ลบคนขับแบบ soft delete
func (s *DriverService) Delete(ctx context.Context, shopID, userID, id string) error {
	if err := s.mongoRepo.SoftDelete(ctx, shopID, id); err != nil {
		return fmt.Errorf("delete driver: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "driver.deleted", "driver", id, "delete", userID, "admin", bson.M{"id": id})

	s.kafkaProducer.Produce("fleet.drivers", database.KafkaEvent{
		Type:      "driver.deleted",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   bson.M{"id": id},
		Timestamp: time.Now(),
	})

	return nil
}

// GetScore ดึง KPI score ของคนขับ
func (s *DriverService) GetScore(ctx context.Context, shopID, id string) (*pgquery.DriverScoreRow, error) {
	return s.pgQuery.GetScore(ctx, shopID, id)
}

// GetSchedule ดึงตารางเวรของคนขับจาก MongoDB
func (s *DriverService) GetSchedule(ctx context.Context, shopID, id string) (*models.Driver, error) {
	return s.mongoRepo.FindByID(ctx, shopID, id)
}

// CalculateSalary คำนวณเงินเดือน + เบี้ยเลี้ยง + OT
func (s *DriverService) CalculateSalary(ctx context.Context, shopID, id string, month, year int) (*DriverSalaryResult, error) {
	driver, err := s.mongoRepo.FindByID(ctx, shopID, id)
	if err != nil {
		return nil, fmt.Errorf("get driver: %w", err)
	}

	// ดึง total_trips จาก PostgreSQL (driver row)
	driverRow, err := s.pgQuery.GetByID(ctx, shopID, id)
	if err != nil {
		return nil, fmt.Errorf("get driver pg: %w", err)
	}
	tripCount := driverRow.TotalTrips

	var baseSalary, dailyAllowance, tripBonus float64
	if driver.Employment != nil {
		baseSalary = driver.Employment.Salary
		dailyAllowance = driver.Employment.DailyAllowance
		tripBonus = driver.Employment.TripBonus
	}

	workingDays := 26 // ค่าเริ่มต้น 26 วันทำงานต่อเดือน
	totalAllowance := dailyAllowance * float64(workingDays)
	totalTripBonus := tripBonus * float64(tripCount)
	total := baseSalary + totalAllowance + totalTripBonus

	return &DriverSalaryResult{
		DriverID:       id,
		DriverName:     driver.Name,
		Month:          month,
		Year:           year,
		BaseSalary:     baseSalary,
		WorkingDays:    workingDays,
		DailyAllowance: totalAllowance,
		TripCount:      tripCount,
		TripBonus:      totalTripBonus,
		Total:          total,
	}, nil
}

// DriverSalaryResult ผลการคำนวณเงินเดือน
type DriverSalaryResult struct {
	DriverID       string  `json:"driver_id"`
	DriverName     string  `json:"driver_name"`
	Month          int     `json:"month"`
	Year           int     `json:"year"`
	BaseSalary     float64 `json:"base_salary"`
	WorkingDays    int     `json:"working_days"`
	DailyAllowance float64 `json:"daily_allowance"`
	TripCount      int     `json:"trip_count"`
	TripBonus      float64 `json:"trip_bonus"`
	OvertimePay    float64 `json:"overtime_pay"`
	Deductions     float64 `json:"deductions"`
	Total          float64 `json:"total"`
}
