package mongo

import (
	"context"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MovementRepo MongoDB repository สำหรับ movement events
type MovementRepo struct {
	mongo *database.MongoDB
}

// NewMovementRepo สร้าง MovementRepo ใหม่
func NewMovementRepo(mongo *database.MongoDB) *MovementRepo {
	return &MovementRepo{mongo: mongo}
}

func (r *MovementRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_movement_events")
}

// Insert บันทึก movement event
func (r *MovementRepo) Insert(ctx context.Context, event *models.MovementEvent) error {
	if event.ID.IsZero() {
		event.ID = primitive.NewObjectID()
	}
	if event.CreatedAt.IsZero() {
		event.CreatedAt = time.Now()
	}
	_, err := r.collection().InsertOne(ctx, event)
	return err
}

// InsertMany บันทึกหลาย events พร้อมกัน
func (r *MovementRepo) InsertMany(ctx context.Context, events []*models.MovementEvent) error {
	if len(events) == 0 {
		return nil
	}
	docs := make([]interface{}, len(events))
	now := time.Now()
	for i, ev := range events {
		if ev.ID.IsZero() {
			ev.ID = primitive.NewObjectID()
		}
		if ev.CreatedAt.IsZero() {
			ev.CreatedAt = now
		}
		docs[i] = ev
	}
	_, err := r.collection().InsertMany(ctx, docs)
	return err
}

// FindByVehicle ดึง movement events ของรถคันหนึ่ง
func (r *MovementRepo) FindByVehicle(ctx context.Context, shopID, vehicleID string, limit int) ([]*models.MovementEvent, error) {
	filter := bson.M{
		"shop_id":    shopID,
		"vehicle_id": vehicleID,
	}
	opts := options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetLimit(int64(limit))

	cursor, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var events []*models.MovementEvent
	if err := cursor.All(ctx, &events); err != nil {
		return nil, err
	}
	return events, nil
}

// FindRecent ดึง movement events ล่าสุดของร้าน
func (r *MovementRepo) FindRecent(ctx context.Context, shopID string, limit int) ([]*models.MovementEvent, error) {
	filter := bson.M{"shop_id": shopID}
	opts := options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetLimit(int64(limit))

	cursor, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var events []*models.MovementEvent
	if err := cursor.All(ctx, &events); err != nil {
		return nil, err
	}
	return events, nil
}
