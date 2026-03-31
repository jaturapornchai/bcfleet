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

// DriverRepo MongoDB repository สำหรับคนขับรถ
type DriverRepo struct {
	mongo *database.MongoDB
}

// NewDriverRepo สร้าง DriverRepo ใหม่
func NewDriverRepo(mongo *database.MongoDB) *DriverRepo {
	return &DriverRepo{mongo: mongo}
}

func (r *DriverRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_drivers")
}

// Insert เพิ่มคนขับใหม่ลง MongoDB
func (r *DriverRepo) Insert(ctx context.Context, driver *models.Driver) error {
	if driver.ID.IsZero() {
		driver.ID = primitive.NewObjectID()
	}
	now := time.Now()
	driver.CreatedAt = now
	driver.UpdatedAt = now

	_, err := r.collection().InsertOne(ctx, driver)
	return err
}

// Update อัปเดตข้อมูลคนขับ
func (r *DriverRepo) Update(ctx context.Context, id string, update bson.M) error {
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

	filter := bson.M{"_id": oid, "deleted_at": bson.M{"$eq": nil}}
	_, err = r.collection().UpdateOne(ctx, filter, update)
	return err
}

// SoftDelete ลบแบบ soft (เซต deleted_at)
func (r *DriverRepo) SoftDelete(ctx context.Context, shopID, id string) error {
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

// FindByID ค้นหาคนขับด้วย ID
func (r *DriverRepo) FindByID(ctx context.Context, shopID, id string) (*models.Driver, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	filter := bson.M{
		"_id":        oid,
		"shop_id":    shopID,
		"deleted_at": bson.M{"$eq": nil},
	}

	var driver models.Driver
	err = r.collection().FindOne(ctx, filter).Decode(&driver)
	if err != nil {
		return nil, err
	}
	return &driver, nil
}

// FindByShop ค้นหาคนขับทั้งหมดของร้าน (รองรับ filter เพิ่มเติม)
func (r *DriverRepo) FindByShop(ctx context.Context, shopID string, filter bson.M) ([]*models.Driver, error) {
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

	var drivers []*models.Driver
	if err := cursor.All(ctx, &drivers); err != nil {
		return nil, err
	}
	return drivers, nil
}
