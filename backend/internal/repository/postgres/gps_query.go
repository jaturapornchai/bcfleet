package postgres

import (
	"context"
	"time"

	"bc-fleet/internal/database"
)

// GPSQuery PostgreSQL queries สำหรับ GPS (เก็บแค่ current location)
type GPSQuery struct {
	db *database.PostgresDB
}

// NewGPSQuery สร้าง GPSQuery ใหม่
func NewGPSQuery(db *database.PostgresDB) *GPSQuery {
	return &GPSQuery{db: db}
}

// VehicleLocationRow ตำแหน่งปัจจุบันของรถ
type VehicleLocationRow struct {
	VehicleID  string     `json:"vehicle_id"`
	ShopID     string     `json:"shop_id"`
	DriverID   *string    `json:"driver_id"`
	TripID     *string    `json:"trip_id"`
	Lat        *float64   `json:"lat"`
	Lng        *float64   `json:"lng"`
	SpeedKmh   *float64   `json:"speed_kmh"`
	Heading    *int       `json:"heading"`
	BatteryPct *int       `json:"battery_pct"`
	UpdatedAt  *time.Time `json:"updated_at"`
}

// GPSTrailRow จุด GPS สำหรับ trip tracking (ดึงจาก PostgreSQL ถ้ามี หรือ MongoDB)
type GPSTrailRow struct {
	Lat       float64   `json:"lat"`
	Lng       float64   `json:"lng"`
	SpeedKmh  float64   `json:"speed_kmh"`
	Heading   int       `json:"heading"`
	Timestamp time.Time `json:"timestamp"`
}

// GetAllLocations ดึงตำแหน่งปัจจุบันของรถทุกคันในร้าน
func (q *GPSQuery) GetAllLocations(ctx context.Context, shopID string) ([]VehicleLocationRow, error) {
	sql := `
		SELECT
			vehicle_id, shop_id, driver_id, trip_id,
			lat, lng, speed_kmh, heading, battery_pct, updated_at
		FROM fleet_vehicle_locations
		WHERE shop_id = $1
		ORDER BY updated_at DESC NULLS LAST
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var locations []VehicleLocationRow
	for rows.Next() {
		var loc VehicleLocationRow
		if err := rows.Scan(
			&loc.VehicleID, &loc.ShopID, &loc.DriverID, &loc.TripID,
			&loc.Lat, &loc.Lng, &loc.SpeedKmh, &loc.Heading,
			&loc.BatteryPct, &loc.UpdatedAt,
		); err != nil {
			return nil, err
		}
		locations = append(locations, loc)
	}
	return locations, rows.Err()
}
