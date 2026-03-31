package postgres

import (
	"context"
	"time"

	"sml-fleet/internal/database"
)

type MaintenanceQuery struct {
	db *database.PostgresDB
}

func NewMaintenanceQuery(db *database.PostgresDB) *MaintenanceQuery {
	return &MaintenanceQuery{db: db}
}

type WorkOrderRow struct {
	ID                  string     `json:"id"`
	ShopID              string     `json:"shop_id"`
	WONo                *string    `json:"wo_no"`
	VehicleID           string     `json:"vehicle_id"`
	Type                *string    `json:"type"`
	Priority            *string    `json:"priority"`
	Status              *string    `json:"status"`
	ReportedBy          *string    `json:"reported_by"`
	Description         *string    `json:"description"`
	MileageAtReport     *int       `json:"mileage_at_report"`
	ServiceProviderType *string    `json:"service_provider_type"`
	ServiceProviderName *string    `json:"service_provider_name"`
	PartsCost           *float64   `json:"parts_cost"`
	LaborCost           *float64   `json:"labor_cost"`
	TotalCost           *float64   `json:"total_cost"`
	ApprovedBy          *string    `json:"approved_by"`
	ApprovedAt          *time.Time `json:"approved_at"`
	CompletedAt         *time.Time `json:"completed_at"`
	BCAccountSynced     bool       `json:"bc_account_synced"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

type MaintenanceDueRow struct {
	VehicleID           string  `json:"vehicle_id"`
	Plate               string  `json:"plate"`
	NextMaintenanceKm   *int    `json:"next_maintenance_km"`
	NextMaintenanceDate *string `json:"next_maintenance_date"`
	MileageKm           *int    `json:"mileage_km"`
	KmRemaining         *int    `json:"km_remaining"`
	DaysRemaining       *int    `json:"days_remaining"`
}

// ListWorkOrders ดึงรายการใบสั่งซ่อม กรองตาม status, vehicleID พร้อม pagination
func (q *MaintenanceQuery) ListWorkOrders(ctx context.Context, shopID string, status string, vehicleID string, page, limit int) ([]WorkOrderRow, int, error) {
	offset := (page - 1) * limit

	sql := `
		SELECT
			id, shop_id, wo_no, vehicle_id, type, priority, status,
			reported_by, description, mileage_at_report,
			service_provider_type, service_provider_name,
			parts_cost, labor_cost, total_cost,
			approved_by, approved_at, completed_at,
			bc_account_synced, created_at, updated_at,
			COUNT(*) OVER() AS total_count
		FROM fleet_work_orders
		WHERE shop_id = $1
		  AND ($2 = '' OR status = $2)
		  AND ($3 = '' OR vehicle_id = $3)
		ORDER BY created_at DESC
		LIMIT $4 OFFSET $5
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, status, vehicleID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var orders []WorkOrderRow
	var total int
	for rows.Next() {
		var w WorkOrderRow
		if err := rows.Scan(
			&w.ID, &w.ShopID, &w.WONo, &w.VehicleID, &w.Type, &w.Priority, &w.Status,
			&w.ReportedBy, &w.Description, &w.MileageAtReport,
			&w.ServiceProviderType, &w.ServiceProviderName,
			&w.PartsCost, &w.LaborCost, &w.TotalCost,
			&w.ApprovedBy, &w.ApprovedAt, &w.CompletedAt,
			&w.BCAccountSynced, &w.CreatedAt, &w.UpdatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		orders = append(orders, w)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return orders, total, nil
}

// GetWorkOrderByID ดึงใบสั่งซ่อมตาม ID
func (q *MaintenanceQuery) GetWorkOrderByID(ctx context.Context, shopID, id string) (*WorkOrderRow, error) {
	sql := `
		SELECT
			id, shop_id, wo_no, vehicle_id, type, priority, status,
			reported_by, description, mileage_at_report,
			service_provider_type, service_provider_name,
			parts_cost, labor_cost, total_cost,
			approved_by, approved_at, completed_at,
			bc_account_synced, created_at, updated_at
		FROM fleet_work_orders
		WHERE shop_id = $1 AND id = $2
	`

	var w WorkOrderRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&w.ID, &w.ShopID, &w.WONo, &w.VehicleID, &w.Type, &w.Priority, &w.Status,
		&w.ReportedBy, &w.Description, &w.MileageAtReport,
		&w.ServiceProviderType, &w.ServiceProviderName,
		&w.PartsCost, &w.LaborCost, &w.TotalCost,
		&w.ApprovedBy, &w.ApprovedAt, &w.CompletedAt,
		&w.BCAccountSynced, &w.CreatedAt, &w.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &w, nil
}

// GetDueSchedule ดึงรายการรถที่ใกล้ถึงกำหนดซ่อมบำรุง
func (q *MaintenanceQuery) GetDueSchedule(ctx context.Context, shopID string) ([]MaintenanceDueRow, error) {
	sql := `
		SELECT
			id AS vehicle_id,
			plate,
			next_maintenance_km,
			TO_CHAR(next_maintenance_date, 'YYYY-MM-DD') AS next_maintenance_date,
			mileage_km,
			CASE
				WHEN next_maintenance_km IS NOT NULL AND mileage_km IS NOT NULL
				THEN next_maintenance_km - mileage_km
				ELSE NULL
			END AS km_remaining,
			CASE
				WHEN next_maintenance_date IS NOT NULL
				THEN EXTRACT(DAY FROM next_maintenance_date - CURRENT_DATE)::INT
				ELSE NULL
			END AS days_remaining
		FROM fleet_vehicles
		WHERE shop_id = $1
		  AND deleted_at IS NULL
		  AND status = 'active'
		  AND (
		    (next_maintenance_km IS NOT NULL AND mileage_km IS NOT NULL AND next_maintenance_km - mileage_km <= 2000)
		    OR
		    (next_maintenance_date IS NOT NULL AND next_maintenance_date <= CURRENT_DATE + INTERVAL '30 days')
		  )
		ORDER BY days_remaining ASC NULLS LAST, km_remaining ASC NULLS LAST
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []MaintenanceDueRow
	for rows.Next() {
		var m MaintenanceDueRow
		if err := rows.Scan(
			&m.VehicleID, &m.Plate,
			&m.NextMaintenanceKm, &m.NextMaintenanceDate,
			&m.MileageKm, &m.KmRemaining, &m.DaysRemaining,
		); err != nil {
			return nil, err
		}
		result = append(result, m)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}
