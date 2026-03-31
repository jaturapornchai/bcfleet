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

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateExpenseRequest คำขอบันทึกค่าใช้จ่าย
type CreateExpenseRequest struct {
	TripID      string              `json:"trip_id"`
	VehicleID   string              `json:"vehicle_id" binding:"required"`
	DriverID    string              `json:"driver_id"`
	Type        string              `json:"type" binding:"required"` // "fuel", "toll", "parking", "repair", "fine", "other"
	Description string              `json:"description"`
	Amount      float64             `json:"amount" binding:"required"`
	FuelDetail  *models.FuelDetail  `json:"fuel_detail"`
	ReceiptURL  string              `json:"receipt_url"`
}

// ExpenseService business logic สำหรับค่าใช้จ่าย
type ExpenseService struct {
	mongoRepo     *mongorepo.ExpenseRepo
	pgQuery       *pgquery.ExpenseQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

// NewExpenseService สร้าง ExpenseService ใหม่
func NewExpenseService(
	mongoRepo *mongorepo.ExpenseRepo,
	pgQuery *pgquery.ExpenseQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *ExpenseService {
	return &ExpenseService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// List ดึงรายการค่าใช้จ่าย (อ่านจาก PostgreSQL)
func (s *ExpenseService) List(ctx context.Context, shopID, vehicleID, expenseType string, page, limit int) ([]pgquery.ExpenseRow, int, error) {
	return s.pgQuery.ListSimple(ctx, shopID, vehicleID, expenseType, page, limit)
}

// Create บันทึกค่าใช้จ่ายใหม่ (เขียน MongoDB → Event Log → Kafka)
func (s *ExpenseService) Create(ctx context.Context, shopID, userID string, req CreateExpenseRequest) (*models.Expense, error) {
	expense := &models.Expense{
		ID:          primitive.NewObjectID(),
		ShopID:      shopID,
		TripID:      req.TripID,
		VehicleID:   req.VehicleID,
		DriverID:    req.DriverID,
		Type:        req.Type,
		Description: req.Description,
		Amount:      req.Amount,
		FuelDetail:  req.FuelDetail,
		ReceiptURL:  req.ReceiptURL,
		RecordedBy:  userID,
		RecordedAt:  time.Now(),
		CreatedAt:   time.Now(),
	}

	if req.Type == "fuel" && req.FuelDetail != nil && req.FuelDetail.Liters > 0 {
		expense.Amount = req.FuelDetail.Liters * req.FuelDetail.PricePerLiter
	}

	if err := s.mongoRepo.Insert(ctx, expense); err != nil {
		return nil, fmt.Errorf("insert expense: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "expense.recorded", "expense", expense.ID.Hex(), "create", userID, "driver", expense)

	s.kafkaProducer.Produce("fleet.expenses", database.KafkaEvent{
		Type:      "expense.recorded",
		ShopID:    shopID,
		EntityID:  expense.ID.Hex(),
		Payload:   expense,
		Timestamp: time.Now(),
	})

	return expense, nil
}

// GetFuelReport ดึงรายงานน้ำมัน
func (s *ExpenseService) GetFuelReport(ctx context.Context, shopID, vehicleID string, from, to time.Time) (*pgquery.FuelReportRow, error) {
	return s.pgQuery.GetFuelReportByVehicle(ctx, shopID, vehicleID, from, to)
}

// GetPLPerVehicle ดึง P&L ต่อคัน
func (s *ExpenseService) GetPLPerVehicle(ctx context.Context, shopID, vehicleID string, month, year int) (*pgquery.PLPerVehicleRow, error) {
	return s.pgQuery.GetPLPerVehicle(ctx, shopID, vehicleID, month, year)
}
