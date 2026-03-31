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

// TripRepo MongoDB repository สำหรับเที่ยววิ่ง
type TripRepo struct {
	mongo *database.MongoDB
}

// NewTripRepo สร้าง TripRepo ใหม่
func NewTripRepo(mongo *database.MongoDB) *TripRepo {
	return &TripRepo{mongo: mongo}
}

func (r *TripRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_trips")
}

// Insert เพิ่มเที่ยววิ่งใหม่ลง MongoDB
func (r *TripRepo) Insert(ctx context.Context, trip *models.Trip) error {
	if trip.ID.IsZero() {
		trip.ID = primitive.NewObjectID()
	}
	now := time.Now()
	trip.CreatedAt = now
	trip.UpdatedAt = now

	_, err := r.collection().InsertOne(ctx, trip)
	return err
}

// Update อัปเดตข้อมูลเที่ยววิ่ง
func (r *TripRepo) Update(ctx context.Context, id string, update bson.M) error {
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

// UpdateStatus เปลี่ยนสถานะเที่ยววิ่ง
func (r *TripRepo) UpdateStatus(ctx context.Context, shopID, id, status string) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	now := time.Now()
	filter := bson.M{"_id": oid, "shop_id": shopID}
	update := bson.M{"$set": bson.M{
		"status":     status,
		"updated_at": now,
	}}

	_, err = r.collection().UpdateOne(ctx, filter, update)
	return err
}

// FindByID ค้นหาเที่ยววิ่งด้วย ID
func (r *TripRepo) FindByID(ctx context.Context, shopID, id string) (*models.Trip, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	filter := bson.M{
		"_id":     oid,
		"shop_id": shopID,
	}

	var trip models.Trip
	err = r.collection().FindOne(ctx, filter).Decode(&trip)
	if err != nil {
		return nil, err
	}
	return &trip, nil
}

// FindByShop ค้นหาเที่ยววิ่งทั้งหมดของร้าน (รองรับ filter เพิ่มเติม)
func (r *TripRepo) FindByShop(ctx context.Context, shopID string, filter bson.M) ([]*models.Trip, error) {
	if filter == nil {
		filter = bson.M{}
	}
	filter["shop_id"] = shopID

	cursor, err := r.collection().Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var trips []*models.Trip
	if err := cursor.All(ctx, &trips); err != nil {
		return nil, err
	}
	return trips, nil
}
