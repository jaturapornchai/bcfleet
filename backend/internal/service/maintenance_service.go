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

// CreateWorkOrderRequest คำขอสร้างใบสั่งซ่อม
type CreateWorkOrderRequest struct {
	VehicleID       string                  `json:"vehicle_id" binding:"required"`
	Type            string                  `json:"type" binding:"required"` // "preventive", "corrective", "emergency"
	Priority        string                  `json:"priority"`
	Description     string                  `json:"description" binding:"required"`
	Symptoms        string                  `json:"symptoms"`
	MileageAtReport int                     `json:"mileage_at_report"`
	ServiceProvider *models.ServiceProvider `json:"service_provider"`
	Parts           []models.WOPart         `json:"parts"`
	Labor           *models.LaborCost       `json:"labor"`
}

// UpdateWorkOrderRequest คำขออัปเดตใบสั่งซ่อม
type UpdateWorkOrderRequest struct {
	Status          string                  `json:"status"`
	Description     string                  `json:"description"`
	ServiceProvider *models.ServiceProvider `json:"service_provider"`
	Parts           []models.WOPart         `json:"parts"`
	Labor           *models.LaborCost       `json:"labor"`
	TotalCost       float64                 `json:"total_cost"`
}

// MaintenanceService business logic สำหรับซ่อมบำรุง
type MaintenanceService struct {
	mongoRepo     *mongorepo.MaintenanceRepo
	pgQuery       *pgquery.MaintenanceQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

// NewMaintenanceService สร้าง MaintenanceService ใหม่
func NewMaintenanceService(
	mongoRepo *mongorepo.MaintenanceRepo,
	pgQuery *pgquery.MaintenanceQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *MaintenanceService {
	return &MaintenanceService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// ListWorkOrders ดึงรายการใบสั่งซ่อม
func (s *MaintenanceService) ListWorkOrders(ctx context.Context, shopID, status, vehicleID string, page, limit int) ([]pgquery.WorkOrderRow, int, error) {
	return s.pgQuery.ListWorkOrders(ctx, shopID, status, vehicleID, page, limit)
}

// GetWorkOrder ดึงรายละเอียดใบสั่งซ่อม
func (s *MaintenanceService) GetWorkOrder(ctx context.Context, shopID, id string) (*pgquery.WorkOrderRow, error) {
	return s.pgQuery.GetWorkOrderByID(ctx, shopID, id)
}

// GetSchedule alias ของ GetDue (ดึงรายการใกล้ถึงกำหนด)
func (s *MaintenanceService) GetSchedule(ctx context.Context, shopID string) ([]pgquery.MaintenanceDueRow, error) {
	return s.pgQuery.GetDueSchedule(ctx, shopID)
}

// GetDue ดึงรายการที่ใกล้ถึงกำหนดซ่อม
func (s *MaintenanceService) GetDue(ctx context.Context, shopID string) ([]pgquery.MaintenanceDueRow, error) {
	return s.pgQuery.GetDueSchedule(ctx, shopID)
}

// CreateWorkOrder สร้างใบสั่งซ่อมใหม่
func (s *MaintenanceService) CreateWorkOrder(ctx context.Context, shopID, userID string, req CreateWorkOrderRequest) (*models.WorkOrder, error) {
	if req.Priority == "" {
		req.Priority = "medium"
	}

	woNo := fmt.Sprintf("WO-%s-%06d", time.Now().Format("20060102"), time.Now().UnixMilli()%1000000)

	var partsCost float64
	for _, p := range req.Parts {
		partsCost += p.Total
	}
	var laborCost float64
	if req.Labor != nil {
		laborCost = req.Labor.Total
	}

	wo := &models.WorkOrder{
		ID:              primitive.NewObjectID(),
		ShopID:          shopID,
		WONo:            woNo,
		VehicleID:       req.VehicleID,
		Type:            req.Type,
		Priority:        req.Priority,
		Status:          "pending_approval",
		ReportedBy:      userID,
		ReportedType:    "admin",
		Description:     req.Description,
		Symptoms:        req.Symptoms,
		MileageAtReport: req.MileageAtReport,
		ServiceProvider: req.ServiceProvider,
		Parts:           req.Parts,
		Labor:           req.Labor,
		TotalCost:       partsCost + laborCost,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	// repo ชื่อ InsertWorkOrder
	if err := s.mongoRepo.InsertWorkOrder(ctx, wo); err != nil {
		return nil, fmt.Errorf("insert work order: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "maintenance.work_order_created", "work_order", wo.ID.Hex(), "create", userID, "admin", wo)

	s.kafkaProducer.Produce("fleet.maintenance", database.KafkaEvent{
		Type:      "maintenance.work_order_created",
		ShopID:    shopID,
		EntityID:  wo.ID.Hex(),
		Payload:   wo,
		Timestamp: time.Now(),
	})

	return wo, nil
}

// UpdateWorkOrder อัปเดตใบสั่งซ่อม
func (s *MaintenanceService) UpdateWorkOrder(ctx context.Context, shopID, userID, id string, req UpdateWorkOrderRequest) error {
	update := bson.M{}
	if req.Status != "" {
		update["status"] = req.Status
	}
	if req.Description != "" {
		update["description"] = req.Description
	}
	if req.ServiceProvider != nil {
		update["service_provider"] = req.ServiceProvider
	}
	if len(req.Parts) > 0 {
		update["parts"] = req.Parts
	}
	if req.Labor != nil {
		update["labor"] = req.Labor
	}
	if req.TotalCost > 0 {
		update["total_cost"] = req.TotalCost
	}

	// repo ชื่อ UpdateWorkOrder
	if err := s.mongoRepo.UpdateWorkOrder(ctx, id, update); err != nil {
		return fmt.Errorf("update work order: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "maintenance.work_order_updated", "work_order", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.maintenance", database.KafkaEvent{
		Type:      "maintenance.work_order_updated",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// Approve อนุมัติใบสั่งซ่อม
func (s *MaintenanceService) Approve(ctx context.Context, shopID, userID, id string) error {
	now := time.Now()
	update := bson.M{
		"status":      "approved",
		"approved_by": userID,
		"approved_at": now,
	}

	if err := s.mongoRepo.UpdateWorkOrder(ctx, id, update); err != nil {
		return fmt.Errorf("approve work order: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "maintenance.work_order_approved", "work_order", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.maintenance", database.KafkaEvent{
		Type:      "maintenance.work_order_approved",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// Complete ปิดงานใบสั่งซ่อม
func (s *MaintenanceService) Complete(ctx context.Context, shopID, userID, id string) error {
	now := time.Now()
	update := bson.M{
		"status":       "completed",
		"completed_at": now,
	}

	if err := s.mongoRepo.UpdateWorkOrder(ctx, id, update); err != nil {
		return fmt.Errorf("complete work order: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "maintenance.work_order_completed", "work_order", id, "update", userID, "admin", update)

	s.kafkaProducer.Produce("fleet.maintenance", database.KafkaEvent{
		Type:      "maintenance.work_order_completed",
		ShopID:    shopID,
		EntityID:  id,
		Payload:   update,
		Timestamp: time.Now(),
	})

	return nil
}

// GetMaintenanceCost ดึงต้นทุนซ่อมสะสมต่อคัน (คำนวณจาก work orders ใน PostgreSQL)
func (s *MaintenanceService) GetMaintenanceCost(ctx context.Context, shopID, vehicleID string) (map[string]interface{}, error) {
	orders, _, err := s.pgQuery.ListWorkOrders(ctx, shopID, "completed", vehicleID, 1, 1000)
	if err != nil {
		return nil, fmt.Errorf("list work orders: %w", err)
	}

	var totalCost float64
	for _, o := range orders {
		if o.TotalCost != nil {
			totalCost += *o.TotalCost
		}
	}

	return map[string]interface{}{
		"vehicle_id":    vehicleID,
		"total_cost":    totalCost,
		"order_count":   len(orders),
	}, nil
}

// ListParts ดึงรายการสต๊อกอะไหล่ (ดึงจาก PostgreSQL fleet_work_orders parts aggregate)
func (s *MaintenanceService) ListParts(ctx context.Context, shopID string, page, limit int) ([]map[string]interface{}, int, error) {
	// placeholder — ใช้ work order parts จาก MongoDB แทนเมื่อ parts inventory table พร้อม
	return []map[string]interface{}{}, 0, nil
}
