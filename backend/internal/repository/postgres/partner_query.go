package postgres

import (
	"context"
	"time"

	"bc-fleet/internal/database"
)

type PartnerQuery struct {
	db *database.PostgresDB
}

func NewPartnerQuery(db *database.PostgresDB) *PartnerQuery {
	return &PartnerQuery{db: db}
}

type PartnerRow struct {
	ID                  string    `json:"id"`
	ShopID              string    `json:"shop_id"`
	OwnerName           *string   `json:"owner_name"`
	OwnerCompany        *string   `json:"owner_company"`
	OwnerPhone          *string   `json:"owner_phone"`
	OwnerTaxID          *string   `json:"owner_tax_id"`
	Plate               *string   `json:"plate"`
	VehicleType         *string   `json:"vehicle_type"`
	MaxWeightKg         *int      `json:"max_weight_kg"`
	PricingModel        *string   `json:"pricing_model"`
	BaseRate            *float64  `json:"base_rate"`
	PerKmRate           *float64  `json:"per_km_rate"`
	Rating              *float64  `json:"rating"`
	TotalTrips          int       `json:"total_trips"`
	Status              string    `json:"status"`
	WithholdingTaxRate  *float64  `json:"withholding_tax_rate"`
	BCAccountCreditorID *string   `json:"bc_account_creditor_id"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
}

// List ดึงรายการรถร่วม กรองตาม status พร้อม pagination
func (q *PartnerQuery) List(ctx context.Context, shopID string, status string, page, limit int) ([]PartnerRow, int, error) {
	offset := (page - 1) * limit

	sql := `
		SELECT
			id, shop_id, owner_name, owner_company, owner_phone, owner_tax_id,
			plate, vehicle_type, max_weight_kg,
			pricing_model, base_rate, per_km_rate,
			rating, total_trips, status,
			withholding_tax_rate, bc_account_creditor_id,
			created_at, updated_at,
			COUNT(*) OVER() AS total_count
		FROM fleet_partner_vehicles
		WHERE shop_id = $1
		  AND ($2 = '' OR status = $2)
		ORDER BY owner_name ASC
		LIMIT $3 OFFSET $4
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, status, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var partners []PartnerRow
	var total int
	for rows.Next() {
		var p PartnerRow
		if err := rows.Scan(
			&p.ID, &p.ShopID, &p.OwnerName, &p.OwnerCompany, &p.OwnerPhone, &p.OwnerTaxID,
			&p.Plate, &p.VehicleType, &p.MaxWeightKg,
			&p.PricingModel, &p.BaseRate, &p.PerKmRate,
			&p.Rating, &p.TotalTrips, &p.Status,
			&p.WithholdingTaxRate, &p.BCAccountCreditorID,
			&p.CreatedAt, &p.UpdatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		partners = append(partners, p)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return partners, total, nil
}

// GetByID ดึงรถร่วมตาม ID
func (q *PartnerQuery) GetByID(ctx context.Context, shopID, id string) (*PartnerRow, error) {
	sql := `
		SELECT
			id, shop_id, owner_name, owner_company, owner_phone, owner_tax_id,
			plate, vehicle_type, max_weight_kg,
			pricing_model, base_rate, per_km_rate,
			rating, total_trips, status,
			withholding_tax_rate, bc_account_creditor_id,
			created_at, updated_at
		FROM fleet_partner_vehicles
		WHERE shop_id = $1 AND id = $2
	`

	var p PartnerRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, id).Scan(
		&p.ID, &p.ShopID, &p.OwnerName, &p.OwnerCompany, &p.OwnerPhone, &p.OwnerTaxID,
		&p.Plate, &p.VehicleType, &p.MaxWeightKg,
		&p.PricingModel, &p.BaseRate, &p.PerKmRate,
		&p.Rating, &p.TotalTrips, &p.Status,
		&p.WithholdingTaxRate, &p.BCAccountCreditorID,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// FindAvailable ค้นหารถร่วมที่ว่าง กรองตาม vehicleType และ zone
func (q *PartnerQuery) FindAvailable(ctx context.Context, shopID string, vehicleType string, zone string) ([]PartnerRow, error) {
	sql := `
		SELECT
			id, shop_id, owner_name, owner_company, owner_phone, owner_tax_id,
			plate, vehicle_type, max_weight_kg,
			pricing_model, base_rate, per_km_rate,
			rating, total_trips, status,
			withholding_tax_rate, bc_account_creditor_id,
			created_at, updated_at
		FROM fleet_partner_vehicles
		WHERE shop_id = $1
		  AND status = 'active'
		  AND ($2 = '' OR vehicle_type = $2)
		ORDER BY rating DESC NULLS LAST, total_trips DESC
	`

	rows, err := q.db.Pool().Query(ctx, sql, shopID, vehicleType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var partners []PartnerRow
	for rows.Next() {
		var p PartnerRow
		if err := rows.Scan(
			&p.ID, &p.ShopID, &p.OwnerName, &p.OwnerCompany, &p.OwnerPhone, &p.OwnerTaxID,
			&p.Plate, &p.VehicleType, &p.MaxWeightKg,
			&p.PricingModel, &p.BaseRate, &p.PerKmRate,
			&p.Rating, &p.TotalTrips, &p.Status,
			&p.WithholdingTaxRate, &p.BCAccountCreditorID,
			&p.CreatedAt, &p.UpdatedAt,
		); err != nil {
			return nil, err
		}
		partners = append(partners, p)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return partners, nil
}
