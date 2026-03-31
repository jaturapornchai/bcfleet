package postgres

import (
	"context"

	"sml-fleet/internal/database"
)

type DashboardQuery struct {
	db *database.PostgresDB
}

func NewDashboardQuery(db *database.PostgresDB) *DashboardQuery {
	return &DashboardQuery{db: db}
}

type DashboardSummary struct {
	ActiveVehicles        int `json:"active_vehicles"`
	VehiclesInMaintenance int `json:"vehicles_in_maintenance"`
	CriticalVehicles      int `json:"critical_vehicles"`
	WarningVehicles       int `json:"warning_vehicles"`
	ActiveDrivers         int `json:"active_drivers"`
	ActiveAlerts          int `json:"active_alerts"`
}

type TodayTripsRow struct {
	TotalTrips   int     `json:"total_trips"`
	Completed    int     `json:"completed"`
	InProgress   int     `json:"in_progress"`
	Pending      int     `json:"pending"`
	TotalRevenue float64 `json:"total_revenue"`
	TotalCost    float64 `json:"total_cost"`
	TotalProfit  float64 `json:"total_profit"`
}

type KPIRow struct {
	VehicleUtilizationRate float64 `json:"vehicle_utilization_rate"`
	OnTimeDeliveryRate     float64 `json:"on_time_delivery_rate"`
	AvgFuelEfficiency      float64 `json:"avg_fuel_efficiency"`
	AvgDriverScore         float64 `json:"avg_driver_score"`
	TotalTripsThisMonth    int     `json:"total_trips_this_month"`
	TotalRevenueThisMonth  float64 `json:"total_revenue_this_month"`
	TotalCostThisMonth     float64 `json:"total_cost_this_month"`
	ProfitMarginThisMonth  float64 `json:"profit_margin_this_month"`
}

// GetSummary ดึงสรุปภาพรวม fleet
func (q *DashboardQuery) GetSummary(ctx context.Context, shopID string) (*DashboardSummary, error) {
	sql := `
		SELECT
			COUNT(*) FILTER (WHERE status = 'active')                      AS active_vehicles,
			COUNT(*) FILTER (WHERE status = 'maintenance')                  AS vehicles_in_maintenance,
			COUNT(*) FILTER (WHERE health_status = 'red'  AND deleted_at IS NULL) AS critical_vehicles,
			COUNT(*) FILTER (WHERE health_status = 'yellow' AND deleted_at IS NULL) AS warning_vehicles
		FROM fleet_vehicles
		WHERE shop_id = $1 AND deleted_at IS NULL
	`

	var s DashboardSummary
	err := q.db.Pool().QueryRow(ctx, sql, shopID).Scan(
		&s.ActiveVehicles,
		&s.VehiclesInMaintenance,
		&s.CriticalVehicles,
		&s.WarningVehicles,
	)
	if err != nil {
		return nil, err
	}

	// Active drivers
	driverSQL := `
		SELECT COUNT(*) FROM fleet_drivers
		WHERE shop_id = $1 AND status = 'active' AND deleted_at IS NULL
	`
	if err := q.db.Pool().QueryRow(ctx, driverSQL, shopID).Scan(&s.ActiveDrivers); err != nil {
		return nil, err
	}

	// Active alerts
	alertSQL := `
		SELECT COUNT(*) FROM fleet_alerts
		WHERE shop_id = $1 AND status = 'active'
	`
	if err := q.db.Pool().QueryRow(ctx, alertSQL, shopID).Scan(&s.ActiveAlerts); err != nil {
		return nil, err
	}

	return &s, nil
}

// GetTodayTrips ดึงสถิติเที่ยววิ่งวันนี้
func (q *DashboardQuery) GetTodayTrips(ctx context.Context, shopID string) (*TodayTripsRow, error) {
	sql := `
		SELECT
			COUNT(*)                                                        AS total_trips,
			COUNT(*) FILTER (WHERE status = 'completed')                    AS completed,
			COUNT(*) FILTER (WHERE status IN ('started', 'delivering'))     AS in_progress,
			COUNT(*) FILTER (WHERE status = 'pending')                      AS pending,
			COALESCE(SUM(revenue), 0)                                       AS total_revenue,
			COALESCE(SUM(total_cost), 0)                                    AS total_cost,
			COALESCE(SUM(profit), 0)                                        AS total_profit
		FROM fleet_trips
		WHERE shop_id = $1
		  AND DATE(planned_start AT TIME ZONE 'Asia/Bangkok') = CURRENT_DATE
	`

	var t TodayTripsRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID).Scan(
		&t.TotalTrips,
		&t.Completed,
		&t.InProgress,
		&t.Pending,
		&t.TotalRevenue,
		&t.TotalCost,
		&t.TotalProfit,
	)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

// GetKPI ดึง KPI metrics ของเดือนปัจจุบัน
func (q *DashboardQuery) GetKPI(ctx context.Context, shopID string) (*KPIRow, error) {
	sql := `
		WITH monthly_trips AS (
			SELECT
				COUNT(*) AS total_trips,
				COALESCE(SUM(revenue), 0) AS total_revenue,
				COALESCE(SUM(total_cost), 0) AS total_cost,
				COALESCE(
					COUNT(*) FILTER (WHERE actual_end <= planned_end AND status = 'completed') * 1.0
					/ NULLIF(COUNT(*) FILTER (WHERE status = 'completed'), 0),
					0
				) AS on_time_rate
			FROM fleet_trips
			WHERE shop_id = $1
			  AND DATE_TRUNC('month', planned_start) = DATE_TRUNC('month', CURRENT_DATE)
		),
		vehicle_stats AS (
			SELECT
				COUNT(*) FILTER (WHERE status = 'active') AS total_active,
				COALESCE(
					COUNT(*) FILTER (WHERE status = 'active' AND id IN (
						SELECT DISTINCT vehicle_id FROM fleet_trips
						WHERE shop_id = $1
						  AND DATE_TRUNC('month', planned_start) = DATE_TRUNC('month', CURRENT_DATE)
						  AND vehicle_id IS NOT NULL
					)) * 1.0 / NULLIF(COUNT(*) FILTER (WHERE status = 'active'), 0),
					0
				) AS utilization_rate
			FROM fleet_vehicles
			WHERE shop_id = $1 AND deleted_at IS NULL
		),
		driver_stats AS (
			SELECT
				COALESCE(AVG(score), 0)           AS avg_score,
				COALESCE(AVG(fuel_efficiency), 0) AS avg_fuel_efficiency
			FROM fleet_drivers
			WHERE shop_id = $1 AND status = 'active' AND deleted_at IS NULL
		)
		SELECT
			vs.utilization_rate,
			mt.on_time_rate,
			ds.avg_fuel_efficiency,
			ds.avg_score,
			mt.total_trips,
			mt.total_revenue,
			mt.total_cost,
			CASE WHEN mt.total_revenue > 0 THEN (mt.total_revenue - mt.total_cost) / mt.total_revenue ELSE 0 END AS profit_margin
		FROM monthly_trips mt, vehicle_stats vs, driver_stats ds
	`

	var k KPIRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID).Scan(
		&k.VehicleUtilizationRate,
		&k.OnTimeDeliveryRate,
		&k.AvgFuelEfficiency,
		&k.AvgDriverScore,
		&k.TotalTripsThisMonth,
		&k.TotalRevenueThisMonth,
		&k.TotalCostThisMonth,
		&k.ProfitMarginThisMonth,
	)
	if err != nil {
		return nil, err
	}
	return &k, nil
}
