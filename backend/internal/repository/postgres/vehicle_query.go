package postgres

import (
	"context"
	"time"

	"bc-fleet/internal/database"
)

type VehicleQuery struct {
	db *database.PostgresDB
}

func NewVehicleQuery(db *database.PostgresDB) *VehicleQuery {
	return &VehicleQuery{db: db}
}

type VehicleRow struct {
	ID              string    `json:"id"`
	ShopID          string    `json:"shop_id"`
	Plate           string    `json:"plate"`
	Brand           *string   `json:"brand"`
	Model           *string   `json:"model"`
	Type            string    `json:"type"`
	Year            *int      `json:"year"`
	Status          string    `json:"status"`
	CurrentDriverID *string   `json:"current_driver_id"`
	MileageKm       *int      `json:"mileage_km"`
	HealthStatus    string    `json:"health_status"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type VehicleHealthRow struct {
	ID                  string  `json:"id"`
	Plate               string  `json:"plate"`
	HealthStatus        string  `json:"health_status"`
	InsuranceExpiry     *string `json:"insurance_expiry"`
	TaxDueDate          *string `json:"tax_due_date"`
	ActDueDate          *string `json:"act_due_date"`
	NextMaintenanceKm   *int    `json:"next_maintenance_km"`
	NextMaintenanceDate *string `json:"next_maintenance_date"`
	MileageKm           *int    `json:"mileage_km"`
}

// List ดึงรายการรถ กรองตาม status, type พร้อม pagination
func (q *VehicleQuery) List(ctx context.Context, shopID string, status string, vehicleType string, page, limit int) ([]VehicleRow, int, error) {
	offset := (page - 1) * limit

	sql := `
		SELECT
			id, shop_id, plate, brand, model, type, year,
			status, current_driver_id, mileage_km, health_status,
			created_at, updated_at,
			COUNT(*) OVER() AS total_count
		FROM fleet_vehicles
		WHERE shop_id = $1
		  AND deleted_at IS NULL
		  AND ($2 = '' OR status = $2)
		  AND ($3 = '' OR type = $3)
		ORDER BY created_at DESC
		LIMIT $4 OFFSET $5
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, status, vehicleType, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var vehicles []VehicleRow
	var total int
	for rows.Next() {
		var v VehicleRow
		if err := rows.Scan(
			&v.ID, &v.ShopID, &v.Plate, &v.Brand, &v.Model, &v.Type, &v.Year,
			&v.Status, &v.CurrentDriverID, &v.MileageKm, &v.HealthStatus,
			&v.CreatedAt, &v.UpdatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		vehicles = append(vehicles, v)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return vehicles, total, nil
}

// GetByID ดึงรถคันเดียวตาม ID
func (q *VehicleQuery) GetByID(ctx context.Context, shopID, id string) (*VehicleRow, error) {
	sql := `
		SELECT
			id, shop_id, plate, brand, model, type, year,
			status, current_driver_id, mileage_km, health_status,
			created_at, updated_at
		FROM fleet_vehicles
		WHERE shop_id = $1 AND id = $2 AND deleted_at IS NULL
	`

	var v VehicleRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&v.ID, &v.ShopID, &v.Plate, &v.Brand, &v.Model, &v.Type, &v.Year,
		&v.Status, &v.CurrentDriverID, &v.MileageKm, &v.HealthStatus,
		&v.CreatedAt, &v.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &v, nil
}

// GetHealth ดึงสถานะสุขภาพรถ
func (q *VehicleQuery) GetHealth(ctx context.Context, shopID, id string) (*VehicleHealthRow, error) {
	sql := `
		SELECT
			id,
			plate,
			health_status,
			TO_CHAR(insurance_expiry, 'YYYY-MM-DD')     AS insurance_expiry,
			TO_CHAR(tax_due_date, 'YYYY-MM-DD')          AS tax_due_date,
			TO_CHAR(act_due_date, 'YYYY-MM-DD')          AS act_due_date,
			next_maintenance_km,
			TO_CHAR(next_maintenance_date, 'YYYY-MM-DD') AS next_maintenance_date,
			mileage_km
		FROM fleet_vehicles
		WHERE shop_id = $1 AND id = $2 AND deleted_at IS NULL
	`

	var h VehicleHealthRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&h.ID, &h.Plate, &h.HealthStatus,
		&h.InsuranceExpiry, &h.TaxDueDate, &h.ActDueDate,
		&h.NextMaintenanceKm, &h.NextMaintenanceDate, &h.MileageKm,
	)
	if err != nil {
		return nil, err
	}
	return &h, nil
}
