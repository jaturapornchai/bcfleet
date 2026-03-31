package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EventLog บันทึก event ทุกรายการ (ไม่ลบ ไม่มี TTL)
type EventLog struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ShopID    string             `bson:"shop_id" json:"shop_id"`
	EventType string             `bson:"event_type" json:"event_type"` // "vehicle.created", "trip.updated"
	Entity    string             `bson:"entity" json:"entity"`         // "vehicle", "driver", "trip"
	EntityID  string             `bson:"entity_id" json:"entity_id"`
	Action    string             `bson:"action" json:"action"` // "create", "update", "delete"
	Payload   bson.M             `bson:"payload" json:"payload"`
	Diff      bson.M             `bson:"diff,omitempty" json:"diff"`
	UserID    string             `bson:"user_id" json:"user_id"`
	UserType  string             `bson:"user_type" json:"user_type"` // "admin", "driver", "system", "ai_agent", "ucp_agent"
	IP        string             `bson:"ip,omitempty" json:"ip"`
	Metadata  *EventMetadata     `bson:"metadata,omitempty" json:"metadata"`
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}

// EventMetadata ข้อมูลเพิ่มเติมของ event
type EventMetadata struct {
	Source    string `bson:"source" json:"source"` // "driver_app", "boss_app", "web_dashboard", "line_bot", "mcp", "ucp"
	UserAgent string `bson:"user_agent,omitempty" json:"user_agent"`
}
