package mongo

import (
	"context"
	"time"

	"bc-fleet/internal/database"
	"bc-fleet/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// ExpenseRepo MongoDB repository สำหรับค่าใช้จ่าย
type ExpenseRepo struct {
	mongo *database.MongoDB
}

// NewExpenseRepo สร้าง ExpenseRepo ใหม่
func NewExpenseRepo(mongo *database.MongoDB) *ExpenseRepo {
	return &ExpenseRepo{mongo: mongo}
}

func (r *ExpenseRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_expenses")
}

// Insert เพิ่มค่าใช้จ่ายใหม่ลง MongoDB
func (r *ExpenseRepo) Insert(ctx context.Context, expense *models.Expense) error {
	if expense.ID.IsZero() {
		expense.ID = primitive.NewObjectID()
	}
	now := time.Now()
	expense.CreatedAt = now
	if expense.RecordedAt.IsZero() {
		expense.RecordedAt = now
	}

	_, err := r.collection().InsertOne(ctx, expense)
	return err
}

// FindByShop ค้นหาค่าใช้จ่ายทั้งหมดของร้าน (รองรับ filter เพิ่มเติม)
func (r *ExpenseRepo) FindByShop(ctx context.Context, shopID string, filter bson.M) ([]*models.Expense, error) {
	if filter == nil {
		filter = bson.M{}
	}
	filter["shop_id"] = shopID

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var expenses []*models.Expense
	if err := cursor.All(ctx, &expenses); err != nil {
		return nil, err
	}
	return expenses, nil
}

// FindByVehicle ค้นหาค่าใช้จ่ายตามรหัสรถ
func (r *ExpenseRepo) FindByVehicle(ctx context.Context, shopID, vehicleID string) ([]*models.Expense, error) {
	filter := bson.M{
		"shop_id":    shopID,
		"vehicle_id": vehicleID,
	}

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var expenses []*models.Expense
	if err := cursor.All(ctx, &expenses); err != nil {
		return nil, err
	}
	return expenses, nil
}

// FindByTrip ค้นหาค่าใช้จ่ายตามรหัสเที่ยววิ่ง
func (r *ExpenseRepo) FindByTrip(ctx context.Context, shopID, tripID string) ([]*models.Expense, error) {
	filter := bson.M{
		"shop_id": shopID,
		"trip_id": tripID,
	}

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var expenses []*models.Expense
	if err := cursor.All(ctx, &expenses); err != nil {
		return nil, err
	}
	return expenses, nil
}
