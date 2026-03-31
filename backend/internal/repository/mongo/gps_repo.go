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

// GPSRepo MongoDB repository สำหรับ GPS logs (high frequency)
type GPSRepo struct {
	mongo *database.MongoDB
}

// NewGPSRepo สร้าง GPSRepo ใหม่
func NewGPSRepo(mongo *database.MongoDB) *GPSRepo {
	return &GPSRepo{mongo: mongo}
}

func (r *GPSRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_gps_logs")
}

// InsertLog บันทึก GPS location ใหม่
func (r *GPSRepo) InsertLog(ctx context.Context, log *models.GPSLog) error {
	if log.ID.IsZero() {
		log.ID = primitive.NewObjectID()
	}
	now := time.Now()
	log.CreatedAt = now
	if log.Timestamp.IsZero() {
		log.Timestamp = now
	}

	_, err := r.collection().InsertOne(ctx, log)
	return err
}

// FindLatestByVehicle ค้นหาตำแหน่งล่าสุดของรถ
func (r *GPSRepo) FindLatestByVehicle(ctx context.Context, shopID, vehicleID string) (*models.GPSLog, error) {
	filter := bson.M{
		"shop_id":    shopID,
		"vehicle_id": vehicleID,
	}

	opts := options.FindOne().SetSort(bson.D{{Key: "timestamp", Value: -1}})

	var gpsLog models.GPSLog
	err := r.collection().FindOne(ctx, filter, opts).Decode(&gpsLog)
	if err != nil {
		return nil, err
	}
	return &gpsLog, nil
}

// FindTrail ค้นหาเส้นทางย้อนหลังของรถในช่วงเวลาที่กำหนด
func (r *GPSRepo) FindTrail(ctx context.Context, shopID, vehicleID string, from, to time.Time) ([]*models.GPSLog, error) {
	filter := bson.M{
		"shop_id":    shopID,
		"vehicle_id": vehicleID,
		"timestamp": bson.M{
			"$gte": from,
			"$lte": to,
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "timestamp", Value: 1}})

	cursor, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var logs []*models.GPSLog
	if err := cursor.All(ctx, &logs); err != nil {
		return nil, err
	}
	return logs, nil
}
