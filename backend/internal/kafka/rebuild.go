package kafka

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"sml-fleet/internal/database"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// RebuildService rebuild PostgreSQL จาก MongoDB
type RebuildService struct {
	mongo *database.MongoDB
	pgDB  *database.PostgresDB
	sync  *FleetSyncConsumer
}

// NewRebuildService สร้าง RebuildService
func NewRebuildService(mongo *database.MongoDB, pgDB *database.PostgresDB) *RebuildService {
	return &RebuildService{
		mongo: mongo,
		pgDB:  pgDB,
		sync:  NewFleetSyncConsumer("", "", pgDB),
	}
}

// RebuildAll DROP + CREATE tables แล้ว INSERT ข้อมูลจาก MongoDB ทั้งหมด
func (r *RebuildService) RebuildAll(ctx context.Context) error {
	log.Println("[Rebuild] เริ่ม rebuild PostgreSQL จาก MongoDB...")
	start := time.Now()

	steps := []struct {
		name string
		fn   func(context.Context) error
	}{
		{"vehicles", r.rebuildVehicles},
		{"drivers", r.rebuildDrivers},
		{"trips", r.rebuildTrips},
		{"work_orders", r.rebuildWorkOrders},
		{"partners", r.rebuildPartners},
		{"expenses", r.rebuildExpenses},
	}

	for _, step := range steps {
		log.Printf("[Rebuild] กำลัง rebuild %s...", step.name)
		if err := step.fn(ctx); err != nil {
			return fmt.Errorf("rebuild %s ล้มเหลว: %w", step.name, err)
		}
		log.Printf("[Rebuild] rebuild %s เสร็จแล้ว", step.name)
	}

	log.Printf("[Rebuild] เสร็จสมบูรณ์ ใช้เวลา %s", time.Since(start))
	return nil
}

// dropAndRecreate DROP table แล้ว CREATE ใหม่ (รองรับ rebuild)
// หมายเหตุ: ไม่ใช้ DROP จริงในโปรดักชัน — ใช้ TRUNCATE แทน (เร็วกว่า ปลอดภัยกว่า)
func (r *RebuildService) truncateTable(ctx context.Context, tableName string) error {
	_, err := r.pgDB.Pool().Exec(ctx,
		fmt.Sprintf("TRUNCATE TABLE %s RESTART IDENTITY CASCADE", tableName),
	)
	return err
}

// mongoToPayload แปลง bson.M เป็น interface{} ผ่าน JSON
func mongoToPayload(doc bson.M) (interface{}, error) {
	// แปลง ObjectID เป็น string
	if id, ok := doc["_id"]; ok {
		doc["id"] = fmt.Sprintf("%v", id)
		delete(doc, "_id")
	}

	b, err := json.Marshal(doc)
	if err != nil {
		return nil, err
	}

	var out interface{}
	if err := json.Unmarshal(b, &out); err != nil {
		return nil, err
	}
	return out, nil
}

// rebuildVehicles rebuild fleet_vehicles จาก MongoDB fleet_vehicles collection
func (r *RebuildService) rebuildVehicles(ctx context.Context) error {
	if err := r.truncateTable(ctx, "fleet_vehicles"); err != nil {
		return fmt.Errorf("truncate fleet_vehicles: %w", err)
	}

	coll := r.mongo.Collection("fleet_vehicles")
	cursor, err := coll.Find(ctx, bson.M{"deleted_at": nil}, options.Find().SetBatchSize(100))
	if err != nil {
		return fmt.Errorf("MongoDB find vehicles: %w", err)
	}
	defer cursor.Close(ctx)

	count := 0
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			log.Printf("[Rebuild] decode vehicle ล้มเหลว: %v", err)
			continue
		}

		payload, err := mongoToPayload(doc)
		if err != nil {
			log.Printf("[Rebuild] mongoToPayload vehicle ล้มเหลว: %v", err)
			continue
		}

		if err := r.sync.upsertVehicle(payload); err != nil {
			log.Printf("[Rebuild] upsertVehicle ล้มเหลว: %v", err)
			continue
		}
		count++
	}

	log.Printf("[Rebuild] vehicles: %d รายการ", count)
	return cursor.Err()
}

// rebuildDrivers rebuild fleet_drivers จาก MongoDB
func (r *RebuildService) rebuildDrivers(ctx context.Context) error {
	if err := r.truncateTable(ctx, "fleet_drivers"); err != nil {
		return fmt.Errorf("truncate fleet_drivers: %w", err)
	}

	coll := r.mongo.Collection("fleet_drivers")
	cursor, err := coll.Find(ctx, bson.M{"deleted_at": nil}, options.Find().SetBatchSize(100))
	if err != nil {
		return fmt.Errorf("MongoDB find drivers: %w", err)
	}
	defer cursor.Close(ctx)

	count := 0
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			log.Printf("[Rebuild] decode driver ล้มเหลว: %v", err)
			continue
		}

		payload, err := mongoToPayload(doc)
		if err != nil {
			log.Printf("[Rebuild] mongoToPayload driver ล้มเหลว: %v", err)
			continue
		}

		if err := r.sync.upsertDriver(payload); err != nil {
			log.Printf("[Rebuild] upsertDriver ล้มเหลว: %v", err)
			continue
		}
		count++
	}

	log.Printf("[Rebuild] drivers: %d รายการ", count)
	return cursor.Err()
}

// rebuildTrips rebuild fleet_trips จาก MongoDB
func (r *RebuildService) rebuildTrips(ctx context.Context) error {
	if err := r.truncateTable(ctx, "fleet_trips"); err != nil {
		return fmt.Errorf("truncate fleet_trips: %w", err)
	}

	coll := r.mongo.Collection("fleet_trips")
	cursor, err := coll.Find(ctx, bson.D{}, options.Find().SetBatchSize(100))
	if err != nil {
		return fmt.Errorf("MongoDB find trips: %w", err)
	}
	defer cursor.Close(ctx)

	count := 0
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			log.Printf("[Rebuild] decode trip ล้มเหลว: %v", err)
			continue
		}

		payload, err := mongoToPayload(doc)
		if err != nil {
			log.Printf("[Rebuild] mongoToPayload trip ล้มเหลว: %v", err)
			continue
		}

		if err := r.sync.upsertTrip(payload); err != nil {
			log.Printf("[Rebuild] upsertTrip ล้มเหลว: %v", err)
			continue
		}
		count++
	}

	log.Printf("[Rebuild] trips: %d รายการ", count)
	return cursor.Err()
}

// rebuildWorkOrders rebuild fleet_work_orders จาก MongoDB
func (r *RebuildService) rebuildWorkOrders(ctx context.Context) error {
	if err := r.truncateTable(ctx, "fleet_work_orders"); err != nil {
		return fmt.Errorf("truncate fleet_work_orders: %w", err)
	}

	coll := r.mongo.Collection("fleet_maintenance_work_orders")
	cursor, err := coll.Find(ctx, bson.D{}, options.Find().SetBatchSize(100))
	if err != nil {
		return fmt.Errorf("MongoDB find work_orders: %w", err)
	}
	defer cursor.Close(ctx)

	count := 0
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			log.Printf("[Rebuild] decode work_order ล้มเหลว: %v", err)
			continue
		}

		payload, err := mongoToPayload(doc)
		if err != nil {
			log.Printf("[Rebuild] mongoToPayload work_order ล้มเหลว: %v", err)
			continue
		}

		if err := r.sync.upsertWorkOrder(payload); err != nil {
			log.Printf("[Rebuild] upsertWorkOrder ล้มเหลว: %v", err)
			continue
		}
		count++
	}

	log.Printf("[Rebuild] work_orders: %d รายการ", count)
	return cursor.Err()
}

// rebuildPartners rebuild fleet_partner_vehicles จาก MongoDB
func (r *RebuildService) rebuildPartners(ctx context.Context) error {
	if err := r.truncateTable(ctx, "fleet_partner_vehicles"); err != nil {
		return fmt.Errorf("truncate fleet_partner_vehicles: %w", err)
	}

	coll := r.mongo.Collection("fleet_partner_vehicles")
	cursor, err := coll.Find(ctx, bson.D{}, options.Find().SetBatchSize(100))
	if err != nil {
		return fmt.Errorf("MongoDB find partners: %w", err)
	}
	defer cursor.Close(ctx)

	count := 0
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			log.Printf("[Rebuild] decode partner ล้มเหลว: %v", err)
			continue
		}

		payload, err := mongoToPayload(doc)
		if err != nil {
			log.Printf("[Rebuild] mongoToPayload partner ล้มเหลว: %v", err)
			continue
		}

		if err := r.sync.upsertPartner(payload); err != nil {
			log.Printf("[Rebuild] upsertPartner ล้มเหลว: %v", err)
			continue
		}
		count++
	}

	log.Printf("[Rebuild] partners: %d รายการ", count)
	return cursor.Err()
}

// rebuildExpenses rebuild fleet_expenses จาก MongoDB
func (r *RebuildService) rebuildExpenses(ctx context.Context) error {
	if err := r.truncateTable(ctx, "fleet_expenses"); err != nil {
		return fmt.Errorf("truncate fleet_expenses: %w", err)
	}

	coll := r.mongo.Collection("fleet_expenses")
	cursor, err := coll.Find(ctx, bson.D{}, options.Find().SetBatchSize(100))
	if err != nil {
		return fmt.Errorf("MongoDB find expenses: %w", err)
	}
	defer cursor.Close(ctx)

	count := 0
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			log.Printf("[Rebuild] decode expense ล้มเหลว: %v", err)
			continue
		}

		payload, err := mongoToPayload(doc)
		if err != nil {
			log.Printf("[Rebuild] mongoToPayload expense ล้มเหลว: %v", err)
			continue
		}

		if err := r.sync.upsertExpense(payload); err != nil {
			log.Printf("[Rebuild] upsertExpense ล้มเหลว: %v", err)
			continue
		}
		count++
	}

	log.Printf("[Rebuild] expenses: %d รายการ", count)
	return cursor.Err()
}
