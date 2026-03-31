package service

import (
	"context"
	"fmt"
	"log"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// AlertService ตรวจสอบและสร้าง alerts อัตโนมัติ
type AlertService struct {
	pgDB  *database.PostgresDB
	mongo *database.MongoDB
	kafka *database.KafkaProducer
}

// NewAlertService สร้าง AlertService ใหม่
func NewAlertService(pgDB *database.PostgresDB, mongo *database.MongoDB, kafka *database.KafkaProducer) *AlertService {
	return &AlertService{
		pgDB:  pgDB,
		mongo: mongo,
		kafka: kafka,
	}
}

// Alert type constants
const (
	AlertTypeInsuranceExpiry = "insurance_expiry"
	AlertTypeTaxDue          = "tax_due"
	AlertTypeActDue          = "act_due"
	AlertTypeLicenseExpiry   = "license_expiry"
	AlertTypeMaintenanceDue  = "maintenance_due"
	AlertTypeGeofence        = "geofence_alert"
	AlertTypeSpeeding        = "speeding"
)

// alertThresholds วันที่ต้องแจ้งเตือนก่อนกำหนด
var alertThresholds = []int{30, 15, 7}

// RunAlertCheck ตรวจสอบและสร้าง alerts — เรียกจาก cron job ทุกชั่วโมง
func (s *AlertService) RunAlertCheck(ctx context.Context) error {
	log.Println("[AlertService] เริ่มตรวจสอบ alerts...")

	var errs []error

	if err := s.checkInsuranceExpiry(ctx); err != nil {
		errs = append(errs, fmt.Errorf("insurance: %w", err))
	}
	if err := s.checkTaxDue(ctx); err != nil {
		errs = append(errs, fmt.Errorf("tax: %w", err))
	}
	if err := s.checkActDue(ctx); err != nil {
		errs = append(errs, fmt.Errorf("act: %w", err))
	}
	if err := s.checkLicenseExpiry(ctx); err != nil {
		errs = append(errs, fmt.Errorf("license: %w", err))
	}
	if err := s.checkMaintenanceDue(ctx); err != nil {
		errs = append(errs, fmt.Errorf("maintenance: %w", err))
	}

	if len(errs) > 0 {
		for _, e := range errs {
			log.Printf("[AlertService] error: %v", e)
		}
		return fmt.Errorf("alert check completed with %d errors", len(errs))
	}

	log.Println("[AlertService] ตรวจสอบ alerts เสร็จสิ้น")
	return nil
}

// ─────────────────────────────────────────────────────────────
// 1. ประกันภัยหมดอายุ
// ─────────────────────────────────────────────────────────────

func (s *AlertService) checkInsuranceExpiry(ctx context.Context) error {
	rows, err := s.pgDB.Pool().Query(ctx, `
		SELECT id, shop_id, plate, insurance_expiry
		FROM fleet_vehicles
		WHERE deleted_at IS NULL
		  AND status != 'inactive'
		  AND insurance_expiry IS NOT NULL
		  AND insurance_expiry BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, shopID, plate string
		var expiryDate time.Time
		if err := rows.Scan(&id, &shopID, &plate, &expiryDate); err != nil {
			continue
		}

		daysRemaining := int(time.Until(expiryDate).Hours() / 24)
		if !s.isAlertThreshold(daysRemaining) {
			continue
		}

		alert := s.buildAlert(
			shopID, AlertTypeInsuranceExpiry, "vehicle", id,
			fmt.Sprintf("ประกันภัยใกล้หมดอายุ — %s", plate),
			fmt.Sprintf("รถ %s ประกันหมดอายุ %s (เหลือ %d วัน)", plate, expiryDate.Format("02/01/2006"), daysRemaining),
			s.severityFromDays(daysRemaining), expiryDate, daysRemaining,
		)
		if err := s.upsertAlert(ctx, alert); err != nil {
			log.Printf("[AlertService] upsert insurance alert error: %v", err)
		}
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// 2. ภาษีรถใกล้กำหนด
// ─────────────────────────────────────────────────────────────

func (s *AlertService) checkTaxDue(ctx context.Context) error {
	rows, err := s.pgDB.Pool().Query(ctx, `
		SELECT id, shop_id, plate, tax_due_date
		FROM fleet_vehicles
		WHERE deleted_at IS NULL
		  AND status != 'inactive'
		  AND tax_due_date IS NOT NULL
		  AND tax_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, shopID, plate string
		var dueDate time.Time
		if err := rows.Scan(&id, &shopID, &plate, &dueDate); err != nil {
			continue
		}

		daysRemaining := int(time.Until(dueDate).Hours() / 24)
		if !s.isAlertThreshold(daysRemaining) {
			continue
		}

		alert := s.buildAlert(
			shopID, AlertTypeTaxDue, "vehicle", id,
			fmt.Sprintf("ภาษีรถใกล้กำหนด — %s", plate),
			fmt.Sprintf("รถ %s ภาษีครบกำหนด %s (เหลือ %d วัน)", plate, dueDate.Format("02/01/2006"), daysRemaining),
			s.severityFromDays(daysRemaining), dueDate, daysRemaining,
		)
		if err := s.upsertAlert(ctx, alert); err != nil {
			log.Printf("[AlertService] upsert tax alert error: %v", err)
		}
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// 3. พ.ร.บ. ใกล้กำหนด
// ─────────────────────────────────────────────────────────────

func (s *AlertService) checkActDue(ctx context.Context) error {
	rows, err := s.pgDB.Pool().Query(ctx, `
		SELECT id, shop_id, plate, act_due_date
		FROM fleet_vehicles
		WHERE deleted_at IS NULL
		  AND status != 'inactive'
		  AND act_due_date IS NOT NULL
		  AND act_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, shopID, plate string
		var dueDate time.Time
		if err := rows.Scan(&id, &shopID, &plate, &dueDate); err != nil {
			continue
		}

		daysRemaining := int(time.Until(dueDate).Hours() / 24)
		if !s.isAlertThreshold(daysRemaining) {
			continue
		}

		alert := s.buildAlert(
			shopID, AlertTypeActDue, "vehicle", id,
			fmt.Sprintf("พ.ร.บ. ใกล้กำหนด — %s", plate),
			fmt.Sprintf("รถ %s พ.ร.บ.ครบกำหนด %s (เหลือ %d วัน)", plate, dueDate.Format("02/01/2006"), daysRemaining),
			s.severityFromDays(daysRemaining), dueDate, daysRemaining,
		)
		if err := s.upsertAlert(ctx, alert); err != nil {
			log.Printf("[AlertService] upsert act alert error: %v", err)
		}
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// 4. ใบขับขี่หมดอายุ
// ─────────────────────────────────────────────────────────────

func (s *AlertService) checkLicenseExpiry(ctx context.Context) error {
	rows, err := s.pgDB.Pool().Query(ctx, `
		SELECT id, shop_id, name, license_expiry
		FROM fleet_drivers
		WHERE deleted_at IS NULL
		  AND status = 'active'
		  AND license_expiry IS NOT NULL
		  AND license_expiry BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var id, shopID, name string
		var expiryDate time.Time
		if err := rows.Scan(&id, &shopID, &name, &expiryDate); err != nil {
			continue
		}

		daysRemaining := int(time.Until(expiryDate).Hours() / 24)
		if !s.isAlertThreshold(daysRemaining) {
			continue
		}

		alert := s.buildAlert(
			shopID, AlertTypeLicenseExpiry, "driver", id,
			fmt.Sprintf("ใบขับขี่ใกล้หมดอายุ — %s", name),
			fmt.Sprintf("คนขับ %s ใบขับขี่หมดอายุ %s (เหลือ %d วัน)", name, expiryDate.Format("02/01/2006"), daysRemaining),
			s.severityFromDays(daysRemaining), expiryDate, daysRemaining,
		)
		if err := s.upsertAlert(ctx, alert); err != nil {
			log.Printf("[AlertService] upsert license alert error: %v", err)
		}
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// 5. ซ่อมบำรุงครบกำหนด
// ─────────────────────────────────────────────────────────────

func (s *AlertService) checkMaintenanceDue(ctx context.Context) error {
	rows, err := s.pgDB.Pool().Query(ctx, `
		SELECT id, shop_id, plate, mileage_km, next_maintenance_km, next_maintenance_date
		FROM fleet_vehicles
		WHERE deleted_at IS NULL
		  AND status = 'active'
		  AND (
		    (next_maintenance_date IS NOT NULL AND next_maintenance_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days')
		    OR
		    (next_maintenance_km IS NOT NULL AND mileage_km IS NOT NULL AND (next_maintenance_km - mileage_km) <= 1000)
		  )
	`)
	if err != nil {
		return err
	}
	defer rows.Close()

	type mRow struct {
		id, shopID, plate string
		mileageKm         int
		nextKm            *int
		nextDate          *time.Time
	}

	var vehicleRows []mRow
	for rows.Next() {
		var r mRow
		if err := rows.Scan(&r.id, &r.shopID, &r.plate, &r.mileageKm, &r.nextKm, &r.nextDate); err != nil {
			continue
		}
		vehicleRows = append(vehicleRows, r)
	}

	for _, r := range vehicleRows {
		// แจ้งตามวันที่
		if r.nextDate != nil {
			daysRemaining := int(time.Until(*r.nextDate).Hours() / 24)
			if s.isAlertThreshold(daysRemaining) {
				alert := s.buildAlert(
					r.shopID, AlertTypeMaintenanceDue, "vehicle", r.id,
					fmt.Sprintf("ซ่อมบำรุงครบกำหนด — %s", r.plate),
					fmt.Sprintf("รถ %s ถึงกำหนดซ่อมบำรุง %s (เหลือ %d วัน)", r.plate, r.nextDate.Format("02/01/2006"), daysRemaining),
					s.severityFromDays(daysRemaining), *r.nextDate, daysRemaining,
				)
				if err := s.upsertAlert(ctx, alert); err != nil {
					log.Printf("[AlertService] upsert maintenance(date) alert error: %v", err)
				}
			}
		}

		// แจ้งตาม KM
		if r.nextKm != nil {
			kmRemaining := *r.nextKm - r.mileageKm
			if kmRemaining <= 1000 {
				severity := "warning"
				if kmRemaining <= 200 {
					severity = "critical"
				}
				dueDate := time.Now().AddDate(0, 0, 14)
				entityID := r.id + ":km"
				alert := s.buildAlert(
					r.shopID, AlertTypeMaintenanceDue, "vehicle", entityID,
					fmt.Sprintf("ซ่อมบำรุงใกล้ครบ KM — %s", r.plate),
					fmt.Sprintf("รถ %s เหลืออีก %d km ถึงกำหนดซ่อมบำรุง (ปัจจุบัน %d km)", r.plate, kmRemaining, r.mileageKm),
					severity, dueDate, kmRemaining,
				)
				if err := s.upsertAlert(ctx, alert); err != nil {
					log.Printf("[AlertService] upsert maintenance(km) alert error: %v", err)
				}
			}
		}
	}
	return nil
}

// ─────────────────────────────────────────────────────────────
// 6. Geofence Alert (placeholder)
// ─────────────────────────────────────────────────────────────

// CheckGeofenceAlert ตรวจสอบรถออกนอก zone ที่กำหนด
// TODO: implement จริงเมื่อมี geofence polygon data
func (s *AlertService) CheckGeofenceAlert(ctx context.Context, shopID, vehicleID string, lat, lng float64) error {
	log.Printf("[AlertService] GeofenceAlert: vehicle=%s lat=%f lng=%f (not implemented)", vehicleID, lat, lng)
	return nil
}

// ─────────────────────────────────────────────────────────────
// 7. Speeding Alert (placeholder)
// ─────────────────────────────────────────────────────────────

// CheckSpeedingAlert ตรวจสอบความเร็วเกินกำหนด (> 90 km/h)
// เรียกจาก GPS handler ทุกครั้งที่รับ GPS update
func (s *AlertService) CheckSpeedingAlert(ctx context.Context, shopID, vehicleID string, speedKmh float64) error {
	const speedLimit = 90.0
	if speedKmh <= speedLimit {
		return nil
	}

	now := time.Now()
	alert := s.buildAlert(
		shopID, AlertTypeSpeeding, "vehicle", vehicleID,
		"ขับเร็วเกินกำหนด",
		fmt.Sprintf("รถ %s ขับเร็ว %.0f km/h (เกินกำหนด %g km/h)", vehicleID, speedKmh, speedLimit),
		"warning", now, 0,
	)
	// speeding alert บันทึกทุกครั้ง ไม่ต้องตรวจ duplicate
	return s.createAlertDoc(ctx, alert)
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

// isAlertThreshold ตรวจสอบว่า daysRemaining อยู่ใน threshold หรือไม่
func (s *AlertService) isAlertThreshold(days int) bool {
	for _, t := range alertThresholds {
		if days >= t-1 && days <= t+1 {
			return true
		}
	}
	return days <= 0
}

// severityFromDays กำหนด severity ตามจำนวนวัน
func (s *AlertService) severityFromDays(days int) string {
	if days <= 7 {
		return "critical"
	}
	if days <= 15 {
		return "warning"
	}
	return "info"
}

// buildAlert สร้าง Alert model ตาม schema จริง
func (s *AlertService) buildAlert(
	shopID, alertType, entity, entityID, title, message, severity string,
	dueDate time.Time, daysRemaining int,
) *models.Alert {
	t := false
	notified := &models.NotificationStatus{LINE: t, Push: t, Email: t}
	return &models.Alert{
		ID:            primitive.NewObjectID(),
		ShopID:        shopID,
		Type:          alertType,
		Entity:        entity,
		EntityID:      entityID,
		Title:         title,
		Message:       message,
		Severity:      severity,
		DueDate:       &dueDate,
		DaysRemaining: daysRemaining,
		Status:        "active",
		Notified:      notified,
		CreatedAt:     time.Now(),
	}
}

// upsertAlert บันทึก alert ถ้ายังไม่มี active alert สำหรับ entity นี้
func (s *AlertService) upsertAlert(ctx context.Context, alert *models.Alert) error {
	col := s.mongo.Collection("fleet_alerts")

	filter := bson.M{
		"shop_id":   alert.ShopID,
		"type":      alert.Type,
		"entity_id": alert.EntityID,
		"status":    "active",
	}

	var existing bson.M
	err := col.FindOne(ctx, filter).Decode(&existing)
	if err == nil {
		// มีอยู่แล้ว — อัปเดต message + days_remaining + severity
		_, updateErr := col.UpdateOne(ctx, filter, bson.M{
			"$set": bson.M{
				"message":        alert.Message,
				"days_remaining": alert.DaysRemaining,
				"severity":       alert.Severity,
				"updated_at":     time.Now(),
			},
		})
		return updateErr
	}
	if err != mongo.ErrNoDocuments {
		return err
	}

	// ไม่มี — สร้างใหม่
	return s.createAlertDoc(ctx, alert)
}

// createAlertDoc เขียน alert ลง MongoDB + produce Kafka event
func (s *AlertService) createAlertDoc(ctx context.Context, alert *models.Alert) error {
	col := s.mongo.Collection("fleet_alerts")

	_, err := col.InsertOne(ctx, alert)
	if err != nil {
		return fmt.Errorf("insert alert MongoDB: %w", err)
	}

	s.kafka.Produce("fleet.alerts", database.KafkaEvent{
		Type:      "alert.created",
		ShopID:    alert.ShopID,
		EntityID:  alert.ID.Hex(),
		Payload:   alert,
		Timestamp: time.Now(),
	})

	log.Printf("[AlertService] สร้าง alert: [%s] %s — %s", alert.Severity, alert.Type, alert.Title)
	return nil
}
