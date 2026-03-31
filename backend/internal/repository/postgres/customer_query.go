package postgres

import (
	"context"
	"time"

	"sml-fleet/internal/database"
)

// CustomerQuery PostgreSQL read queries สำหรับลูกค้า (Read Cache)
type CustomerQuery struct {
	db *database.PostgresDB
}

func NewCustomerQuery(db *database.PostgresDB) *CustomerQuery {
	return &CustomerQuery{db: db}
}

// CustomerRow ข้อมูลลูกค้าจาก PostgreSQL
type CustomerRow struct {
	ID           string     `json:"id"`
	ShopID       string     `json:"shop_id"`
	CustomerNo   string     `json:"customer_no"`
	Name         string     `json:"name"`
	CustomerType string     `json:"customer_type"`
	Phone        *string    `json:"phone"`
	LineUserID   *string    `json:"line_user_id"`
	Email        *string    `json:"email"`
	Company      *string    `json:"company"`
	TaxID        *string    `json:"tax_id"`
	Address      *string    `json:"address"`
	CreditDays   int        `json:"credit_days"`
	CreditLimit  float64    `json:"credit_limit"`
	Notes        *string    `json:"notes"`
	Status       string     `json:"status"`
	TotalTrips   int        `json:"total_trips"`
	TotalRevenue float64    `json:"total_revenue"`
	CreatedAt    *time.Time `json:"created_at"`
	UpdatedAt    *time.Time `json:"updated_at"`
}

// List ดึงรายการลูกค้า
func (q *CustomerQuery) List(ctx context.Context, shopID, status string, page, limit int) ([]CustomerRow, int, error) {
	offset := (page - 1) * limit

	countSQL := `SELECT COUNT(*) FROM fleet_customers WHERE shop_id = $1 AND ($2 = '' OR status = $2)`
	var total int
	if err := q.db.Pool().QueryRow(ctx, countSQL, shopID, status).Scan(&total); err != nil {
		return nil, 0, err
	}

	sql := `
		SELECT c.id, c.shop_id, c.customer_no, c.name, c.customer_type,
			c.phone, c.line_user_id, c.email, c.company, c.tax_id, c.address,
			c.credit_days, c.credit_limit, c.notes, c.status,
			COALESCE((SELECT COUNT(*) FROM fleet_trips t WHERE t.customer_id = c.id), 0) as total_trips,
			COALESCE((SELECT SUM(revenue) FROM fleet_trips t WHERE t.customer_id = c.id), 0) as total_revenue,
			c.created_at, c.updated_at
		FROM fleet_customers c
		WHERE c.shop_id = $1 AND ($2 = '' OR c.status = $2)
		ORDER BY c.name ASC
		LIMIT $3 OFFSET $4
	`
	rows, err := q.db.Pool().Query(ctx, sql, shopID, status, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var customers []CustomerRow
	for rows.Next() {
		var c CustomerRow
		if err := rows.Scan(
			&c.ID, &c.ShopID, &c.CustomerNo, &c.Name, &c.CustomerType,
			&c.Phone, &c.LineUserID, &c.Email, &c.Company, &c.TaxID, &c.Address,
			&c.CreditDays, &c.CreditLimit, &c.Notes, &c.Status,
			&c.TotalTrips, &c.TotalRevenue,
			&c.CreatedAt, &c.UpdatedAt,
		); err != nil {
			return nil, 0, err
		}
		customers = append(customers, c)
	}
	return customers, total, rows.Err()
}

// Search ค้นหาลูกค้าด้วย keyword (phone, name, company)
func (q *CustomerQuery) Search(ctx context.Context, shopID, keyword string, limit int) ([]CustomerRow, error) {
	sql := `
		SELECT id, shop_id, customer_no, name, customer_type,
			phone, line_user_id, email, company, tax_id, address,
			credit_days, credit_limit, notes, status,
			0 as total_trips, 0 as total_revenue,
			created_at, updated_at
		FROM fleet_customers
		WHERE shop_id = $1 AND (
			name ILIKE '%' || $2 || '%' OR
			phone ILIKE '%' || $2 || '%' OR
			company ILIKE '%' || $2 || '%' OR
			customer_no ILIKE '%' || $2 || '%' OR
			line_user_id = $2
		)
		ORDER BY name ASC
		LIMIT $3
	`
	rows, err := q.db.Pool().Query(ctx, sql, shopID, keyword, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var customers []CustomerRow
	for rows.Next() {
		var c CustomerRow
		if err := rows.Scan(
			&c.ID, &c.ShopID, &c.CustomerNo, &c.Name, &c.CustomerType,
			&c.Phone, &c.LineUserID, &c.Email, &c.Company, &c.TaxID, &c.Address,
			&c.CreditDays, &c.CreditLimit, &c.Notes, &c.Status,
			&c.TotalTrips, &c.TotalRevenue,
			&c.CreatedAt, &c.UpdatedAt,
		); err != nil {
			return nil, err
		}
		customers = append(customers, c)
	}
	return customers, rows.Err()
}

// GetByID ดึงลูกค้า by ID
func (q *CustomerQuery) GetByID(ctx context.Context, shopID, id string) (*CustomerRow, error) {
	sql := `
		SELECT c.id, c.shop_id, c.customer_no, c.name, c.customer_type,
			c.phone, c.line_user_id, c.email, c.company, c.tax_id, c.address,
			c.credit_days, c.credit_limit, c.notes, c.status,
			COALESCE((SELECT COUNT(*) FROM fleet_trips t WHERE t.customer_id = c.id), 0),
			COALESCE((SELECT SUM(revenue) FROM fleet_trips t WHERE t.customer_id = c.id), 0),
			c.created_at, c.updated_at
		FROM fleet_customers c
		WHERE c.id = $1 AND c.shop_id = $2
	`
	var c CustomerRow
	err := q.db.Pool().QueryRow(ctx, sql, id, shopID).Scan(
		&c.ID, &c.ShopID, &c.CustomerNo, &c.Name, &c.CustomerType,
		&c.Phone, &c.LineUserID, &c.Email, &c.Company, &c.TaxID, &c.Address,
		&c.CreditDays, &c.CreditLimit, &c.Notes, &c.Status,
		&c.TotalTrips, &c.TotalRevenue,
		&c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

// GetByLineUserID ดึงลูกค้าด้วย LINE User ID
func (q *CustomerQuery) GetByLineUserID(ctx context.Context, shopID, lineUserID string) (*CustomerRow, error) {
	sql := `
		SELECT id, shop_id, customer_no, name, customer_type,
			phone, line_user_id, email, company, tax_id, address,
			credit_days, credit_limit, notes, status,
			0, 0, created_at, updated_at
		FROM fleet_customers
		WHERE shop_id = $1 AND line_user_id = $2
		LIMIT 1
	`
	var c CustomerRow
	err := q.db.Pool().QueryRow(ctx, sql, shopID, lineUserID).Scan(
		&c.ID, &c.ShopID, &c.CustomerNo, &c.Name, &c.CustomerType,
		&c.Phone, &c.LineUserID, &c.Email, &c.Company, &c.TaxID, &c.Address,
		&c.CreditDays, &c.CreditLimit, &c.Notes, &c.Status,
		&c.TotalTrips, &c.TotalRevenue,
		&c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &c, nil
}
