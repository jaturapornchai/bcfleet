package service

import (
	"context"
	"fmt"

	"sml-fleet/internal/database"
	"sml-fleet/internal/eventlog"
	"sml-fleet/internal/models"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"

	"go.mongodb.org/mongo-driver/bson"
)

// CustomerService business logic สำหรับลูกค้า
type CustomerService struct {
	mongoRepo     *mongorepo.CustomerRepo
	pgQuery       *pgquery.CustomerQuery
	eventLogger   *eventlog.Logger
	kafkaProducer *database.KafkaProducer
}

func NewCustomerService(
	mongoRepo *mongorepo.CustomerRepo,
	pgQuery *pgquery.CustomerQuery,
	eventLogger *eventlog.Logger,
	kafkaProducer *database.KafkaProducer,
) *CustomerService {
	return &CustomerService{
		mongoRepo:     mongoRepo,
		pgQuery:       pgQuery,
		eventLogger:   eventLogger,
		kafkaProducer: kafkaProducer,
	}
}

// CreateCustomerRequest คำขอสร้างลูกค้า
type CreateCustomerRequest struct {
	Name         string                  `json:"name" binding:"required"`
	CustomerType string                  `json:"customer_type"` // individual, company
	Phone        string                  `json:"phone"`
	LineUserID   string                  `json:"line_user_id"`
	Email        string                  `json:"email"`
	Company      string                  `json:"company"`
	TaxID        string                  `json:"tax_id"`
	Address      string                  `json:"address"`
	Contacts     []models.CustomerContact `json:"contacts"`
	CreditTerms  *models.CreditTerms     `json:"credit_terms"`
	Notes        string                  `json:"notes"`
	Tags         []string                `json:"tags"`
}

// Create สร้างลูกค้าใหม่ (เขียน MongoDB → Kafka → PostgreSQL)
func (s *CustomerService) Create(ctx context.Context, shopID, userID string, req CreateCustomerRequest) (*models.Customer, error) {
	customerNo, err := s.mongoRepo.GenerateCustomerNo(ctx, shopID)
	if err != nil {
		return nil, fmt.Errorf("generate customer no: %w", err)
	}

	customerType := req.CustomerType
	if customerType == "" {
		customerType = "individual"
	}

	customer := &models.Customer{
		ShopID:       shopID,
		CustomerNo:   customerNo,
		Name:         req.Name,
		CustomerType: customerType,
		Phone:        req.Phone,
		LineUserID:   req.LineUserID,
		Email:        req.Email,
		Company:      req.Company,
		TaxID:        req.TaxID,
		Address:      req.Address,
		Contacts:     req.Contacts,
		CreditTerms:  req.CreditTerms,
		Notes:        req.Notes,
		Tags:         req.Tags,
		Status:       "active",
		CreatedBy:    userID,
	}

	// 1. เขียน MongoDB (Source of Truth)
	if err := s.mongoRepo.Insert(ctx, customer); err != nil {
		return nil, fmt.Errorf("insert customer: %w", err)
	}

	// 2. Event log
	s.eventLogger.Log(ctx, shopID, "customer.created", "customer", customer.ID.Hex(), "create", userID, "admin", customer)

	// 3. Kafka → PostgreSQL sync
	s.kafkaProducer.Produce("fleet.customers", database.KafkaEvent{
		Type:     "customer.created",
		ShopID:   shopID,
		EntityID: customer.ID.Hex(),
		Payload:  customer,
	})

	return customer, nil
}

// Update อัปเดตลูกค้า
func (s *CustomerService) Update(ctx context.Context, shopID, userID, id string, updates map[string]interface{}) error {
	bsonUpdates := bson.M{}
	for k, v := range updates {
		if v != nil && v != "" {
			bsonUpdates[k] = v
		}
	}

	if err := s.mongoRepo.Update(ctx, shopID, id, bsonUpdates); err != nil {
		return fmt.Errorf("update customer: %w", err)
	}

	s.eventLogger.Log(ctx, shopID, "customer.updated", "customer", id, "update", userID, "admin", updates)

	s.kafkaProducer.Produce("fleet.customers", database.KafkaEvent{
		Type:     "customer.updated",
		ShopID:   shopID,
		EntityID: id,
		Payload:  updates,
	})

	return nil
}

// GetByID ดึงลูกค้า by ID (อ่าน PostgreSQL)
func (s *CustomerService) GetByID(ctx context.Context, shopID, id string) (*pgquery.CustomerRow, error) {
	return s.pgQuery.GetByID(ctx, shopID, id)
}

// List ดึงรายการลูกค้า (อ่าน PostgreSQL)
func (s *CustomerService) List(ctx context.Context, shopID, status string, page, limit int) ([]pgquery.CustomerRow, int, error) {
	return s.pgQuery.List(ctx, shopID, status, page, limit)
}

// Search ค้นหาลูกค้า (อ่าน PostgreSQL)
func (s *CustomerService) Search(ctx context.Context, shopID, keyword string, limit int) ([]pgquery.CustomerRow, error) {
	return s.pgQuery.Search(ctx, shopID, keyword, limit)
}

// GetByLineUserID ดึงลูกค้าจาก LINE User ID
func (s *CustomerService) GetByLineUserID(ctx context.Context, shopID, lineUserID string) (*pgquery.CustomerRow, error) {
	return s.pgQuery.GetByLineUserID(ctx, shopID, lineUserID)
}
