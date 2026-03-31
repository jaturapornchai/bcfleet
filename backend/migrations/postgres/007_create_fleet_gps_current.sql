CREATE TABLE IF NOT EXISTS fleet_vehicle_locations (
    vehicle_id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    driver_id TEXT,
    trip_id TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    speed_kmh DECIMAL(6,2),
    heading INT,
    battery_pct INT,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_locations_shop ON fleet_vehicle_locations(shop_id);
