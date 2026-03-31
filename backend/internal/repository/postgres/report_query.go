package postgres

import (
	"context"
	"time"

	"sml-fleet/internal/database"
)

type ReportQuery struct {
	db *database.PostgresDB
}

func NewReportQuery(db *database.PostgresDB) *ReportQuery {
	return &ReportQuery{db: db}
}

type CostPerTripRow struct {
	TripID       string   `json:"trip_id"`
	TripNo       *string  `json:"trip_no"`
	PlannedStart *string  `json:"planned_start"`
	VehicleID    *string  `json:"vehicle_id"`
	DriverID     *string  `json:"driver_id"`
	DistanceKm   *float64 `json:"distance_km"`
	FuelCost     *float64 `json:"fuel_cost"`
	TollCost     *float64 `json:"toll_cost"`
	OtherCost    *float64 `json:"other_cost"`
	TotalCost    *float64 `json:"total_cost"`
	Revenue      *float64 `json:"revenue"`
	Profit       *float64 `json:"profit"`
}

type UtilizationRow struct {
	VehicleID      string  `json:"vehicle_id"`
	Plate          string  `json:"plate"`
	VehicleType    string  `json:"type"`
	TotalTrips     int     `json:"total_trips"`
	TotalDays      int     `json:"total_days"`
	WorkingDays    int     `json:"working_days"`
	UtilizationPct float64 `json:"utilization_pct"`
	TotalRevenue   float64 `json:"total_revenue"`
	TotalCost      float64 `json:"total_cost"`
}

type FuelEfficiencyRow struct {
	VehicleID       string  `json:"vehicle_id"`
	Plate           string  `json:"plate"`
	TotalFuelLiters float64 `json:"total_fuel_liters"`
	TotalFuelCost   float64 `json:"total_fuel_cost"`
	TotalDistanceKm float64 `json:"total_distance_km"`
	KmPerLiter      float64 `json:"km_per_liter"`
	CostPerKm       float64 `json:"cost_per_km"`
}

type DriverPerfRow struct {
	DriverID       string   `json:"driver_id"`
	Name           string   `json:"name"`
	Score          int      `json:"score"`
	TotalTrips     int      `json:"total_trips"`
	OnTimeRate     *float64 `json:"on_time_rate"`
	FuelEfficiency *float64 `json:"fuel_efficiency"`
	CustomerRating *float64 `json:"customer_rating"`
	TotalRevenue   float64  `json:"total_revenue"`
}

// CostPerTrip รายงานต้นทุนต่อเที่ยวในช่วงวันที่กำหนด
func (q *ReportQuery) CostPerTrip(ctx context.Context, shopID string, dateFrom, dateTo time.Time) ([]CostPerTripRow, error) {
	sql := `
		SELECT
			id AS trip_id,
			trip_no,
			TO_CHAR(planned_start, 'YYYY-MM-DD HH24:MI') AS planned_start,
			vehicle_id,
			driver_id,
			distance_km,
			fuel_cost,
			toll_cost,
			other_cost,
			total_cost,
			revenue,
			profit
		FROM fleet_trips
		WHERE shop_id = $1
		  AND planned_start >= $2
		  AND planned_start <= $3
		ORDER BY planned_start DESC
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, dateFrom, dateTo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []CostPerTripRow
	for rows.Next() {
		var r CostPerTripRow
		if err := rows.Scan(
			&r.TripID, &r.TripNo, &r.PlannedStart,
			&r.VehicleID, &r.DriverID,
			&r.DistanceKm,
			&r.FuelCost, &r.TollCost, &r.OtherCost,
			&r.TotalCost, &r.Revenue, &r.Profit,
		); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}

// VehicleUtilization รายงานอัตราการใช้รถในช่วงวันที่กำหนด
func (q *ReportQuery) VehicleUtilization(ctx context.Context, shopID string, dateFrom, dateTo time.Time) ([]UtilizationRow, error) {
	totalDays := int(dateTo.Sub(dateFrom).Hours()/24) + 1

	sql := `
		SELECT
			v.id         AS vehicle_id,
			v.plate,
			v.type,
			COUNT(t.id)  AS total_trips,
			$4::INT      AS total_days,
			COUNT(DISTINCT DATE(t.planned_start)) AS working_days,
			ROUND(
				COUNT(DISTINCT DATE(t.planned_start)) * 100.0 / NULLIF($4, 0),
				2
			) AS utilization_pct,
			COALESCE(SUM(t.revenue), 0)    AS total_revenue,
			COALESCE(SUM(t.total_cost), 0) AS total_cost
		FROM fleet_vehicles v
		LEFT JOIN fleet_trips t
		       ON t.vehicle_id = v.id
		      AND t.planned_start >= $2
		      AND t.planned_start <= $3
		WHERE v.shop_id = $1
		  AND v.deleted_at IS NULL
		GROUP BY v.id, v.plate, v.type
		ORDER BY utilization_pct DESC
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, dateFrom, dateTo, totalDays)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []UtilizationRow
	for rows.Next() {
		var r UtilizationRow
		if err := rows.Scan(
			&r.VehicleID, &r.Plate, &r.VehicleType,
			&r.TotalTrips, &r.TotalDays, &r.WorkingDays, &r.UtilizationPct,
			&r.TotalRevenue, &r.TotalCost,
		); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}

// FuelEfficiency รายงานประสิทธิภาพน้ำมันต่อรถในช่วงวันที่กำหนด
func (q *ReportQuery) FuelEfficiency(ctx context.Context, shopID string, dateFrom, dateTo time.Time) ([]FuelEfficiencyRow, error) {
	sql := `
		SELECT
			v.id    AS vehicle_id,
			v.plate,
			COALESCE(SUM(e.fuel_liters), 0)   AS total_fuel_liters,
			COALESCE(SUM(e.amount), 0)         AS total_fuel_cost,
			COALESCE(SUM(t.distance_km), 0)    AS total_distance_km,
			CASE
				WHEN SUM(e.fuel_liters) > 0
				THEN ROUND(SUM(t.distance_km) / SUM(e.fuel_liters), 2)
				ELSE 0
			END AS km_per_liter,
			CASE
				WHEN SUM(t.distance_km) > 0
				THEN ROUND(SUM(e.amount) / SUM(t.distance_km), 2)
				ELSE 0
			END AS cost_per_km
		FROM fleet_vehicles v
		LEFT JOIN fleet_expenses e
		       ON e.vehicle_id = v.id
		      AND e.type = 'fuel'
		      AND e.recorded_at >= $2
		      AND e.recorded_at <= $3
		LEFT JOIN fleet_trips t
		       ON t.vehicle_id = v.id
		      AND t.planned_start >= $2
		      AND t.planned_start <= $3
		      AND t.status = 'completed'
		WHERE v.shop_id = $1
		  AND v.deleted_at IS NULL
		GROUP BY v.id, v.plate
		ORDER BY km_per_liter DESC
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, dateFrom, dateTo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []FuelEfficiencyRow
	for rows.Next() {
		var r FuelEfficiencyRow
		if err := rows.Scan(
			&r.VehicleID, &r.Plate,
			&r.TotalFuelLiters, &r.TotalFuelCost,
			&r.TotalDistanceKm,
			&r.KmPerLiter, &r.CostPerKm,
		); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}

// DriverPerformance รายงานผลงานคนขับ (leaderboard) ทั้งหมด
func (q *ReportQuery) DriverPerformance(ctx context.Context, shopID string) ([]DriverPerfRow, error) {
	sql := `
		SELECT
			d.id   AS driver_id,
			d.name,
			d.score,
			d.total_trips,
			d.on_time_rate,
			d.fuel_efficiency,
			d.customer_rating,
			COALESCE((
				SELECT SUM(revenue)
				FROM fleet_trips
				WHERE driver_id = d.id
				  AND DATE_TRUNC('month', planned_start) = DATE_TRUNC('month', CURRENT_DATE)
			), 0) AS total_revenue
		FROM fleet_drivers d
		WHERE d.shop_id = $1
		  AND d.status = 'active'
		  AND d.deleted_at IS NULL
		ORDER BY d.score DESC
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []DriverPerfRow
	for rows.Next() {
		var r DriverPerfRow
		if err := rows.Scan(
			&r.DriverID, &r.Name, &r.Score, &r.TotalTrips,
			&r.OnTimeRate, &r.FuelEfficiency, &r.CustomerRating,
			&r.TotalRevenue,
		); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}
