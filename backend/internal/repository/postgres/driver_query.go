package postgres

import (
	"context"
	"time"

	"bc-fleet/internal/database"
)

type DriverQuery struct {
	db *database.PostgresDB
}

func NewDriverQuery(db *database.PostgresDB) *DriverQuery {
	return &DriverQuery{db: db}
}

type DriverRow struct {
	ID                string    `json:"id"`
	ShopID            string    `json:"shop_id"`
	EmployeeID        *string   `json:"employee_id"`
	Name              string    `json:"name"`
	Nickname          *string   `json:"nickname"`
	Phone             *string   `json:"phone"`
	LicenseType       *string   `json:"license_type"`
	LicenseExpiry     *string   `json:"license_expiry"`
	EmploymentType    *string   `json:"employment_type"`
	Salary            *float64  `json:"salary"`
	DailyAllowance    *float64  `json:"daily_allowance"`
	TripBonus         *float64  `json:"trip_bonus"`
	Status            string    `json:"status"`
	AssignedVehicleID *string   `json:"assigned_vehicle_id"`
	Score             int       `json:"score"`
	TotalTrips        int       `json:"total_trips"`
	OnTimeRate        *float64  `json:"on_time_rate"`
	FuelEfficiency    *float64  `json:"fuel_efficiency"`
	CustomerRating    *float64  `json:"customer_rating"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type DriverScoreRow struct {
	ID             string   `json:"id"`
	Name           string   `json:"name"`
	Score          int      `json:"score"`
	TotalTrips     int      `json:"total_trips"`
	OnTimeRate     *float64 `json:"on_time_rate"`
	FuelEfficiency *float64 `json:"fuel_efficiency"`
	CustomerRating *float64 `json:"customer_rating"`
}

// List ดึงรายการคนขับ กรองตาม status พร้อม pagination
func (q *DriverQuery) List(ctx context.Context, shopID string, status string, page, limit int) ([]DriverRow, int, error) {
	offset := (page - 1) * limit

	sql := `
		SELECT
			id, shop_id, employee_id, name, nickname, phone,
			license_type, TO_CHAR(license_expiry, 'YYYY-MM-DD') AS license_expiry,
			employment_type, salary, daily_allowance, trip_bonus,
			status, assigned_vehicle_id, score, total_trips,
			on_time_rate, fuel_efficiency, customer_rating,
			created_at, updated_at,
			COUNT(*) OVER() AS total_count
		FROM fleet_drivers
		WHERE shop_id = $1
		  AND deleted_at IS NULL
		  AND ($2 = '' OR status = $2)
		ORDER BY name ASC
		LIMIT $3 OFFSET $4
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, status, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var drivers []DriverRow
	var total int
	for rows.Next() {
		var d DriverRow
		if err := rows.Scan(
			&d.ID, &d.ShopID, &d.EmployeeID, &d.Name, &d.Nickname, &d.Phone,
			&d.LicenseType, &d.LicenseExpiry,
			&d.EmploymentType, &d.Salary, &d.DailyAllowance, &d.TripBonus,
			&d.Status, &d.AssignedVehicleID, &d.Score, &d.TotalTrips,
			&d.OnTimeRate, &d.FuelEfficiency, &d.CustomerRating,
			&d.CreatedAt, &d.UpdatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		drivers = append(drivers, d)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return drivers, total, nil
}

// GetByID ดึงคนขับคนเดียวตาม ID
func (q *DriverQuery) GetByID(ctx context.Context, shopID, id string) (*DriverRow, error) {
	sql := `
		SELECT
			id, shop_id, employee_id, name, nickname, phone,
			license_type, TO_CHAR(license_expiry, 'YYYY-MM-DD') AS license_expiry,
			employment_type, salary, daily_allowance, trip_bonus,
			status, assigned_vehicle_id, score, total_trips,
			on_time_rate, fuel_efficiency, customer_rating,
			created_at, updated_at
		FROM fleet_drivers
		WHERE shop_id = $1 AND id = $2 AND deleted_at IS NULL
	`

	var d DriverRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&d.ID, &d.ShopID, &d.EmployeeID, &d.Name, &d.Nickname, &d.Phone,
		&d.LicenseType, &d.LicenseExpiry,
		&d.EmploymentType, &d.Salary, &d.DailyAllowance, &d.TripBonus,
		&d.Status, &d.AssignedVehicleID, &d.Score, &d.TotalTrips,
		&d.OnTimeRate, &d.FuelEfficiency, &d.CustomerRating,
		&d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

// GetScore ดึง KPI score ของคนขับ
func (q *DriverQuery) GetScore(ctx context.Context, shopID, id string) (*DriverScoreRow, error) {
	sql := `
		SELECT
			id, name, score, total_trips,
			on_time_rate, fuel_efficiency, customer_rating
		FROM fleet_drivers
		WHERE shop_id = $1 AND id = $2 AND deleted_at IS NULL
	`

	var s DriverScoreRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&s.ID, &s.Name, &s.Score, &s.TotalTrips,
		&s.OnTimeRate, &s.FuelEfficiency, &s.CustomerRating,
	)
	if err != nil {
		return nil, err
	}
	return &s, nil
}
