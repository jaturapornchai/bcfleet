CREATE TABLE IF NOT EXISTS fleet_alerts (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    type TEXT NOT NULL,
    entity TEXT,
    entity_id TEXT,
    title TEXT,
    message TEXT,
    severity TEXT,
    due_date DATE,
    days_remaining INT,
    status TEXT DEFAULT 'active',
    acknowledged_by TEXT,
    acknowledged_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_alerts_shop ON fleet_alerts(shop_id, status);
