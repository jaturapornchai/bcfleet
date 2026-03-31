package service

import (
	"context"
	"fmt"
	"time"

	"bc-fleet/internal/database"
	"bc-fleet/internal/eventlog"
	"bc-fleet/internal/models"
	mongorepo "bc-fleet/internal/repository/mongo"
	pgquery "bc-fleet/internal/repository/postgres"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateTripRequest คำขอสร้างเที่ยววิ่งใหม่
type CreateTripRequest struct {
	VehicleID    string              `json:"vehicle_id"`
	DriverID     string              `json:"driver_id"`
	IsPartner    bool                `json:"is_partner"`
	PartnerID    string              `json:"partner_id"`
	Origin       models.TripLocation `json:"origin" binding:"required"`
	Destinations []models.Destination `json:"destinations" binding:"required"`
	Cargo        *models.CargoInfo   `json:"cargo"`
	PlannedStart time.Time           `json:"planned_start"`
	PlannedEnd   time.Time           `json:"planned_end"`
	Revenue      float64             `json:"revenue"`
}

// UpdateTripStatusRequest คำขอเปลี่ยนสถานะเที่ยว
type UpdateTripStatusRequest struct {
	Status string `json:"status" binding:"required"`
}

// AssignTripRequest คำขอมอบหมายรถ+คนขับ
type AssignTripRequest struct {
	VehicleID string `json:"vehicle_id" binding:"required"`
	DriverID  string `json:"driver_id" binding:"required"`
	IsPartner bool   `json:"is_partner"`
	PartnerID string `json:"partner_id"`
}

// PODRequest คำขออัปโหลด POD
type PODRequest struct {
	Photos       []string `json:"photos"`
	SignatureURL string   `json:"signature_url"`
	ReceiverName string   `json:"receiver_name"`
	Notes        string   `json:"notes"`
}

// TripService business logic สำหรับเที่ยววิ่ง
type TripService struct {
	mongoRepo     *mongorepo.TripRepo
	pgQuery       *pgquery.TripQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

// NewTripService สร้าง TripService ใหม่
func NewTripService(
	mongoRepo *mongorepo.TripRepo,
	pgQuery *pgquery.TripQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *TripService {
	return &TripService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// List ดึงรายการเที่ยววิ่ง (อ่านจาก PostgreSQL)
func (s *TripService) List(ctx context.Context, shopID, status, driverID, vehicleID string, page, limit int) ([]pgquery.TripRow, int, error) {
	return s.pgQuery.ListSimple(ctx, shopID, status, driverID, vehicleID, page, limit)
}

// GetByID ดึงเที่ยววิ่งคันเดียว
func (s *TripService) GetByID(ctx context.Context, shopID, id string) (*pgquery.TripRow, error) {
	return s.pgQuery.GetByID(ctx, shopID, id)
}

// Create สร้างเที่ยววิ่งใหม่ (เขียน MongoDB → Event Log → Kafka)
func (s *TripService) Create(ctx context.Context, shopID, userID string, req CreateTripRequest) (*models.Trip, error) {
	tripNo := fmt.Sprintf("TRIP-%s-%06d", time.Now().Format("20060102"), time.Now().UnixMilli()%1000000)

	// set seq ให้ destinations
	for i := range req.Destinations {
		req.Destinations[i].Seq = i + 1
		req.Destinations[i].Status = "pending"
	}

	trip := &models.Trip{
		ID:           primitive.NewObjectID(),
		ShopID:       shopID,
		TripNo:       tripNo,
		Status:       "draft",
		VehicleID:    req.VehicleID,
		DriverID:     req.DriverID,
		IsPartner:    req.IsPartner,
		PartnerID:    req.PartnerID,
		Origin:       req.Origin,
		Destinations: req.Destinations,
		Cargo:        req.Cargo,
		Schedule: &models.TripSchedule{
			PlannedStart: req.PlannedStart,
			PlannedEnd:   req.PlannedEnd,
		},
		Costs:     &models.TripCosts{Revenue: req.Revenue},
		CreatedBy: userID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.mongoRepo.Insert(ctx, trip); err != nil {
		return nil, fmt.Errorf("insert trip: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "trip.created", "trip", trip.ID.Hex(), "create", userID, "admin", trip)

	s.kafkaProducer.Produce("fleet.trips", database.KafkaEvent{
		Type:      "trip.created",
		ShopID:    shopID,
		EntityID:  trip.ID.Hex(),
		Payload:   trip,
		Timestamp: time.Now(),
	})

	return trip, nil
}

// UpdateStatus เปลี่ยนสถานะเที่ยว
func (s *TripService) UpdateStatus(ctx context.Context, shopID, userID, id string, req UpdateTripStatusRequest) error {
	update := bson.M{"status": req.Status}

	now := time.Now()
	switch req.Status {
	case "started":
		update["schedule.actual_start"] = now
	case "completed":
		update["schedule.actual_end"] = now
	}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("update trip status: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "trip.status_updated", "trip", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.trips", database.KafkaEvent{
		Type:      "trip.status_updated",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// Assign มอบหมายรถ + คนขับให้เที่ยววิ่ง
func (s *TripService) Assign(ctx context.Context, shopID, userID, id string, req AssignTripRequest) error {
	update := bson.M{
		"vehicle_id": req.VehicleID,
		"driver_id":  req.DriverID,
		"is_partner": req.IsPartner,
		"status":     "pending",
	}
	if req.PartnerID != "" {
		update["partner_id"] = req.PartnerID
	}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("assign trip: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "trip.assigned", "trip", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.trips", database.KafkaEvent{
		Type:      "trip.assigned",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// UploadPOD บันทึก Proof of Delivery
func (s *TripService) UploadPOD(ctx context.Context, shopID, userID, id string, req PODRequest) error {
	pod := models.ProofOfDelivery{
		Photos:       req.Photos,
		SignatureURL: req.SignatureURL,
		ReceiverName: req.ReceiverName,
		Notes:        req.Notes,
		Timestamp:    time.Now(),
	}

	update := bson.M{
		"pod":    pod,
		"status": "completed",
	}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("upload POD: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "trip.pod_uploaded", "trip", id, "update", userID, "driver", pod)

	s.kafkaProducer.Produce("fleet.trips", database.KafkaEvent{
		Type:      "trip.pod_uploaded",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// GetTracking ดึงข้อมูล GPS tracking ของเที่ยว
func (s *TripService) GetTracking(ctx context.Context, shopID, id string) ([]pgquery.GPSTrailRow, error) {
	return s.pgQuery.GetTripTracking(ctx, id)
}

// GetPOD ดึง POD ของเที่ยว
func (s *TripService) GetPOD(ctx context.Context, shopID, id string) (*models.ProofOfDelivery, error) {
	trip, err := s.mongoRepo.FindByID(ctx, shopID, id)
	if err != nil {
		return nil, err
	}
	return trip.POD, nil
}

// GetCostBreakdown ดึงรายละเอียดต้นทุนต่อเที่ยว
func (s *TripService) GetCostBreakdown(ctx context.Context, shopID, id string) (*pgquery.TripCostRow, error) {
	return s.pgQuery.GetCostBreakdown(ctx, shopID, id)
}
