CREATE TABLE IF NOT EXISTS fleet_drivers (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    employee_id TEXT,
    name TEXT NOT NULL,
    nickname TEXT,
    phone TEXT,
    license_type TEXT,
    license_expiry DATE,
    employment_type TEXT,
    salary DECIMAL(12,2),
    daily_allowance DECIMAL(12,2),
    trip_bonus DECIMAL(12,2),
    status TEXT DEFAULT 'active',
    assigned_vehicle_id TEXT,
    score INT DEFAULT 0,
    total_trips INT DEFAULT 0,
    on_time_rate DECIMAL(5,4),
    fuel_efficiency DECIMAL(5,2),
    customer_rating DECIMAL(3,2),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_drivers_shop ON fleet_drivers(shop_id);
CREATE INDEX idx_fleet_drivers_status ON fleet_drivers(shop_id, status);
