package mongo

import (
	"context"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// VehicleRepo MongoDB repository สำหรับรถขนส่ง
type VehicleRepo struct {
	mongo *database.MongoDB
}

// NewVehicleRepo สร้าง VehicleRepo ใหม่
func NewVehicleRepo(mongo *database.MongoDB) *VehicleRepo {
	return &VehicleRepo{mongo: mongo}
}

func (r *VehicleRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_vehicles")
}

// Insert เพิ่มรถใหม่ลง MongoDB
func (r *VehicleRepo) Insert(ctx context.Context, vehicle *models.Vehicle) error {
	if vehicle.ID.IsZero() {
		vehicle.ID = primitive.NewObjectID()
	}
	now := time.Now()
	vehicle.CreatedAt = now
	vehicle.UpdatedAt = now

	_, err := r.collection().InsertOne(ctx, vehicle)
	return err
}

// Update อัปเดตข้อมูลรถ
func (r *VehicleRepo) Update(ctx context.Context, id string, update bson.M) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	// ตรวจสอบว่า update มี $set อยู่แล้วหรือไม่
	if _, hasSet := update["$set"]; !hasSet {
		update = bson.M{"$set": update}
	}

	// อัปเดต updated_at เสมอ
	if setMap, ok := update["$set"].(bson.M); ok {
		setMap["updated_at"] = time.Now()
	}

	filter := bson.M{"_id": oid, "deleted_at": bson.M{"$eq": nil}}
	_, err = r.collection().UpdateOne(ctx, filter, update)
	return err
}

// SoftDelete ลบแบบ soft (เซต deleted_at)
func (r *VehicleRepo) SoftDelete(ctx context.Context, shopID, id string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	now := time.Now()
	filter := bson.M{"_id": oid, "shop_id": shopID, "deleted_at": bson.M{"$eq": nil}}
	update := bson.M{"$set": bson.M{
		"deleted_at": now,
		"updated_at": now,
	}}

	_, err = r.collection().UpdateOne(ctx, filter, update)
	return err
}

// FindByID ค้นหารถด้วย ID
func (r *VehicleRepo) FindByID(ctx context.Context, shopID, id string) (*models.Vehicle, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	filter := bson.M{
		"_id":        oid,
		"shop_id":    shopID,
		"deleted_at": bson.M{"$eq": nil},
	}

	var vehicle models.Vehicle
	err = r.collection().FindOne(ctx, filter).Decode(&vehicle)
	if err != nil {
		return nil, err
	}
	return &vehicle, nil
}

// FindByShop ค้นหารถทั้งหมดของร้าน (รองรับ filter เพิ่มเติม)
func (r *VehicleRepo) FindByShop(ctx context.Context, shopID string, filter bson.M) ([]*models.Vehicle, error) {
	if filter == nil {
		filter = bson.M{}
	}
	filter["shop_id"] = shopID
	filter["deleted_at"] = bson.M{"$eq": nil}

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var vehicles []*models.Vehicle
	if err := cursor.All(ctx, &vehicles); err != nil {
		return nil, err
	}
	return vehicles, nil
}
