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

// RegisterPartnerRequest คำขอลงทะเบียนรถร่วม
type RegisterPartnerRequest struct {
	Owner          models.PartnerOwner      `json:"owner" binding:"required"`
	Vehicle        models.PartnerVehicleInfo `json:"vehicle" binding:"required"`
	Driver         models.PartnerDriverInfo  `json:"driver"`
	Pricing        models.PartnerPricing    `json:"pricing"`
	CoverageZones  []string                 `json:"coverage_zones"`
	WithholdingTax *models.WithholdingTax   `json:"withholding_tax"`
}

// UpdatePartnerRequest คำขออัปเดตรถร่วม
type UpdatePartnerRequest struct {
	Status        string                 `json:"status"`
	Pricing       *models.PartnerPricing `json:"pricing"`
	CoverageZones []string               `json:"coverage_zones"`
}

// FindAvailablePartnersRequest คำขอค้นหารถร่วมว่าง
type FindAvailablePartnersRequest struct {
	VehicleType string    `json:"vehicle_type"`
	Zone        string    `json:"zone"`
	Date        time.Time `json:"date"`
	MaxWeightKg int       `json:"max_weight_kg"`
}

// BookPartnerRequest คำขอจองรถร่วม
type BookPartnerRequest struct {
	PartnerID string    `json:"partner_id" binding:"required"`
	TripID    string    `json:"trip_id"`
	Date      time.Time `json:"date"`
	Zone      string    `json:"zone"`
	Notes     string    `json:"notes"`
}

// PartnerService business logic สำหรับรถร่วม
type PartnerService struct {
	mongoRepo     *mongorepo.PartnerRepo
	pgQuery       *pgquery.PartnerQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

// NewPartnerService สร้าง PartnerService ใหม่
func NewPartnerService(
	mongoRepo *mongorepo.PartnerRepo,
	pgQuery *pgquery.PartnerQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *PartnerService {
	return &PartnerService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// List ดึงรายการรถร่วมทั้งหมด
func (s *PartnerService) List(ctx context.Context, shopID, status string, page, limit int) ([]pgquery.PartnerRow, int, error) {
	return s.pgQuery.List(ctx, shopID, status, page, limit)
}

// GetByID ดึงรถร่วมคันเดียว
func (s *PartnerService) GetByID(ctx context.Context, shopID, id string) (*pgquery.PartnerRow, error) {
	return s.pgQuery.GetByID(ctx, shopID, id)
}

// Register ลงทะเบียนรถร่วมใหม่
func (s *PartnerService) Register(ctx context.Context, shopID, userID string, req RegisterPartnerRequest) (*models.PartnerVehicle, error) {
	partner := &models.PartnerVehicle{
		ID:            primitive.NewObjectID(),
		ShopID:        shopID,
		Owner:         req.Owner,
		Vehicle:       req.Vehicle,
		Driver:        req.Driver,
		Pricing:       req.Pricing,
		CoverageZones: req.CoverageZones,
		WithholdingTax: req.WithholdingTax,
		Rating:        5.0,
		TotalTrips:    0,
		Status:        "active",
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	if partner.WithholdingTax == nil {
		partner.WithholdingTax = &models.WithholdingTax{
			Rate: 0.01,
			Type: "ภ.ง.ด.3",
		}
	}

	if err := s.mongoRepo.Insert(ctx, partner); err != nil {
		return nil, fmt.Errorf("insert partner: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "partner.vehicle_registered", "partner_vehicle", partner.ID.Hex(), "create", userID, "admin", partner)

	s.kafkaProducer.Produce("fleet.partners", database.KafkaEvent{
		Type:      "partner.vehicle_registered",
		ShopID:    shopID,
		EntityID:  partner.ID.Hex(),
		Payload:   partner,
		Timestamp: time.Now(),
	})

	return partner, nil
}

// Update อัปเดตรถร่วม
func (s *PartnerService) Update(ctx context.Context, shopID, userID, id string, req UpdatePartnerRequest) error {
	update := bson.M{}
	if req.Status != "" {
		update["status"] = req.Status
	}
	if req.Pricing != nil {
		update["pricing"] = req.Pricing
	}
	if len(req.CoverageZones) > 0 {
		update["coverage_zones"] = req.CoverageZones
	}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("update partner: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "partner.updated", "partner_vehicle", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.partners", database.KafkaEvent{
		Type:      "partner.updated",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// Delete ลบรถร่วม (soft delete)
func (s *PartnerService) Delete(ctx context.Context, shopID, userID, id string) error {
	update := bson.M{"status": "inactive"}

	if err := s.mongoRepo.Update(ctx, id, update); err != nil {
		return fmt.Errorf("delete partner: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "partner.deactivated", "partner_vehicle", id, "delete", userID, "admin", bson.M{"id": id})

	s.kafkaProducer.Produce("fleet.partners", database.KafkaEvent{
		Type:      "partner.deactivated",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   bson.M{"id": id},
		Timestamp: time.Now(),
	})

	return nil
}

// FindAvailable ค้นหารถร่วมที่ว่าง
func (s *PartnerService) FindAvailable(ctx context.Context, shopID string, req FindAvailablePartnersRequest) ([]pgquery.PartnerRow, error) {
	return s.pgQuery.FindAvailable(ctx, shopID, req.VehicleType, req.Zone)
}

// Book จองรถร่วม + ส่งงาน
func (s *PartnerService) Book(ctx context.Context, shopID, userID string, req BookPartnerRequest) error {
	booking := bson.M{
		"partner_id": req.PartnerID,
		"trip_id":    req.TripID,
		"date":       req.Date,
		"zone":       req.Zone,
		"notes":      req.Notes,
		"status":     "booked",
		"booked_at":  time.Now(),
		"booked_by":  userID,
	}

	s.eventLogger.Log(ctx, shopID, "partner.booked", "partner_vehicle", req.PartnerID, "update", userID, "admin", booking)

	s.kafkaProducer.Produce("fleet.partners", database.KafkaEvent{
		Type:      "partner.booked",
		ShopID:    shopID,
		EntityID:  req.PartnerID,
		Payload:   booking,
		Timestamp: time.Now(),
	})

	return nil
}

// GetSettlements ดึงรายการจ่ายเงินรถร่วม
func (s *PartnerService) GetSettlements(ctx context.Context, shopID string, page, limit int) ([]pgquery.PartnerSettlementRow, int, error) {
	return s.pgQuery.GetSettlements(ctx, shopID, page, limit)
}

// CalculatePayment คำนวณค่าจ้างรถร่วม + หัก ณ ที่จ่าย
func (s *PartnerService) CalculatePayment(ctx context.Context, shopID, partnerID string, tripIDs []string) (*PartnerPaymentResult, error) {
	partner, err := s.mongoRepo.FindByID(ctx, shopID, partnerID)
	if err != nil {
		return nil, fmt.Errorf("get partner: %w", err)
	}

	// ดึงรายการเที่ยวที่ต้องจ่าย
	trips, err := s.pgQuery.GetPartnerTrips(ctx, shopID, partnerID, tripIDs)
	if err != nil {
		return nil, fmt.Errorf("get partner trips: %w", err)
	}

	var grossAmount float64
	for _, t := range trips {
		if t.TotalCost != nil {
			grossAmount += *t.TotalCost
		}
	}

	var withholdingRate float64
	if partner.WithholdingTax != nil {
		withholdingRate = partner.WithholdingTax.Rate
	}
	withholdingAmount := grossAmount * withholdingRate
	netAmount := grossAmount - withholdingAmount

	return &PartnerPaymentResult{
		PartnerID:         partnerID,
		PartnerName:       partner.Owner.Name,
		TripCount:         len(trips),
		GrossAmount:       grossAmount,
		WithholdingRate:   withholdingRate,
		WithholdingAmount: withholdingAmount,
		NetAmount:         netAmount,
		BankAccount:       partner.Owner.BankAccount,
	}, nil
}

// PartnerPaymentResult ผลการคำนวณค่าจ้างรถร่วม
type PartnerPaymentResult struct {
	PartnerID         string               `json:"partner_id"`
	PartnerName       string               `json:"partner_name"`
	TripCount         int                  `json:"trip_count"`
	GrossAmount       float64              `json:"gross_amount"`
	WithholdingRate   float64              `json:"withholding_rate"`
	WithholdingAmount float64              `json:"withholding_amount"`
	NetAmount         float64              `json:"net_amount"`
	BankAccount       *models.BankAccount  `json:"bank_account"`
}
