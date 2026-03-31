CREATE TABLE IF NOT EXISTS fleet_partner_vehicles (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    owner_name TEXT,
    owner_company TEXT,
    owner_phone TEXT,
    owner_tax_id TEXT,
    plate TEXT,
    vehicle_type TEXT,
    max_weight_kg INT,
    pricing_model TEXT,
    base_rate DECIMAL(12,2),
    per_km_rate DECIMAL(8,2),
    rating DECIMAL(3,2),
    total_trips INT DEFAULT 0,
    status TEXT DEFAULT 'active',
    withholding_tax_rate DECIMAL(5,4),
    bc_account_creditor_id TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_partners_shop ON fleet_partner_vehicles(shop_id);
