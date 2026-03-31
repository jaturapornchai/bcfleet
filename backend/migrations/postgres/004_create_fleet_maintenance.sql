CREATE TABLE IF NOT EXISTS fleet_work_orders (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    wo_no TEXT UNIQUE,
    vehicle_id TEXT NOT NULL,
    type TEXT,
    priority TEXT,
    status TEXT,
    reported_by TEXT,
    description TEXT,
    mileage_at_report INT,
    service_provider_type TEXT,
    service_provider_name TEXT,
    parts_cost DECIMAL(12,2),
    labor_cost DECIMAL(12,2),
    total_cost DECIMAL(12,2),
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    bc_account_synced BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_wo_shop ON fleet_work_orders(shop_id);
CREATE INDEX idx_fleet_wo_vehicle ON fleet_work_orders(vehicle_id);
CREATE INDEX idx_fleet_wo_status ON fleet_work_orders(shop_id, status);
