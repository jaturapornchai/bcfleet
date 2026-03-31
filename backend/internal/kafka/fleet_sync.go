package kafka

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"

	"sml-fleet/internal/database"

	kafkago "github.com/segmentio/kafka-go"
)

// FleetSyncConsumer sync MongoDB events ไป PostgreSQL
type FleetSyncConsumer struct {
	brokers []string
	groupID string
	pgDB    *database.PostgresDB
	readers map[string]*kafkago.Reader
}

// NewFleetSyncConsumer สร้าง FleetSyncConsumer
func NewFleetSyncConsumer(brokers, groupID string, pgDB *database.PostgresDB) *FleetSyncConsumer {
	return &FleetSyncConsumer{
		brokers: strings.Split(brokers, ","),
		groupID: groupID,
		pgDB:    pgDB,
		readers: make(map[string]*kafkago.Reader),
	}
}

// Start เริ่ม consume และ sync — block จนกว่า ctx จะ cancel
func (s *FleetSyncConsumer) Start(ctx context.Context) error {
	for _, topic := range FleetTopics {
		go func(t string) {
			r := kafkago.NewReader(kafkago.ReaderConfig{
				Brokers:  s.brokers,
				GroupID:  s.groupID + "-sync",
				Topic:    t,
				MinBytes: 1,
				MaxBytes: 10e6,
			})
			s.readers[t] = r

			log.Printf("[FleetSync] เริ่ม sync topic: %s", t)
			for {
				select {
				case <-ctx.Done():
					r.Close()
					return
				default:
					msg, err := r.ReadMessage(ctx)
					if err != nil {
						if ctx.Err() != nil {
							return
						}
						log.Printf("[FleetSync] อ่าน %s ล้มเหลว: %v", t, err)
						continue
					}

					var event database.KafkaEvent
					if err := json.Unmarshal(msg.Value, &event); err != nil {
						log.Printf("[FleetSync] parse event ล้มเหลว: %v", err)
						continue
					}

					if err := s.HandleEvent(event); err != nil {
						log.Printf("[FleetSync] HandleEvent ล้มเหลว [%s]: %v", event.Type, err)
					}
				}
			}
		}(topic)
	}

	// block จนกว่า context จะ cancel
	<-ctx.Done()
	return ctx.Err()
}

// HandleEvent route event ไปยัง upsert method ที่เหมาะสม
func (s *FleetSyncConsumer) HandleEvent(event database.KafkaEvent) error {
	switch event.Type {
	case "vehicle.created", "vehicle.updated":
		return s.upsertVehicle(event.Payload)
	case "vehicle.deleted":
		return s.softDeleteVehicle(event.EntityID)

	case "driver.created", "driver.updated":
		return s.upsertDriver(event.Payload)
	case "driver.deleted":
		return s.softDeleteDriver(event.EntityID)

	case "trip.created", "trip.updated", "trip.status_changed":
		return s.upsertTrip(event.Payload)

	case "maintenance.work_order_created", "maintenance.work_order_updated",
		"maintenance.work_order_approved", "maintenance.work_order_completed":
		return s.upsertWorkOrder(event.Payload)

	case "partner.vehicle_registered", "partner.vehicle_updated":
		return s.upsertPartner(event.Payload)

	case "expense.recorded", "expense.updated":
		return s.upsertExpense(event.Payload)

	case "gps.location_updated":
		return s.updateVehicleLocation(event.Payload)

	default:
		// event ที่ไม่ต้อง sync (เช่น event-logs) — ข้ามไป
		return nil
	}
}

// toMap แปลง payload interface{} เป็น map
func toMap(payload interface{}) (map[string]interface{}, error) {
	b, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	var m map[string]interface{}
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, err
	}
	return m, nil
}

// getString ดึงค่า string จาก map
func getString(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok && v != nil {
		return fmt.Sprintf("%v", v)
	}
	return ""
}

// getFloat64 ดึงค่า float64 จาก map
func getFloat64(m map[string]interface{}, key string) float64 {
	if v, ok := m[key]; ok && v != nil {
		switch val := v.(type) {
		case float64:
			return val
		case int:
			return float64(val)
		}
	}
	return 0
}

// getBool ดึงค่า bool จาก map
func getBool(m map[string]interface{}, key string) bool {
	if v, ok := m[key]; ok && v != nil {
		if b, ok := v.(bool); ok {
			return b
		}
	}
	return false
}

// getInt ดึงค่า int จาก map
func getInt(m map[string]interface{}, key string) int {
	return int(getFloat64(m, key))
}

// parseTime แปลง string เป็น time.Time
func parseTime(v interface{}) *time.Time {
	if v == nil {
		return nil
	}
	s, ok := v.(string)
	if !ok {
		return nil
	}
	formats := []string{
		time.RFC3339,
		time.RFC3339Nano,
		"2006-01-02T15:04:05Z",
		"2006-01-02",
	}
	for _, f := range formats {
		if t, err := time.Parse(f, s); err == nil {
			return &t
		}
	}
	return nil
}

// upsertVehicle INSERT ... ON CONFLICT DO UPDATE สำหรับ fleet_vehicles
func (s *FleetSyncConsumer) upsertVehicle(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("upsertVehicle toMap: %w", err)
	}

	// ดึง nested fields
	var insuranceExpiry, taxDueDate, actDueDate *time.Time
	if ins, ok := m["insurance"].(map[string]interface{}); ok {
		insuranceExpiry = parseTime(ins["end_date"])
	}
	if tax, ok := m["tax"].(map[string]interface{}); ok {
		taxDueDate = parseTime(tax["due_date"])
	}
	if act, ok := m["act"].(map[string]interface{}); ok {
		actDueDate = parseTime(act["due_date"])
	}

	var lat, lng *float64
	if loc, ok := m["current_location"].(map[string]interface{}); ok {
		la := getFloat64(loc, "lat")
		ln := getFloat64(loc, "lng")
		lat = &la
		lng = &ln
	}

	id := getString(m, "id")
	if id == "" {
		id = getString(m, "_id")
	}

	now := time.Now()
	createdAt := now
	updatedAt := now
	if t := parseTime(m["created_at"]); t != nil {
		createdAt = *t
	}
	if t := parseTime(m["updated_at"]); t != nil {
		updatedAt = *t
	}

	sql := `
		INSERT INTO fleet_vehicles (
			id, shop_id, plate, brand, model, type, year, color,
			chassis_no, engine_no, fuel_type, max_weight_kg, ownership,
			partner_id, status, current_driver_id,
			current_lat, current_lng, mileage_km,
			insurance_expiry, tax_due_date, act_due_date,
			health_status, created_at, updated_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,
			$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25
		)
		ON CONFLICT (id) DO UPDATE SET
			plate = EXCLUDED.plate,
			brand = EXCLUDED.brand,
			model = EXCLUDED.model,
			type = EXCLUDED.type,
			year = EXCLUDED.year,
			color = EXCLUDED.color,
			fuel_type = EXCLUDED.fuel_type,
			max_weight_kg = EXCLUDED.max_weight_kg,
			ownership = EXCLUDED.ownership,
			partner_id = EXCLUDED.partner_id,
			status = EXCLUDED.status,
			current_driver_id = EXCLUDED.current_driver_id,
			current_lat = EXCLUDED.current_lat,
			current_lng = EXCLUDED.current_lng,
			mileage_km = EXCLUDED.mileage_km,
			insurance_expiry = EXCLUDED.insurance_expiry,
			tax_due_date = EXCLUDED.tax_due_date,
			act_due_date = EXCLUDED.act_due_date,
			health_status = EXCLUDED.health_status,
			updated_at = EXCLUDED.updated_at
	`

	healthStatus := "green"
	if h := getString(m, "health_status"); h != "" {
		healthStatus = h
	}

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		id,
		getString(m, "shop_id"),
		getString(m, "plate"),
		getString(m, "brand"),
		getString(m, "model"),
		getString(m, "type"),
		getInt(m, "year"),
		getString(m, "color"),
		getString(m, "chassis_no"),
		getString(m, "engine_no"),
		getString(m, "fuel_type"),
		getInt(m, "max_weight_kg"),
		getString(m, "ownership"),
		getString(m, "partner_id"),
		getString(m, "status"),
		getString(m, "current_driver_id"),
		lat, lng,
		getInt(m, "mileage_km"),
		insuranceExpiry, taxDueDate, actDueDate,
		healthStatus,
		createdAt, updatedAt,
	)
	return err
}

// softDeleteVehicle set deleted_at = now()
func (s *FleetSyncConsumer) softDeleteVehicle(entityID string) error {
	_, err := s.pgDB.Pool().Exec(context.Background(),
		`UPDATE fleet_vehicles SET deleted_at = $1, updated_at = $1 WHERE id = $2`,
		time.Now(), entityID,
	)
	return err
}

// upsertDriver INSERT ... ON CONFLICT DO UPDATE สำหรับ fleet_drivers
func (s *FleetSyncConsumer) upsertDriver(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("upsertDriver toMap: %w", err)
	}

	id := getString(m, "id")
	if id == "" {
		id = getString(m, "_id")
	}

	var licenseType string
	var licenseExpiry *time.Time
	if lic, ok := m["license"].(map[string]interface{}); ok {
		licenseType = getString(lic, "type")
		licenseExpiry = parseTime(lic["expiry_date"])
	}

	var empType string
	var salary, dailyAllowance, tripBonus float64
	if emp, ok := m["employment"].(map[string]interface{}); ok {
		empType = getString(emp, "type")
		salary = getFloat64(emp, "salary")
		dailyAllowance = getFloat64(emp, "daily_allowance")
		tripBonus = getFloat64(emp, "trip_bonus")
	}

	var score, totalTrips int
	var onTimeRate, fuelEfficiency, customerRating float64
	if perf, ok := m["performance"].(map[string]interface{}); ok {
		score = getInt(perf, "score")
		totalTrips = getInt(perf, "total_trips")
		onTimeRate = getFloat64(perf, "on_time_rate")
		fuelEfficiency = getFloat64(perf, "fuel_efficiency")
		customerRating = getFloat64(perf, "customer_rating")
	}

	now := time.Now()
	createdAt := now
	updatedAt := now
	if t := parseTime(m["created_at"]); t != nil {
		createdAt = *t
	}
	if t := parseTime(m["updated_at"]); t != nil {
		updatedAt = *t
	}

	sql := `
		INSERT INTO fleet_drivers (
			id, shop_id, employee_id, name, nickname, phone,
			license_type, license_expiry, employment_type,
			salary, daily_allowance, trip_bonus, status,
			assigned_vehicle_id, score, total_trips,
			on_time_rate, fuel_efficiency, customer_rating,
			created_at, updated_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21
		)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			nickname = EXCLUDED.nickname,
			phone = EXCLUDED.phone,
			license_type = EXCLUDED.license_type,
			license_expiry = EXCLUDED.license_expiry,
			employment_type = EXCLUDED.employment_type,
			salary = EXCLUDED.salary,
			daily_allowance = EXCLUDED.daily_allowance,
			trip_bonus = EXCLUDED.trip_bonus,
			status = EXCLUDED.status,
			assigned_vehicle_id = EXCLUDED.assigned_vehicle_id,
			score = EXCLUDED.score,
			total_trips = EXCLUDED.total_trips,
			on_time_rate = EXCLUDED.on_time_rate,
			fuel_efficiency = EXCLUDED.fuel_efficiency,
			customer_rating = EXCLUDED.customer_rating,
			updated_at = EXCLUDED.updated_at
	`

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		id,
		getString(m, "shop_id"),
		getString(m, "employee_id"),
		getString(m, "name"),
		getString(m, "nickname"),
		getString(m, "phone"),
		licenseType, licenseExpiry,
		empType,
		salary, dailyAllowance, tripBonus,
		getString(m, "status"),
		getString(m, "assigned_vehicle_id"),
		score, totalTrips,
		onTimeRate, fuelEfficiency, customerRating,
		createdAt, updatedAt,
	)
	return err
}

// softDeleteDriver set deleted_at = now()
func (s *FleetSyncConsumer) softDeleteDriver(entityID string) error {
	_, err := s.pgDB.Pool().Exec(context.Background(),
		`UPDATE fleet_drivers SET deleted_at = $1, updated_at = $1 WHERE id = $2`,
		time.Now(), entityID,
	)
	return err
}

// upsertTrip INSERT ... ON CONFLICT DO UPDATE สำหรับ fleet_trips
func (s *FleetSyncConsumer) upsertTrip(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("upsertTrip toMap: %w", err)
	}

	id := getString(m, "id")
	if id == "" {
		id = getString(m, "_id")
	}

	var originName string
	var originLat, originLng float64
	if orig, ok := m["origin"].(map[string]interface{}); ok {
		originName = getString(orig, "name")
		originLat = getFloat64(orig, "lat")
		originLng = getFloat64(orig, "lng")
	}

	var destCount int
	if dests, ok := m["destinations"].([]interface{}); ok {
		destCount = len(dests)
	}
	if destCount == 0 {
		destCount = 1
	}

	var cargoDesc string
	var cargoWeightKg int
	if cargo, ok := m["cargo"].(map[string]interface{}); ok {
		cargoDesc = getString(cargo, "description")
		cargoWeightKg = getInt(cargo, "weight_kg")
	}

	var plannedStart, plannedEnd, actualStart, actualEnd *time.Time
	if sched, ok := m["schedule"].(map[string]interface{}); ok {
		plannedStart = parseTime(sched["planned_start"])
		plannedEnd = parseTime(sched["planned_end"])
		actualStart = parseTime(sched["actual_start"])
		actualEnd = parseTime(sched["actual_end"])
	}

	var distanceKm, fuelCost, tollCost, otherCost, driverAllowance, totalCost, revenue, profit float64
	if costs, ok := m["costs"].(map[string]interface{}); ok {
		fuelCost = getFloat64(costs, "fuel")
		tollCost = getFloat64(costs, "toll")
		otherCost = getFloat64(costs, "other")
		driverAllowance = getFloat64(costs, "driver_allowance")
		totalCost = getFloat64(costs, "total")
		revenue = getFloat64(costs, "revenue")
		profit = getFloat64(costs, "profit")
	}
	if route, ok := m["route"].(map[string]interface{}); ok {
		distanceKm = getFloat64(route, "distance_km")
	}

	hasPOD := m["pod"] != nil

	now := time.Now()
	createdAt := now
	updatedAt := now
	if t := parseTime(m["created_at"]); t != nil {
		createdAt = *t
	}
	if t := parseTime(m["updated_at"]); t != nil {
		updatedAt = *t
	}

	sql := `
		INSERT INTO fleet_trips (
			id, shop_id, trip_no, status, vehicle_id, driver_id,
			is_partner, partner_id,
			origin_name, origin_lat, origin_lng, destination_count,
			cargo_description, cargo_weight_kg,
			planned_start, planned_end, actual_start, actual_end,
			distance_km, fuel_cost, toll_cost, other_cost,
			driver_allowance, total_cost, revenue, profit,
			has_pod, created_by, created_at, updated_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,
			$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30
		)
		ON CONFLICT (id) DO UPDATE SET
			status = EXCLUDED.status,
			vehicle_id = EXCLUDED.vehicle_id,
			driver_id = EXCLUDED.driver_id,
			is_partner = EXCLUDED.is_partner,
			partner_id = EXCLUDED.partner_id,
			origin_name = EXCLUDED.origin_name,
			origin_lat = EXCLUDED.origin_lat,
			origin_lng = EXCLUDED.origin_lng,
			destination_count = EXCLUDED.destination_count,
			cargo_description = EXCLUDED.cargo_description,
			cargo_weight_kg = EXCLUDED.cargo_weight_kg,
			planned_start = EXCLUDED.planned_start,
			planned_end = EXCLUDED.planned_end,
			actual_start = EXCLUDED.actual_start,
			actual_end = EXCLUDED.actual_end,
			distance_km = EXCLUDED.distance_km,
			fuel_cost = EXCLUDED.fuel_cost,
			toll_cost = EXCLUDED.toll_cost,
			other_cost = EXCLUDED.other_cost,
			driver_allowance = EXCLUDED.driver_allowance,
			total_cost = EXCLUDED.total_cost,
			revenue = EXCLUDED.revenue,
			profit = EXCLUDED.profit,
			has_pod = EXCLUDED.has_pod,
			updated_at = EXCLUDED.updated_at
	`

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		id,
		getString(m, "shop_id"),
		getString(m, "trip_no"),
		getString(m, "status"),
		getString(m, "vehicle_id"),
		getString(m, "driver_id"),
		getBool(m, "is_partner"),
		getString(m, "partner_id"),
		originName, originLat, originLng,
		destCount,
		cargoDesc, cargoWeightKg,
		plannedStart, plannedEnd, actualStart, actualEnd,
		distanceKm, fuelCost, tollCost, otherCost,
		driverAllowance, totalCost, revenue, profit,
		hasPOD,
		getString(m, "created_by"),
		createdAt, updatedAt,
	)
	return err
}

// upsertWorkOrder INSERT ... ON CONFLICT DO UPDATE สำหรับ fleet_work_orders
func (s *FleetSyncConsumer) upsertWorkOrder(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("upsertWorkOrder toMap: %w", err)
	}

	id := getString(m, "id")
	if id == "" {
		id = getString(m, "_id")
	}

	var spType, spName string
	if sp, ok := m["service_provider"].(map[string]interface{}); ok {
		spType = getString(sp, "type")
		spName = getString(sp, "name")
	}

	var partsCost float64
	if parts, ok := m["parts"].([]interface{}); ok {
		for _, p := range parts {
			if pm, ok := p.(map[string]interface{}); ok {
				partsCost += getFloat64(pm, "total")
			}
		}
	}

	var laborCost float64
	if labor, ok := m["labor"].(map[string]interface{}); ok {
		laborCost = getFloat64(labor, "total")
	}

	bcSynced := false
	if bc, ok := m["bc_account_entry"].(map[string]interface{}); ok {
		bcSynced = getBool(bc, "synced")
	}

	approvedAt := parseTime(m["approved_at"])
	completedAt := parseTime(m["completed_at"])

	now := time.Now()
	createdAt := now
	updatedAt := now
	if t := parseTime(m["created_at"]); t != nil {
		createdAt = *t
	}
	if t := parseTime(m["updated_at"]); t != nil {
		updatedAt = *t
	}

	sql := `
		INSERT INTO fleet_work_orders (
			id, shop_id, wo_no, vehicle_id, type, priority, status,
			reported_by, description, mileage_at_report,
			service_provider_type, service_provider_name,
			parts_cost, labor_cost, total_cost,
			approved_by, approved_at, completed_at,
			bc_account_synced, created_at, updated_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21
		)
		ON CONFLICT (id) DO UPDATE SET
			status = EXCLUDED.status,
			priority = EXCLUDED.priority,
			service_provider_type = EXCLUDED.service_provider_type,
			service_provider_name = EXCLUDED.service_provider_name,
			parts_cost = EXCLUDED.parts_cost,
			labor_cost = EXCLUDED.labor_cost,
			total_cost = EXCLUDED.total_cost,
			approved_by = EXCLUDED.approved_by,
			approved_at = EXCLUDED.approved_at,
			completed_at = EXCLUDED.completed_at,
			bc_account_synced = EXCLUDED.bc_account_synced,
			updated_at = EXCLUDED.updated_at
	`

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		id,
		getString(m, "shop_id"),
		getString(m, "wo_no"),
		getString(m, "vehicle_id"),
		getString(m, "type"),
		getString(m, "priority"),
		getString(m, "status"),
		getString(m, "reported_by"),
		getString(m, "description"),
		getInt(m, "mileage_at_report"),
		spType, spName,
		partsCost, laborCost,
		getFloat64(m, "total_cost"),
		getString(m, "approved_by"),
		approvedAt, completedAt,
		bcSynced,
		createdAt, updatedAt,
	)
	return err
}

// upsertPartner INSERT ... ON CONFLICT DO UPDATE สำหรับ fleet_partner_vehicles
func (s *FleetSyncConsumer) upsertPartner(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("upsertPartner toMap: %w", err)
	}

	id := getString(m, "id")
	if id == "" {
		id = getString(m, "_id")
	}

	var ownerName, ownerCompany, ownerPhone, ownerTaxID string
	if owner, ok := m["owner"].(map[string]interface{}); ok {
		ownerName = getString(owner, "name")
		ownerCompany = getString(owner, "company")
		ownerPhone = getString(owner, "phone")
		ownerTaxID = getString(owner, "tax_id")
	}

	var plate, vehicleType string
	var maxWeightKg int
	if v, ok := m["vehicle"].(map[string]interface{}); ok {
		plate = getString(v, "plate")
		vehicleType = getString(v, "type")
		maxWeightKg = getInt(v, "max_weight_kg")
	}

	var pricingModel string
	var baseRate, perKmRate float64
	if pricing, ok := m["pricing"].(map[string]interface{}); ok {
		pricingModel = getString(pricing, "model")
		baseRate = getFloat64(pricing, "base_rate")
		perKmRate = getFloat64(pricing, "per_km")
	}

	var whtRate float64
	if wht, ok := m["withholding_tax"].(map[string]interface{}); ok {
		whtRate = getFloat64(wht, "rate")
	}

	now := time.Now()
	createdAt := now
	updatedAt := now
	if t := parseTime(m["created_at"]); t != nil {
		createdAt = *t
	}
	if t := parseTime(m["updated_at"]); t != nil {
		updatedAt = *t
	}

	sql := `
		INSERT INTO fleet_partner_vehicles (
			id, shop_id, owner_name, owner_company, owner_phone, owner_tax_id,
			plate, vehicle_type, max_weight_kg,
			pricing_model, base_rate, per_km_rate,
			rating, total_trips, status,
			withholding_tax_rate, bc_account_creditor_id,
			created_at, updated_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19
		)
		ON CONFLICT (id) DO UPDATE SET
			owner_name = EXCLUDED.owner_name,
			owner_company = EXCLUDED.owner_company,
			owner_phone = EXCLUDED.owner_phone,
			plate = EXCLUDED.plate,
			vehicle_type = EXCLUDED.vehicle_type,
			max_weight_kg = EXCLUDED.max_weight_kg,
			pricing_model = EXCLUDED.pricing_model,
			base_rate = EXCLUDED.base_rate,
			per_km_rate = EXCLUDED.per_km_rate,
			rating = EXCLUDED.rating,
			total_trips = EXCLUDED.total_trips,
			status = EXCLUDED.status,
			withholding_tax_rate = EXCLUDED.withholding_tax_rate,
			updated_at = EXCLUDED.updated_at
	`

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		id,
		getString(m, "shop_id"),
		ownerName, ownerCompany, ownerPhone, ownerTaxID,
		plate, vehicleType, maxWeightKg,
		pricingModel, baseRate, perKmRate,
		getFloat64(m, "rating"),
		getInt(m, "total_trips"),
		getString(m, "status"),
		whtRate,
		getString(m, "bc_account_creditor_id"),
		createdAt, updatedAt,
	)
	return err
}

// upsertExpense INSERT ... ON CONFLICT DO UPDATE สำหรับ fleet_expenses
func (s *FleetSyncConsumer) upsertExpense(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("upsertExpense toMap: %w", err)
	}

	id := getString(m, "id")
	if id == "" {
		id = getString(m, "_id")
	}

	var fuelLiters, fuelPricePerLiter float64
	var odometerKm int
	if fd, ok := m["fuel_detail"].(map[string]interface{}); ok {
		fuelLiters = getFloat64(fd, "liters")
		fuelPricePerLiter = getFloat64(fd, "price_per_liter")
		odometerKm = getInt(fd, "odometer_km")
	}

	bcSynced := false
	if bc, ok := m["bc_account_entry"].(map[string]interface{}); ok {
		bcSynced = getBool(bc, "synced")
	}

	recordedAt := time.Now()
	if t := parseTime(m["recorded_at"]); t != nil {
		recordedAt = *t
	}
	createdAt := recordedAt
	if t := parseTime(m["created_at"]); t != nil {
		createdAt = *t
	}

	sql := `
		INSERT INTO fleet_expenses (
			id, shop_id, trip_id, vehicle_id, driver_id,
			type, description, amount,
			fuel_liters, fuel_price_per_liter, odometer_km,
			receipt_url, bc_account_synced,
			recorded_at, created_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15
		)
		ON CONFLICT (id) DO UPDATE SET
			type = EXCLUDED.type,
			description = EXCLUDED.description,
			amount = EXCLUDED.amount,
			fuel_liters = EXCLUDED.fuel_liters,
			fuel_price_per_liter = EXCLUDED.fuel_price_per_liter,
			odometer_km = EXCLUDED.odometer_km,
			receipt_url = EXCLUDED.receipt_url,
			bc_account_synced = EXCLUDED.bc_account_synced,
			recorded_at = EXCLUDED.recorded_at
	`

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		id,
		getString(m, "shop_id"),
		getString(m, "trip_id"),
		getString(m, "vehicle_id"),
		getString(m, "driver_id"),
		getString(m, "type"),
		getString(m, "description"),
		getFloat64(m, "amount"),
		fuelLiters, fuelPricePerLiter, odometerKm,
		getString(m, "receipt_url"),
		bcSynced,
		recordedAt, createdAt,
	)
	return err
}

// updateVehicleLocation UPSERT latest GPS location ลง fleet_vehicle_locations
func (s *FleetSyncConsumer) updateVehicleLocation(payload interface{}) error {
	m, err := toMap(payload)
	if err != nil {
		return fmt.Errorf("updateVehicleLocation toMap: %w", err)
	}

	vehicleID := getString(m, "vehicle_id")
	if vehicleID == "" {
		return fmt.Errorf("vehicle_id ว่างเปล่า")
	}

	var lat, lng float64
	if loc, ok := m["location"].(map[string]interface{}); ok {
		// GeoJSON format: coordinates[lng, lat]
		if coords, ok := loc["coordinates"].([]interface{}); ok && len(coords) >= 2 {
			if ln, ok := coords[0].(float64); ok {
				lng = ln
			}
			if la, ok := coords[1].(float64); ok {
				lat = la
			}
		}
	}

	updatedAt := time.Now()
	if t := parseTime(m["timestamp"]); t != nil {
		updatedAt = *t
	}

	sql := `
		INSERT INTO fleet_vehicle_locations (
			vehicle_id, shop_id, driver_id, trip_id,
			lat, lng, speed_kmh, heading, battery_pct, updated_at
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		ON CONFLICT (vehicle_id) DO UPDATE SET
			shop_id = EXCLUDED.shop_id,
			driver_id = EXCLUDED.driver_id,
			trip_id = EXCLUDED.trip_id,
			lat = EXCLUDED.lat,
			lng = EXCLUDED.lng,
			speed_kmh = EXCLUDED.speed_kmh,
			heading = EXCLUDED.heading,
			battery_pct = EXCLUDED.battery_pct,
			updated_at = EXCLUDED.updated_at
	`

	_, err = s.pgDB.Pool().Exec(context.Background(), sql,
		vehicleID,
		getString(m, "shop_id"),
		getString(m, "driver_id"),
		getString(m, "trip_id"),
		lat, lng,
		getFloat64(m, "speed_kmh"),
		getInt(m, "heading"),
		getInt(m, "battery_pct"),
		updatedAt,
	)
	return err
}
