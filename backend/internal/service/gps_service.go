package service

import (
	"context"
	"fmt"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/models"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RecordLocationRequest คำขอบันทึก GPS location
type RecordLocationRequest struct {
	VehicleID  string    `json:"vehicle_id" binding:"required"`
	DriverID   string    `json:"driver_id"`
	TripID     string    `json:"trip_id"`
	Lat        float64   `json:"lat" binding:"required"`
	Lng        float64   `json:"lng" binding:"required"`
	SpeedKmh   float64   `json:"speed_kmh"`
	Heading    int       `json:"heading"`
	AccuracyM  float64   `json:"accuracy_m"`
	BatteryPct int       `json:"battery_pct"`
	Timestamp  time.Time `json:"timestamp"`
}

// GPSService business logic สำหรับ GPS tracking
type GPSService struct {
	mongoRepo     *mongorepo.GPSRepo
	pgQuery       *pgquery.GPSQuery
	kafkaProducer *database.KafkaProducer
}

// NewGPSService สร้าง GPSService ใหม่
func NewGPSService(
	mongoRepo *mongorepo.GPSRepo,
	pgQuery *pgquery.GPSQuery,
	kafkaProducer *database.KafkaProducer,
) *GPSService {
	return &GPSService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		kafkaProducer: kafkaProducer,
	}
}

// RecordLocation บันทึก GPS location (เขียน MongoDB → Kafka → PostgreSQL latest)
func (s *GPSService) RecordLocation(ctx context.Context, shopID string, req RecordLocationRequest) error {
	ts := req.Timestamp
	if ts.IsZero() {
		ts = time.Now()
	}

	gpsLog := &models.GPSLog{
		ID:        primitive.NewObjectID(),
		ShopID:    shopID,
		VehicleID: req.VehicleID,
		DriverID:  req.DriverID,
		TripID:    req.TripID,
		Location: models.GeoJSON{
			Type:        "Point",
			Coordinates: []float64{req.Lng, req.Lat}, // GeoJSON: [lng, lat]
		},
		SpeedKmh:   req.SpeedKmh,
		Heading:    req.Heading,
		AccuracyM:  req.AccuracyM,
		BatteryPct: req.BatteryPct,
		Timestamp:  ts,
		CreatedAt:  time.Now(),
	}

	// เขียน MongoDB (GPS log ทั้งหมด)
	if err := s.mongoRepo.InsertLog(ctx, gpsLog); err != nil {
		return fmt.Errorf("insert gps log: %w", err)
	}

	// Produce ไป Kafka → Consumer จะ upsert fleet_vehicle_locations (current only)
	s.kafkaProducer.Produce("fleet.gps", database.KafkaEvent{
		Type:      "gps.location_updated",
		ShopID:    shopID,
		EntityID:  req.VehicleID,
		Payload:   gpsLog,
		Timestamp: time.Now(),
	})

	return nil
}

// GetVehicleLocations ดึงตำแหน่งรถทุกคันปัจจุบัน
func (s *GPSService) GetVehicleLocations(ctx context.Context, shopID string) ([]pgquery.VehicleLocationRow, error) {
	return s.pgQuery.GetAllLocations(ctx, shopID)
}

// GetMovingVehicles ดึงรถที่กำลังเคลื่อนที่ (เปลี่ยนตำแหน่ง > minDistanceM เมตร ใน maxAgeMinutes นาทีที่ผ่านมา)
func (s *GPSService) GetMovingVehicles(ctx context.Context, shopID string, minDistanceM float64, maxAgeMinutes int) ([]pgquery.MovingVehicleRow, error) {
	return s.pgQuery.GetMovingVehicles(ctx, shopID, minDistanceM, maxAgeMinutes)
}

// GetTrail ดึงเส้นทางย้อนหลังจาก MongoDB
func (s *GPSService) GetTrail(ctx context.Context, shopID, vehicleID string, from, to time.Time) ([]*models.GPSLog, error) {
	return s.mongoRepo.FindTrail(ctx, shopID, vehicleID, from, to)
}
