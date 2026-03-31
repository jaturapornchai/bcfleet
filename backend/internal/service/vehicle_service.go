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

// CreateVehicleRequest คำขอสร้างรถใหม่
type CreateVehicleRequest struct {
	Plate       string  `json:"plate" binding:"required"`
	Brand       string  `json:"brand"`
	Model       string  `json:"model"`
	Type        string  `json:"type" binding:"required"`
	Year        int     `json:"year"`
	Color       string  `json:"color"`
	ChassisNo   string  `json:"chassis_no"`
	EngineNo    string  `json:"engine_no"`
	FuelType    string  `json:"fuel_type"`
	MaxWeightKg int     `json:"max_weight_kg"`
	Ownership   string  `json:"ownership"`
	MileageKm   int     `json:"mileage_km"`
}

// UpdateVehicleRequest คำขออัปเดตข้อมูลรถ
type UpdateVehicleRequest struct {
	Brand       string  `json:"brand"`
	Model       string  `json:"model"`
	Color       string  `json:"color"`
	FuelType    string  `json:"fuel_type"`
	MaxWeightKg int     `json:"max_weight_kg"`
	Status      string  `json:"status"`
	MileageKm   int     `json:"mileage_km"`
}

// VehicleService business logic สำหรับรถขนส่ง
type VehicleService struct {
	mongoRepo     *mongorepo.VehicleRepo
	mongoDB       *database.MongoDB
	pgQuery       *pgquery.VehicleQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

// NewVehicleService สร้าง VehicleService ใหม่
func NewVehicleService(
	mongoRepo *mongorepo.VehicleRepo,
	pgQuery *pgquery.VehicleQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *VehicleService {
	return &VehicleService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// WithMongoDB inject mongoDB สำหรับ event log queries
func (s *VehicleService) WithMongoDB(db *database.MongoDB) *VehicleService {
	s.mongoDB = db
	return s
}

// List ดึงรายการรถ (อ่านจาก PostgreSQL)
func (s *VehicleService) List(ctx context.Context, shopID, status, vehicleType string, page, limit int) ([]pgquery.VehicleRow, int, error) {
	return s.pgQuery.List(ctx, shopID, status, vehicleType, page, limit)
}

// GetByID ดึงข้อมูลรถคันเดียว
func (s *VehicleService) GetByID(ctx context.Context, shopID, id string) (*pgquery.VehicleRow, error) {
	return s.pgQuery.GetByID(ctx, shopID, id)
}

// Create สร้างรถใหม่ (เขียน MongoDB → Event Log → Kafka)
func (s *VehicleService) Create(ctx context.Context, shopID, userID string, req CreateVehicleRequest) (*models.Vehicle, error) {
	if req.Ownership == "" {
		req.Ownership = "own"
	}

	vehicle := &models.Vehicle{
		ID:          primitive.NewObjectID(),
		ShopID:      shopID,
		Plate:       req.Plate,
		Brand:       req.Brand,
		Model:       req.Model,
		Type:        req.Type,
		Year:        req.Year,
		Color:       req.Color,
		ChassisNo:   req.ChassisNo,
		EngineNo:    req.EngineNo,
		FuelType:    req.FuelType,
		MaxWeightKg: req.MaxWeightKg,
		Ownership:   req.Ownership,
		MileageKm:   req.MileageKm,
		Status:      "active",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := s.mongoRepo.Insert(ctx, vehicle); err != nil {
		return nil, fmt.Errorf("insert vehicle: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "vehicle.created", "vehicle", vehicle.ID.Hex(), "create", userID, "admin", vehicle)

	s.kafkaProducer.Produce("fleet.vehicles", database.KafkaEvent{
		Type:      "vehicle.created",
		ShopID:    shopID,
		EntityID:  vehicle.ID.Hex(),
		Payload:   vehicle,
		Timestamp: time.Now(),
	})

	return vehicle, nil
}

// Update อัปเดตข้อมูลรถ
func (s *VehicleService) Update(ctx context.Context, shopID, userID, id string, req UpdateVehicleRequest) error {
	update := bson.M{}
	if req.Brand != "" {
		update["brand"] = req.Brand
	}
	if req.Model != "" {
		update["model"] = req.Model
	}
	if req.Color != "" {
		update["color"] = req.Color
	}
	if req.FuelType != "" {
		update["fuel_type"] = req.FuelType
	}
	if req.MaxWeightKg > 0 {
		update["max_weight_kg"] = req.MaxWeightKg
	}
	if req.Status != "" {
		update["status"] = req.Status
	}
	if req.MileageKm > 0 {
		update["mileage_km"] = req.MileageKm
	}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("update vehicle: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "vehicle.updated", "vehicle", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.vehicles", database.KafkaEvent{
		Type:      "vehicle.updated",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// Delete ลบรถแบบ soft delete
func (s *VehicleService) Delete(ctx context.Context, shopID, userID, id string) error {
	if err := s.mongoRepo.SoftDelete(ctx, shopID, id); err != nil {
		return fmt.Errorf("delete vehicle: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "vehicle.deleted", "vehicle", id, "delete", userID, "admin", bson.M{"id": id})

	s.kafkaProducer.Produce("fleet.vehicles", database.KafkaEvent{
		Type:      "vehicle.deleted",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   bson.M{"id": id},
		Timestamp: time.Now(),
	})

	return nil
}

// GetHealth ดึงสถานะสุขภาพรถ
func (s *VehicleService) GetHealth(ctx context.Context, shopID, id string) (*pgquery.VehicleHealthRow, error) {
	return s.pgQuery.GetHealth(ctx, shopID, id)
}

// GetHistory ดึงประวัติทั้งหมดจาก MongoDB event logs
func (s *VehicleService) GetHistory(ctx context.Context, shopID, id string) ([]*models.EventLog, error) {
	filter := bson.M{
		"shop_id":   shopID,
		"entity":    "vehicle",
		"entity_id": id,
	}
	cursor, err := s.mongoDB.Collection("fleet_event_logs").Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("find event logs: %w", err)
	}
	defer cursor.Close(ctx)

	var logs []*models.EventLog
	if err := cursor.All(ctx, &logs); err != nil {
		return nil, err
	}
	return logs, nil
}
