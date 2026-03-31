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

// MaintenanceRepo MongoDB repository สำหรับใบสั่งซ่อม
type MaintenanceRepo struct {
	mongo *database.MongoDB
}

// NewMaintenanceRepo สร้าง MaintenanceRepo ใหม่
func NewMaintenanceRepo(mongo *database.MongoDB) *MaintenanceRepo {
	return &MaintenanceRepo{mongo: mongo}
}

func (r *MaintenanceRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_maintenance_work_orders")
}

// InsertWorkOrder เพิ่มใบสั่งซ่อมใหม่ลง MongoDB
func (r *MaintenanceRepo) InsertWorkOrder(ctx context.Context, wo *models.WorkOrder) error {
	if wo.ID.IsZero() {
		wo.ID = primitive.NewObjectID()
	}
	now := time.Now()
	wo.CreatedAt = now
	wo.UpdatedAt = now

	_, err := r.collection().InsertOne(ctx, wo)
	return err
}

// UpdateWorkOrder อัปเดตข้อมูลใบสั่งซ่อม
func (r *MaintenanceRepo) UpdateWorkOrder(ctx context.Context, id string, update bson.M) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	if _, hasSet := update["$set"]; !hasSet {
		update = bson.M{"$set": update}
	}

	if setMap, ok := update["$set"].(bson.M); ok {
		setMap["updated_at"] = time.Now()
	}

	filter := bson.M{"_id": oid}
	_, err = r.collection().UpdateOne(ctx, filter, update)
	return err
}

// FindWorkOrderByID ค้นหาใบสั่งซ่อมด้วย ID
func (r *MaintenanceRepo) FindWorkOrderByID(ctx context.Context, shopID, id string) (*models.WorkOrder, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	filter := bson.M{
		"_id":     oid,
		"shop_id": shopID,
	}

	var wo models.WorkOrder
	err = r.collection().FindOne(ctx, filter).Decode(&wo)
	if err != nil {
		return nil, err
	}
	return &wo, nil
}

// FindWorkOrdersByShop ค้นหาใบสั่งซ่อมทั้งหมดของร้าน (รองรับ filter เพิ่มเติม)
func (r *MaintenanceRepo) FindWorkOrdersByShop(ctx context.Context, shopID string, filter bson.M) ([]*models.WorkOrder, error) {
	if filter == nil {
		filter = bson.M{}
	}
	filter["shop_id"] = shopID

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var workOrders []*models.WorkOrder
	if err := cursor.All(ctx, &workOrders); err != nil {
		return nil, err
	}
	return workOrders, nil
}
