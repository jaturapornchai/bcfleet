package eventlog

import (
	"context"
	"log"
	"time"

	"bc-fleet/internal/database"
	"bc-fleet/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Logger บันทึก event log ลง MongoDB
type Logger struct {
	mongo *database.MongoDB
}

// NewLogger สร้าง event logger
func NewLogger(mongo *database.MongoDB) *Logger {
	return &Logger{mongo: mongo}
}

// Log บันทึก event
func (l *Logger) Log(ctx context.Context, shopID, eventType, entity, entityID, action, userID, userType string, payload interface{}) {
	var payloadBSON bson.M
	data, _ := bson.Marshal(payload)
	bson.Unmarshal(data, &payloadBSON)

	eventLog := models.EventLog{
		ID:        primitive.NewObjectID(),
		ShopID:    shopID,
		EventType: eventType,
		Entity:    entity,
		EntityID:  entityID,
		Action:    action,
		Payload:   payloadBSON,
		UserID:    userID,
		UserType:  userType,
		CreatedAt: time.Now(),
	}

	_, err := l.mongo.Collection("fleet_event_logs").InsertOne(ctx, eventLog)
	if err != nil {
		log.Printf("Event log error: %v", err)
	}
}

// LogWithDiff บันทึก event พร้อม diff (สำหรับ update)
func (l *Logger) LogWithDiff(ctx context.Context, shopID, eventType, entity, entityID, action, userID, userType string, payload, diff interface{}) {
	var payloadBSON, diffBSON bson.M
	data, _ := bson.Marshal(payload)
	bson.Unmarshal(data, &payloadBSON)
	data2, _ := bson.Marshal(diff)
	bson.Unmarshal(data2, &diffBSON)

	eventLog := models.EventLog{
		ID:        primitive.NewObjectID(),
		ShopID:    shopID,
		EventType: eventType,
		Entity:    entity,
		EntityID:  entityID,
		Action:    action,
		Payload:   payloadBSON,
		Diff:      diffBSON,
		UserID:    userID,
		UserType:  userType,
		CreatedAt: time.Now(),
	}

	_, err := l.mongo.Collection("fleet_event_logs").InsertOne(ctx, eventLog)
	if err != nil {
		log.Printf("Event log error: %v", err)
	}
}
