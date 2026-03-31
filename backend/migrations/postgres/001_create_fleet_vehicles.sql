CREATE TABLE IF NOT EXISTS fleet_vehicles (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    plate TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    type TEXT NOT NULL,
    year INT,
    color TEXT,
    chassis_no TEXT,
    engine_no TEXT,
    fuel_type TEXT,
    max_weight_kg INT,
    ownership TEXT DEFAULT 'own',
    partner_id TEXT,
    status TEXT DEFAULT 'active',
    current_driver_id TEXT,
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    mileage_km INT,
    insurance_expiry DATE,
    tax_due_date DATE,
    act_due_date DATE,
    next_maintenance_km INT,
    next_maintenance_date DATE,
    health_status TEXT DEFAULT 'green',
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_vehicles_shop ON fleet_vehicles(shop_id);
CREATE INDEX idx_fleet_vehicles_status ON fleet_vehicles(shop_id, status);
CREATE INDEX idx_fleet_vehicles_plate ON fleet_vehicles(shop_id, plate);
