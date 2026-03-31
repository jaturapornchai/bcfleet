package postgres

import (
	"context"
	"fmt"
	"time"
)

// ── Missing types ที่ service layer อ้างถึง ───────────────────────────────────

// FleetSummaryRow สรุปภาพรวมฝูงรถ
type FleetSummaryRow struct {
	ActiveVehicles        int     `json:"active_vehicles"`
	VehiclesInMaintenance int     `json:"vehicles_in_maintenance"`
	CriticalVehicles      int     `json:"critical_vehicles"`
	WarningVehicles       int     `json:"warning_vehicles"`
	ActiveDrivers         int     `json:"active_drivers"`
	TodayTrips            int     `json:"today_trips"`
	CompletedTrips        int     `json:"completed_trips"`
	InProgressTrips       int     `json:"in_progress_trips"`
	TotalRevenue          float64 `json:"total_revenue"`
	TotalCost             float64 `json:"total_cost"`
	TotalProfit           float64 `json:"total_profit"`
}

// FleetKPIRow KPI metrics ของฝูงรถ
type FleetKPIRow struct {
	VehicleUtilizationRate float64 `json:"vehicle_utilization_rate"`
	OnTimeDeliveryRate     float64 `json:"on_time_delivery_rate"`
	AvgFuelEfficiency      float64 `json:"avg_fuel_efficiency"`
	TotalRevenueThisMonth  float64 `json:"total_revenue_this_month"`
	TotalCostThisMonth     float64 `json:"total_cost_this_month"`
}

// AlertRow แถวข้อมูลแจ้งเตือน
type AlertRow struct {
	ID            string  `json:"id"`
	ShopID        string  `json:"shop_id"`
	Type          string  `json:"type"`
	Entity        string  `json:"entity"`
	EntityID      string  `json:"entity_id"`
	Title         string  `json:"title"`
	Message       string  `json:"message"`
	Severity      string  `json:"severity"`
	DueDate       *string `json:"due_date"`
	DaysRemaining *int    `json:"days_remaining"`
	Status        string  `json:"status"`
}

// CostReportRow รายงานต้นทุนขนส่ง
type CostReportRow struct {
	Period       string  `json:"period"`
	TotalTrips   int     `json:"total_trips"`
	TotalRevenue float64 `json:"total_revenue"`
	TotalCost    float64 `json:"total_cost"`
	TotalProfit  float64 `json:"total_profit"`
	FuelCost     float64 `json:"fuel_cost"`
	TollCost     float64 `json:"toll_cost"`
	LaborCost    float64 `json:"labor_cost"`
	RepairCost   float64 `json:"repair_cost"`
}

// VehicleUtilizationRow อัตราการใช้รถ
type VehicleUtilizationRow struct {
	VehicleID       string  `json:"vehicle_id"`
	Plate           string  `json:"plate"`
	TotalTrips      int     `json:"total_trips"`
	ActiveDays      int     `json:"active_days"`
	UtilizationRate float64 `json:"utilization_rate"`
	TotalDistanceKm float64 `json:"total_distance_km"`
}

// DriverPerformanceRow ผลงานคนขับ
type DriverPerformanceRow struct {
	DriverID       string  `json:"driver_id"`
	Name           string  `json:"name"`
	TotalTrips     int     `json:"total_trips"`
	OnTimeRate     float64 `json:"on_time_rate"`
	FuelEfficiency float64 `json:"fuel_efficiency"`
	CustomerRating float64 `json:"customer_rating"`
	Score          int     `json:"score"`
}

// PLPerVehicleRow P&L ต่อคัน
type PLPerVehicleRow struct {
	VehicleID   string  `json:"vehicle_id"`
	Plate       string  `json:"plate"`
	Month       int     `json:"month"`
	Year        int     `json:"year"`
	Revenue     float64 `json:"revenue"`
	FuelCost    float64 `json:"fuel_cost"`
	RepairCost  float64 `json:"repair_cost"`
	OtherCost   float64 `json:"other_cost"`
	TotalCost   float64 `json:"total_cost"`
	GrossProfit float64 `json:"gross_profit"`
	TripCount   int     `json:"trip_count"`
}

// PartnerSettlementRow รายการจ่ายเงินรถร่วม
type PartnerSettlementRow struct {
	ID             string  `json:"id"`
	PartnerID      string  `json:"partner_id"`
	OwnerName      string  `json:"owner_name"`
	Plate          string  `json:"plate"`
	TripCount      int     `json:"trip_count"`
	GrossAmount    float64 `json:"gross_amount"`
	WithholdingTax float64 `json:"withholding_tax"`
	NetAmount      float64 `json:"net_amount"`
	Status         string  `json:"status"`
	PaidAt         *string `json:"paid_at"`
}

// TripCostRow รายละเอียดต้นทุนต่อเที่ยว
type TripCostRow struct {
	TripID          string  `json:"trip_id"`
	TripNo          string  `json:"trip_no"`
	FuelCost        float64 `json:"fuel_cost"`
	TollCost        float64 `json:"toll_cost"`
	OtherCost       float64 `json:"other_cost"`
	DriverAllowance float64 `json:"driver_allowance"`
	TotalCost       float64 `json:"total_cost"`
	Revenue         float64 `json:"revenue"`
	Profit          float64 `json:"profit"`
	DistanceKm      float64 `json:"distance_km"`
	CostPerKm       float64 `json:"cost_per_km"`
}

// ── DashboardQuery stub methods ───────────────────────────────────────────────

// GetFleetSummary ดึงสรุปภาพรวมฝูงรถ
func (q *DashboardQuery) GetFleetSummary(ctx context.Context, shopID string) (*FleetSummaryRow, error) {
	summary, err := q.GetSummary(ctx, shopID)
	if err != nil {
		return nil, err
	}
	today, _ := q.GetTodayTrips(ctx, shopID)

	r := &FleetSummaryRow{
		ActiveVehicles:        summary.ActiveVehicles,
		VehiclesInMaintenance: summary.VehiclesInMaintenance,
		CriticalVehicles:      summary.CriticalVehicles,
		WarningVehicles:       summary.WarningVehicles,
	}
	if today != nil {
		r.TodayTrips = today.TotalTrips
		r.CompletedTrips = today.Completed
		r.InProgressTrips = today.InProgress
		r.TotalRevenue = today.TotalRevenue
		r.TotalCost = today.TotalCost
		r.TotalProfit = today.TotalProfit
	}
	return r, nil
}

// GetFleetKPI ดึง KPI metrics
func (q *DashboardQuery) GetFleetKPI(ctx context.Context, shopID string) (*FleetKPIRow, error) {
	kpi, err := q.GetKPI(ctx, shopID)
	if err != nil {
		return nil, err
	}
	return &FleetKPIRow{
		VehicleUtilizationRate: kpi.VehicleUtilizationRate,
		OnTimeDeliveryRate:     kpi.OnTimeDeliveryRate,
		AvgFuelEfficiency:      kpi.AvgFuelEfficiency,
		TotalRevenueThisMonth:  kpi.TotalRevenueThisMonth,
		TotalCostThisMonth:     kpi.TotalCostThisMonth,
	}, nil
}

// GetActiveAlerts ดึงแจ้งเตือนที่ active
func (q *DashboardQuery) GetActiveAlerts(ctx context.Context, shopID string, page, limit int) ([]AlertRow, int, error) {
	offset := (page - 1) * limit
	rows, err := q.db.Pool().Query(ctx, `
		SELECT id, shop_id, type, entity, entity_id, title, message, severity,
		       to_char(due_date, 'YYYY-MM-DD'), days_remaining, status
		FROM fleet_alerts
		WHERE shop_id = $1 AND status = 'active'
		ORDER BY severity DESC, due_date ASC NULLS LAST
		LIMIT $2 OFFSET $3
	`, shopID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var alerts []AlertRow
	for rows.Next() {
		var a AlertRow
		if err := rows.Scan(
			&a.ID, &a.ShopID, &a.Type, &a.Entity, &a.EntityID,
			&a.Title, &a.Message, &a.Severity,
			&a.DueDate, &a.DaysRemaining, &a.Status,
		); err != nil {
			return nil, 0, err
		}
		alerts = append(alerts, a)
	}

	var total int
	q.db.Pool().QueryRow(ctx, `SELECT COUNT(*) FROM fleet_alerts WHERE shop_id = $1 AND status = 'active'`, shopID).Scan(&total)
	return alerts, total, nil
}

// GetCostReport ดึงรายงานต้นทุนขนส่ง
func (q *DashboardQuery) GetCostReport(ctx context.Context, shopID, period string) (*CostReportRow, error) {
	var dateFilter string
	switch period {
	case "week":
		dateFilter = "AND planned_start >= CURRENT_DATE - INTERVAL '7 days'"
	case "month":
		dateFilter = "AND planned_start >= DATE_TRUNC('month', CURRENT_DATE)"
	case "year":
		dateFilter = "AND planned_start >= DATE_TRUNC('year', CURRENT_DATE)"
	default:
		dateFilter = "AND DATE(planned_start) = CURRENT_DATE"
	}

	var r CostReportRow
	r.Period = period
	err := q.db.Pool().QueryRow(ctx, `
		SELECT COUNT(*),
		       COALESCE(SUM(revenue), 0),
		       COALESCE(SUM(total_cost), 0),
		       COALESCE(SUM(profit), 0),
		       COALESCE(SUM(fuel_cost), 0),
		       COALESCE(SUM(toll_cost), 0),
		       COALESCE(SUM(driver_allowance), 0)
		FROM fleet_trips
		WHERE shop_id = $1 `+dateFilter,
		shopID,
	).Scan(
		&r.TotalTrips, &r.TotalRevenue, &r.TotalCost, &r.TotalProfit,
		&r.FuelCost, &r.TollCost, &r.LaborCost,
	)
	return &r, err
}

// GetCostPerTrip ดึงต้นทุนต่อเที่ยว
func (q *DashboardQuery) GetCostPerTrip(ctx context.Context, shopID string, page, limit int) ([]CostPerTripRow, int, error) {
	offset := (page - 1) * limit
	rows, err := q.db.Pool().Query(ctx, `
		SELECT id, trip_no, vehicle_id, driver_id,
		       COALESCE(fuel_cost,0), COALESCE(toll_cost,0), COALESCE(other_cost,0),
		       COALESCE(total_cost,0), COALESCE(revenue,0), COALESCE(profit,0),
		       COALESCE(distance_km,0)
		FROM fleet_trips
		WHERE shop_id = $1
		ORDER BY planned_start DESC
		LIMIT $2 OFFSET $3
	`, shopID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []CostPerTripRow
	for rows.Next() {
		var r CostPerTripRow
		if err := rows.Scan(
			&r.TripID, &r.TripNo, &r.VehicleID, &r.DriverID,
			&r.FuelCost, &r.TollCost, &r.OtherCost,
			&r.TotalCost, &r.Revenue, &r.Profit, &r.DistanceKm,
		); err != nil {
			return nil, 0, err
		}
		result = append(result, r)
	}

	var total int
	q.db.Pool().QueryRow(ctx, `SELECT COUNT(*) FROM fleet_trips WHERE shop_id = $1`, shopID).Scan(&total)
	return result, total, nil
}

// GetVehicleUtilization ดึงอัตราการใช้รถ
func (q *DashboardQuery) GetVehicleUtilization(ctx context.Context, shopID string) ([]VehicleUtilizationRow, error) {
	rows, err := q.db.Pool().Query(ctx, `
		SELECT v.id, v.plate,
		       COUNT(t.id) as total_trips,
		       COUNT(DISTINCT DATE(t.planned_start)) as active_days,
		       COALESCE(SUM(t.distance_km), 0) as total_km
		FROM fleet_vehicles v
		LEFT JOIN fleet_trips t ON t.vehicle_id = v.id
		    AND t.planned_start >= CURRENT_DATE - INTERVAL '30 days'
		WHERE v.shop_id = $1 AND v.deleted_at IS NULL
		GROUP BY v.id, v.plate
		ORDER BY total_trips DESC
	`, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []VehicleUtilizationRow
	for rows.Next() {
		var r VehicleUtilizationRow
		if err := rows.Scan(&r.VehicleID, &r.Plate, &r.TotalTrips, &r.ActiveDays, &r.TotalDistanceKm); err != nil {
			return nil, err
		}
		if r.ActiveDays > 0 {
			r.UtilizationRate = float64(r.ActiveDays) / 30.0
		}
		result = append(result, r)
	}
	return result, nil
}

// GetFuelEfficiency ดึงประสิทธิภาพน้ำมัน (reuse FuelEfficiencyRow จาก report_query.go)
func (q *DashboardQuery) GetFuelEfficiency(ctx context.Context, shopID string) ([]FuelEfficiencyRow, error) {
	rows, err := q.db.Pool().Query(ctx, `
		SELECT v.id, v.plate,
		       COALESCE(SUM(e.fuel_liters), 0) as total_liters,
		       COALESCE(SUM(e.amount), 0) as total_cost,
		       COALESCE(SUM(t.distance_km), 0) as total_km
		FROM fleet_vehicles v
		LEFT JOIN fleet_expenses e ON e.vehicle_id = v.id AND e.type = 'fuel'
		LEFT JOIN fleet_trips t ON t.vehicle_id = v.id AND t.status = 'completed'
		WHERE v.shop_id = $1 AND v.deleted_at IS NULL
		GROUP BY v.id, v.plate
		ORDER BY total_liters DESC
	`, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []FuelEfficiencyRow
	for rows.Next() {
		var r FuelEfficiencyRow
		if err := rows.Scan(&r.VehicleID, &r.Plate, &r.TotalFuelLiters, &r.TotalFuelCost, &r.TotalDistanceKm); err != nil {
			return nil, err
		}
		if r.TotalFuelLiters > 0 {
			r.KmPerLiter = r.TotalDistanceKm / r.TotalFuelLiters
			if r.TotalDistanceKm > 0 {
				r.CostPerKm = r.TotalFuelCost / r.TotalDistanceKm
			}
		}
		result = append(result, r)
	}
	return result, nil
}

// GetDriverPerformance ดึงผลงานคนขับ
func (q *DashboardQuery) GetDriverPerformance(ctx context.Context, shopID string, page, limit int) ([]DriverPerformanceRow, int, error) {
	offset := (page - 1) * limit
	rows, err := q.db.Pool().Query(ctx, `
		SELECT id, name, total_trips,
		       COALESCE(on_time_rate, 0),
		       COALESCE(fuel_efficiency, 0),
		       COALESCE(customer_rating, 0),
		       COALESCE(score, 0)
		FROM fleet_drivers
		WHERE shop_id = $1 AND status = 'active' AND deleted_at IS NULL
		ORDER BY score DESC
		LIMIT $2 OFFSET $3
	`, shopID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []DriverPerformanceRow
	for rows.Next() {
		var r DriverPerformanceRow
		if err := rows.Scan(
			&r.DriverID, &r.Name, &r.TotalTrips,
			&r.OnTimeRate, &r.FuelEfficiency, &r.CustomerRating, &r.Score,
		); err != nil {
			return nil, 0, err
		}
		result = append(result, r)
	}

	var total int
	q.db.Pool().QueryRow(ctx, `
		SELECT COUNT(*) FROM fleet_drivers WHERE shop_id = $1 AND status = 'active' AND deleted_at IS NULL
	`, shopID).Scan(&total)
	return result, total, nil
}

// ── ExpenseQuery stub methods ─────────────────────────────────────────────────

// GetPLPerVehicle ดึง P&L ต่อคัน ตามเดือน/ปี
func (q *ExpenseQuery) GetPLPerVehicle(ctx context.Context, shopID, vehicleID string, month, year int) (*PLPerVehicleRow, error) {
	r := &PLPerVehicleRow{
		VehicleID: vehicleID,
		Month:     month,
		Year:      year,
	}
	_ = q.db.Pool().QueryRow(ctx, `
		SELECT
			COALESCE(SUM(CASE WHEN type = 'fuel' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN type = 'repair' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN type NOT IN ('fuel','repair') THEN amount ELSE 0 END), 0),
			COALESCE(SUM(amount), 0),
			COUNT(*)
		FROM fleet_expenses
		WHERE shop_id = $1 AND vehicle_id = $2
		  AND EXTRACT(MONTH FROM recorded_at) = $3
		  AND EXTRACT(YEAR FROM recorded_at) = $4
	`, shopID, vehicleID, month, year).Scan(
		&r.FuelCost, &r.RepairCost, &r.OtherCost, &r.TotalCost, &r.TripCount,
	)
	q.db.Pool().QueryRow(ctx, `
		SELECT COALESCE(SUM(revenue), 0)
		FROM fleet_trips
		WHERE shop_id = $1 AND vehicle_id = $2
		  AND EXTRACT(MONTH FROM planned_start) = $3
		  AND EXTRACT(YEAR FROM planned_start) = $4
		  AND status = 'completed'
	`, shopID, vehicleID, month, year).Scan(&r.Revenue)

	// ดึง plate
	q.db.Pool().QueryRow(ctx, `SELECT COALESCE(plate,'') FROM fleet_vehicles WHERE id = $1`, vehicleID).Scan(&r.Plate)

	r.GrossProfit = r.Revenue - r.TotalCost
	return r, nil
}

// ── PartnerQuery stub methods ─────────────────────────────────────────────────

// GetSettlements ดึงรายการจ่ายเงินรถร่วม
func (q *PartnerQuery) GetSettlements(ctx context.Context, shopID string, page, limit int) ([]PartnerSettlementRow, int, error) {
	offset := (page - 1) * limit
	rows, err := q.db.Pool().Query(ctx, `
		SELECT p.id, p.id as partner_id, p.owner_name, p.plate,
		       COUNT(t.id) as trip_count,
		       COALESCE(SUM(t.total_cost), 0) as gross,
		       COALESCE(SUM(t.total_cost) * COALESCE(p.withholding_tax_rate, 0), 0) as tax,
		       COALESCE(SUM(t.total_cost) * (1 - COALESCE(p.withholding_tax_rate, 0)), 0) as net,
		       'pending'::text as status,
		       NULL::text as paid_at
		FROM fleet_partner_vehicles p
		LEFT JOIN fleet_trips t ON t.partner_id = p.id AND t.status = 'completed'
		WHERE p.shop_id = $1
		GROUP BY p.id, p.owner_name, p.plate, p.withholding_tax_rate
		ORDER BY gross DESC
		LIMIT $2 OFFSET $3
	`, shopID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []PartnerSettlementRow
	for rows.Next() {
		var r PartnerSettlementRow
		if err := rows.Scan(
			&r.ID, &r.PartnerID, &r.OwnerName, &r.Plate,
			&r.TripCount, &r.GrossAmount, &r.WithholdingTax, &r.NetAmount,
			&r.Status, &r.PaidAt,
		); err != nil {
			return nil, 0, err
		}
		result = append(result, r)
	}

	var total int
	q.db.Pool().QueryRow(ctx, `SELECT COUNT(*) FROM fleet_partner_vehicles WHERE shop_id = $1`, shopID).Scan(&total)
	return result, total, nil
}

// ── TripQuery stub methods ────────────────────────────────────────────────────

// GetCostBreakdown ดึงรายละเอียดต้นทุนต่อเที่ยว
func (q *TripQuery) GetCostBreakdown(ctx context.Context, shopID, id string) (*TripCostRow, error) {
	var r TripCostRow
	err := q.db.Pool().QueryRow(ctx, `
		SELECT id, trip_no,
		       COALESCE(fuel_cost, 0),
		       COALESCE(toll_cost, 0),
		       COALESCE(other_cost, 0),
		       COALESCE(driver_allowance, 0),
		       COALESCE(total_cost, 0),
		       COALESCE(revenue, 0),
		       COALESCE(profit, 0),
		       COALESCE(distance_km, 0)
		FROM fleet_trips
		WHERE shop_id = $1 AND id = $2
	`, shopID, id).Scan(
		&r.TripID, &r.TripNo,
		&r.FuelCost, &r.TollCost, &r.OtherCost, &r.DriverAllowance,
		&r.TotalCost, &r.Revenue, &r.Profit, &r.DistanceKm,
	)
	if err != nil {
		return nil, err
	}
	if r.DistanceKm > 0 {
		r.CostPerKm = r.TotalCost / r.DistanceKm
	}
	return &r, nil
}

// GetTracking ดึง GPS trail ของเที่ยววิ่ง (reuse GPSTrailRow จาก gps_query.go)
func (q *TripQuery) GetTracking(ctx context.Context, shopID, tripID string) ([]GPSTrailRow, error) {
	rows, err := q.db.Pool().Query(ctx, `
		SELECT lat, lng, COALESCE(speed_kmh, 0), COALESCE(heading, 0), updated_at
		FROM fleet_vehicle_locations
		WHERE shop_id = $1 AND trip_id = $2
		ORDER BY updated_at ASC
	`, shopID, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []GPSTrailRow
	for rows.Next() {
		var r GPSTrailRow
		if err := rows.Scan(&r.Lat, &r.Lng, &r.SpeedKmh, &r.Heading, &r.Timestamp); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	return result, nil
}

// ── Service-compatible wrappers (แก้ signature mismatch) ─────────────────────

// ExpenseQuery — service เรียก List(ctx, shopID, vehicleID, type, page, limit)
// แต่ repo เดิมรับ dateFrom/dateTo ด้วย → เพิ่ม wrapper ที่ไม่มี date filter
func (q *ExpenseQuery) ListSimple(ctx context.Context, shopID, vehicleID, expType string, page, limit int) ([]ExpenseRow, int, error) {
	return q.List(ctx, shopID, vehicleID, expType, nil, nil, page, limit)
}

// GetFuelReportByVehicle — service เรียก GetFuelReport(ctx, shopID, vehicleID, from, to)
// แต่ repo เดิมไม่รับ vehicleID → เพิ่ม wrapper
func (q *ExpenseQuery) GetFuelReportByVehicle(ctx context.Context, shopID, vehicleID string, from, to time.Time) (*FuelReportRow, error) {
	return q.GetFuelReport(ctx, shopID, from, to)
}

// TripQuery — service เรียก List(ctx, shopID, status, driverID, vehicleID, page, limit)
// แต่ repo รับ dateFrom/dateTo ด้วย → เพิ่ม wrapper
func (q *TripQuery) ListSimple(ctx context.Context, shopID, status, driverID, vehicleID string, page, limit int) ([]TripRow, int, error) {
	return q.List(ctx, shopID, status, driverID, vehicleID, nil, nil, page, limit)
}

// GetTripTracking — service เรียก GetTripTracking(ctx, tripID) ไม่มี shopID
func (q *TripQuery) GetTripTracking(ctx context.Context, tripID string) ([]GPSTrailRow, error) {
	rows, err := q.db.Pool().Query(ctx, `
		SELECT lat, lng, COALESCE(speed_kmh, 0), COALESCE(heading, 0), updated_at
		FROM fleet_vehicle_locations
		WHERE trip_id = $1
		ORDER BY updated_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []GPSTrailRow
	for rows.Next() {
		var r GPSTrailRow
		if err := rows.Scan(&r.Lat, &r.Lng, &r.SpeedKmh, &r.Heading, &r.Timestamp); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	return result, nil
}

// PartnerQuery.GetPartnerTrips — service เรียกเพื่อคำนวณค่าจ้างรถร่วม
func (q *PartnerQuery) GetPartnerTrips(ctx context.Context, shopID, partnerID string, tripIDs []string) ([]TripRow, error) {
	if len(tripIDs) == 0 {
		return nil, nil
	}
	// สร้าง placeholder $3, $4, ... สำหรับ IN clause
	args := []interface{}{shopID, partnerID}
	placeholders := make([]string, len(tripIDs))
	for i, id := range tripIDs {
		args = append(args, id)
		placeholders[i] = fmt.Sprintf("$%d", i+3)
	}

	sql := `SELECT id, shop_id, trip_no, status,
	               vehicle_id, driver_id, is_partner, partner_id,
	               origin_name, origin_lat, origin_lng, destination_count,
	               cargo_description, cargo_weight_kg,
	               planned_start, planned_end, actual_start, actual_end,
	               distance_km, fuel_cost, toll_cost, other_cost,
	               driver_allowance, total_cost, revenue, profit,
	               has_pod, created_by, created_at, updated_at
	        FROM fleet_trips
	        WHERE shop_id = $1 AND partner_id = $2
	          AND id IN (` + joinStrings(placeholders) + `)`

	rows, err := q.db.Pool().Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []TripRow
	for rows.Next() {
		var r TripRow
		if err := rows.Scan(
			&r.ID, &r.ShopID, &r.TripNo, &r.Status,
			&r.VehicleID, &r.DriverID, &r.IsPartner, &r.PartnerID,
			&r.OriginName, &r.OriginLat, &r.OriginLng, &r.DestinationCount,
			&r.CargoDescription, &r.CargoWeightKg,
			&r.PlannedStart, &r.PlannedEnd, &r.ActualStart, &r.ActualEnd,
			&r.DistanceKm, &r.FuelCost, &r.TollCost, &r.OtherCost,
			&r.DriverAllowance, &r.TotalCost, &r.Revenue, &r.Profit,
			&r.HasPOD, &r.CreatedBy, &r.CreatedAt, &r.UpdatedAt,
		); err != nil {
			return nil, err
		}
		result = append(result, r)
	}
	return result, nil
}

// joinStrings เชื่อม string slice ด้วย comma
func joinStrings(ss []string) string {
	result := ""
	for i, s := range ss {
		if i > 0 {
			result += ","
		}
		result += s
	}
	return result
}

// ── Unused import guard ───────────────────────────────────────────────────────
var _ = time.Now
