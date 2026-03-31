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

// PartnerRepo MongoDB repository สำหรับรถร่วม
type PartnerRepo struct {
	mongo *database.MongoDB
}

// NewPartnerRepo สร้าง PartnerRepo ใหม่
func NewPartnerRepo(mongo *database.MongoDB) *PartnerRepo {
	return &PartnerRepo{mongo: mongo}
}

func (r *PartnerRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_partner_vehicles")
}

// Insert เพิ่มรถร่วมใหม่ลง MongoDB
func (r *PartnerRepo) Insert(ctx context.Context, partner *models.PartnerVehicle) error {
	if partner.ID.IsZero() {
		partner.ID = primitive.NewObjectID()
	}
	now := time.Now()
	partner.CreatedAt = now
	partner.UpdatedAt = now

	_, err := r.collection().InsertOne(ctx, partner)
	return err
}

// Update อัปเดตข้อมูลรถร่วม
func (r *PartnerRepo) Update(ctx context.Context, id string, update bson.M) error {
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

// FindByID ค้นหารถร่วมด้วย ID
func (r *PartnerRepo) FindByID(ctx context.Context, shopID, id string) (*models.PartnerVehicle, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	filter := bson.M{
		"_id":     oid,
		"shop_id": shopID,
	}

	var partner models.PartnerVehicle
	err = r.collection().FindOne(ctx, filter).Decode(&partner)
	if err != nil {
		return nil, err
	}
	return &partner, nil
}

// FindByShop ค้นหารถร่วมทั้งหมดของร้าน (รองรับ filter เพิ่มเติม)
func (r *PartnerRepo) FindByShop(ctx context.Context, shopID string, filter bson.M) ([]*models.PartnerVehicle, error) {
	if filter == nil {
		filter = bson.M{}
	}
	filter["shop_id"] = shopID

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var partners []*models.PartnerVehicle
	if err := cursor.All(ctx, &partners); err != nil {
		return nil, err
	}
	return partners, nil
}

// FindAvailable ค้นหารถร่วมที่ว่างตาม zone และ vehicleType
func (r *PartnerRepo) FindAvailable(ctx context.Context, shopID, zone, vehicleType string) ([]*models.PartnerVehicle, error) {
	filter := bson.M{
		"shop_id": shopID,
		"status":  "active",
	}

	// กรอง zone ถ้าระบุ
	if zone != "" {
		filter["coverage_zones"] = bson.M{"$in": bson.A{zone}}
	}

	// กรองประเภทรถถ้าระบุ
	if vehicleType != "" {
		filter["vehicle.type"] = vehicleType
	}

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var partners []*models.PartnerVehicle
	if err := cursor.All(ctx, &partners); err != nil {
		return nil, err
	}
	return partners, nil
}
