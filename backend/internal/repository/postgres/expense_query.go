package postgres

import (
	"context"
	"time"

	"bc-fleet/internal/database"
)

type ExpenseQuery struct {
	db *database.PostgresDB
}

func NewExpenseQuery(db *database.PostgresDB) *ExpenseQuery {
	return &ExpenseQuery{db: db}
}

type ExpenseRow struct {
	ID                string     `json:"id"`
	ShopID            string     `json:"shop_id"`
	TripID            *string    `json:"trip_id"`
	VehicleID         *string    `json:"vehicle_id"`
	DriverID          *string    `json:"driver_id"`
	Type              string     `json:"type"`
	Description       *string    `json:"description"`
	Amount            float64    `json:"amount"`
	FuelLiters        *float64   `json:"fuel_liters"`
	FuelPricePerLiter *float64   `json:"fuel_price_per_liter"`
	OdometerKm        *int       `json:"odometer_km"`
	ReceiptURL        *string    `json:"receipt_url"`
	BCAccountSynced   bool       `json:"bc_account_synced"`
	RecordedAt        *time.Time `json:"recorded_at"`
	CreatedAt         time.Time  `json:"created_at"`
}

type FuelReportRow struct {
	TotalLiters       float64 `json:"total_liters"`
	TotalAmount       float64 `json:"total_amount"`
	AvgPricePerLiter  float64 `json:"avg_price_per_liter"`
	TotalTransactions int     `json:"total_transactions"`
}

type PLRow struct {
	VehicleID    string  `json:"vehicle_id"`
	TotalRevenue float64 `json:"total_revenue"`
	FuelCost     float64 `json:"fuel_cost"`
	TollCost     float64 `json:"toll_cost"`
	OtherCost    float64 `json:"other_cost"`
	RepairCost   float64 `json:"repair_cost"`
	TotalCost    float64 `json:"total_cost"`
	Profit       float64 `json:"profit"`
	TripCount    int     `json:"trip_count"`
}

// List ดึงรายการค่าใช้จ่าย กรองตาม vehicleID, type, ช่วงวันที่ พร้อม pagination
func (q *ExpenseQuery) List(
	ctx context.Context,
	shopID string,
	vehicleID string,
	expType string,
	dateFrom, dateTo *time.Time,
	page, limit int,
) ([]ExpenseRow, int, error) {
	offset := (page - 1) * limit

	sql := `
		SELECT
			id, shop_id, trip_id, vehicle_id, driver_id,
			type, description, amount,
			fuel_liters, fuel_price_per_liter, odometer_km,
			receipt_url, bc_account_synced,
			recorded_at, created_at,
			COUNT(*) OVER() AS total_count
		FROM fleet_expenses
		WHERE shop_id = $1
		  AND ($2 = '' OR vehicle_id = $2)
		  AND ($3 = '' OR type = $3)
		  AND ($4::TIMESTAMPTZ IS NULL OR recorded_at >= $4)
		  AND ($5::TIMESTAMPTZ IS NULL OR recorded_at <= $5)
		ORDER BY recorded_at DESC
		LIMIT $6 OFFSET $7
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, vehicleID, expType, dateFrom, dateTo, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var expenses []ExpenseRow
	var total int
	for rows.Next() {
		var e ExpenseRow
		if err := rows.Scan(
			&e.ID, &e.ShopID, &e.TripID, &e.VehicleID, &e.DriverID,
			&e.Type, &e.Description, &e.Amount,
			&e.FuelLiters, &e.FuelPricePerLiter, &e.OdometerKm,
			&e.ReceiptURL, &e.BCAccountSynced,
			&e.RecordedAt, &e.CreatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		expenses = append(expenses, e)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return expenses, total, nil
}

// GetFuelReport สรุปรายงานน้ำมันในช่วงวันที่กำหนด
func (q *ExpenseQuery) GetFuelReport(ctx context.Context, shopID string, dateFrom, dateTo time.Time) (*FuelReportRow, error) {
	sql := `
		SELECT
			COALESCE(SUM(fuel_liters), 0)                                              AS total_liters,
			COALESCE(SUM(amount), 0)                                                   AS total_amount,
			COALESCE(AVG(fuel_price_per_liter), 0)                                     AS avg_price_per_liter,
			COUNT(*)                                                                    AS total_transactions
		FROM fleet_expenses
		WHERE shop_id = $1
		  AND type = 'fuel'
		  AND recorded_at >= $2
		  AND recorded_at <= $3
	`

	var r FuelReportRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, dateFrom, dateTo).Scan(
		&r.TotalLiters, &r.TotalAmount, &r.AvgPricePerLiter, &r.TotalTransactions,
	)
	if err != nil {
		return nil, err
	}
	return &r, nil
}

// GetPLByVehicle คำนวณ P&L ต่อรถในช่วงวันที่กำหนด
func (q *ExpenseQuery) GetPLByVehicle(ctx context.Context, shopID, vehicleID string, dateFrom, dateTo time.Time) (*PLRow, error) {
	sql := `
		SELECT
			$2::TEXT                                                                          AS vehicle_id,
			COALESCE((
				SELECT SUM(revenue) FROM fleet_trips
				WHERE shop_id = $1 AND vehicle_id = $2
				  AND planned_start >= $3 AND planned_start <= $4
			), 0) AS total_revenue,
			COALESCE(SUM(amount) FILTER (WHERE type = 'fuel'),   0) AS fuel_cost,
			COALESCE(SUM(amount) FILTER (WHERE type = 'toll'),   0) AS toll_cost,
			COALESCE(SUM(amount) FILTER (WHERE type NOT IN ('fuel','toll','repair')), 0) AS other_cost,
			COALESCE(SUM(amount) FILTER (WHERE type = 'repair'), 0) AS repair_cost,
			COALESCE(SUM(amount), 0)                                AS total_cost,
			0::NUMERIC                                              AS profit,
			COALESCE((
				SELECT COUNT(*) FROM fleet_trips
				WHERE shop_id = $1 AND vehicle_id = $2
				  AND planned_start >= $3 AND planned_start <= $4
			), 0)::INT AS trip_count
		FROM fleet_expenses
		WHERE shop_id = $1
		  AND vehicle_id = $2
		  AND recorded_at >= $3
		  AND recorded_at <= $4
	`

	var r PLRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, vehicleID, dateFrom, dateTo).Scan(
		&r.VehicleID,
		&r.TotalRevenue,
		&r.FuelCost, &r.TollCost, &r.OtherCost, &r.RepairCost,
		&r.TotalCost,
		&r.Profit,
		&r.TripCount,
	)
	if err != nil {
		return nil, err
	}
	r.Profit = r.TotalRevenue - r.TotalCost
	return &r, nil
}
