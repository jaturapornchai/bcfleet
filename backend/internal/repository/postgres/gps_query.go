package postgres

import (
	"context"
	"time"

	"sml-fleet/internal/database"
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

// MovingVehicleRow รถที่ตรวจพบว่ากำลังเคลื่อนที่
type MovingVehicleRow struct {
	VehicleID        string     `json:"vehicle_id"`
	ShopID           string     `json:"shop_id"`
	Plate            string     `json:"plate"`
	DriverID         *string    `json:"driver_id"`
	TripID           *string    `json:"trip_id"`
	Lat              float64    `json:"lat"`
	Lng              float64    `json:"lng"`
	PrevLat          float64    `json:"prev_lat"`
	PrevLng          float64    `json:"prev_lng"`
	SpeedKmh         *float64   `json:"speed_kmh"`
	Heading          *int       `json:"heading"`
	DistanceM        float64    `json:"distance_m"`          // ระยะทางที่เคลื่อนที่ (เมตร)
	MonitoringPrompt *string    `json:"monitoring_prompt"`   // AI prompt เฉพาะรถคันนี้
	UpdatedAt        *time.Time `json:"updated_at"`
	PrevUpdatedAt    *time.Time `json:"prev_updated_at"`
}

// GetMovingVehicles ดึงรถที่เคลื่อนที่ (distance > minDistanceM) ในช่วง maxAgeMinutes นาทีที่ผ่านมา
func (q *GPSQuery) GetMovingVehicles(ctx context.Context, shopID string, minDistanceM float64, maxAgeMinutes int) ([]MovingVehicleRow, error) {
	sql := `
		SELECT
			l.vehicle_id,
			l.shop_id,
			COALESCE(v.plate, l.vehicle_id) AS plate,
			l.driver_id,
			l.trip_id,
			l.lat,
			l.lng,
			l.prev_lat,
			l.prev_lng,
			l.speed_kmh,
			l.heading,
			2 * 6371000 * asin(sqrt(
				power(sin(radians((l.lat - l.prev_lat) / 2)), 2) +
				cos(radians(l.prev_lat)) * cos(radians(l.lat)) *
				power(sin(radians((l.lng - l.prev_lng) / 2)), 2)
			)) AS distance_m,
			v.monitoring_prompt,
			l.updated_at,
			l.prev_updated_at
		FROM fleet_vehicle_locations l
		LEFT JOIN fleet_vehicles v ON v.id = l.vehicle_id
		WHERE
			l.shop_id = $1
			AND l.prev_lat IS NOT NULL
			AND l.prev_lng IS NOT NULL
			AND l.lat IS NOT NULL
			AND l.lng IS NOT NULL
			AND l.updated_at > NOW() - ($2 * INTERVAL '1 minute')
			AND 2 * 6371000 * asin(sqrt(
				power(sin(radians((l.lat - l.prev_lat) / 2)), 2) +
				cos(radians(l.prev_lat)) * cos(radians(l.lat)) *
				power(sin(radians((l.lng - l.prev_lng) / 2)), 2)
			)) > $3
		ORDER BY distance_m DESC
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, maxAgeMinutes, minDistanceM)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []MovingVehicleRow
	for rows.Next() {
		var r MovingVehicleRow
		if err := rows.Scan(
			&r.VehicleID, &r.ShopID, &r.Plate,
			&r.DriverID, &r.TripID,
			&r.Lat, &r.Lng, &r.PrevLat, &r.PrevLng,
			&r.SpeedKmh, &r.Heading, &r.DistanceM,
			&r.MonitoringPrompt,
			&r.UpdatedAt, &r.PrevUpdatedAt,
		); err != nil {
			return nil, err
		}
		results = append(results, r)
	}
	return results, rows.Err()
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
