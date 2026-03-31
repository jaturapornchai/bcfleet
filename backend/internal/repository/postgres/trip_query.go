package postgres

import (
	"context"
	"time"

	"bc-fleet/internal/database"
)

type TripQuery struct {
	db *database.PostgresDB
}

func NewTripQuery(db *database.PostgresDB) *TripQuery {
	return &TripQuery{db: db}
}

type TripRow struct {
	ID               string     `json:"id"`
	ShopID           string     `json:"shop_id"`
	TripNo           *string    `json:"trip_no"`
	Status           string     `json:"status"`
	VehicleID        *string    `json:"vehicle_id"`
	DriverID         *string    `json:"driver_id"`
	IsPartner        bool       `json:"is_partner"`
	PartnerID        *string    `json:"partner_id"`
	OriginName       *string    `json:"origin_name"`
	OriginLat        *float64   `json:"origin_lat"`
	OriginLng        *float64   `json:"origin_lng"`
	DestinationCount int        `json:"destination_count"`
	CargoDescription *string    `json:"cargo_description"`
	CargoWeightKg    *int       `json:"cargo_weight_kg"`
	PlannedStart     *time.Time `json:"planned_start"`
	PlannedEnd       *time.Time `json:"planned_end"`
	ActualStart      *time.Time `json:"actual_start"`
	ActualEnd        *time.Time `json:"actual_end"`
	DistanceKm       *float64   `json:"distance_km"`
	FuelCost         *float64   `json:"fuel_cost"`
	TollCost         *float64   `json:"toll_cost"`
	OtherCost        *float64   `json:"other_cost"`
	DriverAllowance  *float64   `json:"driver_allowance"`
	TotalCost        *float64   `json:"total_cost"`
	Revenue          *float64   `json:"revenue"`
	Profit           *float64   `json:"profit"`
	HasPOD           bool       `json:"has_pod"`
	CreatedBy        *string    `json:"created_by"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// List ดึงรายการเที่ยววิ่ง พร้อม filter และ pagination
func (q *TripQuery) List(
	ctx context.Context,
	shopID string,
	status string,
	driverID string,
	vehicleID string,
	dateFrom, dateTo *time.Time,
	page, limit int,
) ([]TripRow, int, error) {
	offset := (page - 1) * limit

	sql := `
		SELECT
			id, shop_id, trip_no, status,
			vehicle_id, driver_id, is_partner, partner_id,
			origin_name, origin_lat, origin_lng, destination_count,
			cargo_description, cargo_weight_kg,
			planned_start, planned_end, actual_start, actual_end,
			distance_km, fuel_cost, toll_cost, other_cost,
			driver_allowance, total_cost, revenue, profit,
			has_pod, created_by, created_at, updated_at,
			COUNT(*) OVER() AS total_count
		FROM fleet_trips
		WHERE shop_id = $1
		  AND ($2 = '' OR status = $2)
		  AND ($3 = '' OR driver_id = $3)
		  AND ($4 = '' OR vehicle_id = $4)
		  AND ($5::TIMESTAMPTZ IS NULL OR planned_start >= $5)
		  AND ($6::TIMESTAMPTZ IS NULL OR planned_start <= $6)
		ORDER BY planned_start DESC
		LIMIT $7 OFFSET $8
	`

	rows, err := q.db.Pool().Query(ctx, sql,
		shopID, status, driverID, vehicleID,
		dateFrom, dateTo,
		limit, offset,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var trips []TripRow
	var total int
	for rows.Next() {
		var t TripRow
		if err := rows.Scan(
			&t.ID, &t.ShopID, &t.TripNo, &t.Status,
			&t.VehicleID, &t.DriverID, &t.IsPartner, &t.PartnerID,
			&t.OriginName, &t.OriginLat, &t.OriginLng, &t.DestinationCount,
			&t.CargoDescription, &t.CargoWeightKg,
			&t.PlannedStart, &t.PlannedEnd, &t.ActualStart, &t.ActualEnd,
			&t.DistanceKm, &t.FuelCost, &t.TollCost, &t.OtherCost,
			&t.DriverAllowance, &t.TotalCost, &t.Revenue, &t.Profit,
			&t.HasPOD, &t.CreatedBy, &t.CreatedAt, &t.UpdatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		trips = append(trips, t)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return trips, total, nil
}

// GetByID ดึงเที่ยววิ่งคันเดียวตาม ID
func (q *TripQuery) GetByID(ctx context.Context, shopID, id string) (*TripRow, error) {
	sql := `
		SELECT
			id, shop_id, trip_no, status,
			vehicle_id, driver_id, is_partner, partner_id,
			origin_name, origin_lat, origin_lng, destination_count,
			cargo_description, cargo_weight_kg,
			planned_start, planned_end, actual_start, actual_end,
			distance_km, fuel_cost, toll_cost, other_cost,
			driver_allowance, total_cost, revenue, profit,
			has_pod, created_by, created_at, updated_at
		FROM fleet_trips
		WHERE shop_id = $1 AND id = $2
	`

	var t TripRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&t.ID, &t.ShopID, &t.TripNo, &t.Status,
		&t.VehicleID, &t.DriverID, &t.IsPartner, &t.PartnerID,
		&t.OriginName, &t.OriginLat, &t.OriginLng, &t.DestinationCount,
		&t.CargoDescription, &t.CargoWeightKg,
		&t.PlannedStart, &t.PlannedEnd, &t.ActualStart, &t.ActualEnd,
		&t.DistanceKm, &t.FuelCost, &t.TollCost, &t.OtherCost,
		&t.DriverAllowance, &t.TotalCost, &t.Revenue, &t.Profit,
		&t.HasPOD, &t.CreatedBy, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &t, nil
}
