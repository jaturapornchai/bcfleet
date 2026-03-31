CREATE TABLE IF NOT EXISTS fleet_trips (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    trip_no TEXT UNIQUE,
    status TEXT NOT NULL,
    vehicle_id TEXT,
    driver_id TEXT,
    is_partner BOOLEAN DEFAULT false,
    partner_id TEXT,
    origin_name TEXT,
    origin_lat DOUBLE PRECISION,
    origin_lng DOUBLE PRECISION,
    destination_count INT DEFAULT 1,
    cargo_description TEXT,
    cargo_weight_kg INT,
    planned_start TIMESTAMPTZ,
    planned_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    distance_km DECIMAL(10,2),
    fuel_cost DECIMAL(12,2),
    toll_cost DECIMAL(12,2),
    other_cost DECIMAL(12,2),
    driver_allowance DECIMAL(12,2),
    total_cost DECIMAL(12,2),
    revenue DECIMAL(12,2),
    profit DECIMAL(12,2),
    has_pod BOOLEAN DEFAULT false,
    created_by TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_trips_shop ON fleet_trips(shop_id);
CREATE INDEX idx_fleet_trips_status ON fleet_trips(shop_id, status);
CREATE INDEX idx_fleet_trips_date ON fleet_trips(shop_id, planned_start);
CREATE INDEX idx_fleet_trips_vehicle ON fleet_trips(vehicle_id);
CREATE INDEX idx_fleet_trips_driver ON fleet_trips(driver_id);
