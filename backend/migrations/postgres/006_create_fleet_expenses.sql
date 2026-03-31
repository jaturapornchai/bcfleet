CREATE TABLE IF NOT EXISTS fleet_expenses (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    trip_id TEXT,
    vehicle_id TEXT,
    driver_id TEXT,
    type TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    fuel_liters DECIMAL(8,2),
    fuel_price_per_liter DECIMAL(8,2),
    odometer_km INT,
    receipt_url TEXT,
    bc_account_synced BOOLEAN DEFAULT false,
    recorded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_expenses_shop ON fleet_expenses(shop_id);
CREATE INDEX idx_fleet_expenses_vehicle ON fleet_expenses(vehicle_id);
CREATE INDEX idx_fleet_expenses_date ON fleet_expenses(shop_id, recorded_at);
