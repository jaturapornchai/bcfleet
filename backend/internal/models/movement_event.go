package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// MovementEvent เหตุการณ์ที่ตรวจพบจาก AI วิเคราะห์ GPS movement
type MovementEvent struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID     string             `bson:"shop_id" json:"shop_id"`
	VehicleID  string             `bson:"vehicle_id" json:"vehicle_id"`
	Plate      string             `bson:"plate" json:"plate"`
	EventType  string             `bson:"event_type" json:"event_type"`   // movement.started, movement.stopped, speeding, geofence.exit, route.deviation, idle.with_trip, erratic.driving, night.movement
	Severity   string             `bson:"severity" json:"severity"`       // info, warning, critical
	Analysis   string             `bson:"analysis" json:"analysis"`       // AI สรุปเป็นภาษาไทย
	Data       *MovementData      `bson:"data" json:"data"`
	AlertCreated bool             `bson:"alert_created" json:"alert_created"`
	AnalyzedBy string             `bson:"analyzed_by" json:"analyzed_by"` // HiClaw worker name
	CreatedAt  time.Time          `bson:"created_at" json:"created_at"`
}

// MovementData ข้อมูล GPS ที่เกี่ยวข้องกับ event
type MovementData struct {
	Lat        float64  `bson:"lat" json:"lat"`
	Lng        float64  `bson:"lng" json:"lng"`
	PrevLat    float64  `bson:"prev_lat" json:"prev_lat"`
	PrevLng    float64  `bson:"prev_lng" json:"prev_lng"`
	SpeedKmh   float64  `bson:"speed_kmh" json:"speed_kmh"`
	DistanceM  float64  `bson:"distance_m" json:"distance_m"`
	TripID     string   `bson:"trip_id,omitempty" json:"trip_id,omitempty"`
	DriverID   string   `bson:"driver_id,omitempty" json:"driver_id,omitempty"`
}
