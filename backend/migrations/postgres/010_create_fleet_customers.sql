-- 010_create_fleet_customers.sql
-- ฐานข้อมูลลูกค้า + เชื่อม customer_id กับ trip

CREATE TABLE IF NOT EXISTS fleet_customers (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    customer_no TEXT NOT NULL,
    name TEXT NOT NULL,
    customer_type TEXT DEFAULT 'individual',
    phone TEXT,
    line_user_id TEXT,
    email TEXT,
    company TEXT,
    tax_id TEXT,
    address TEXT,
    credit_enabled BOOLEAN DEFAULT FALSE,
    credit_days INT DEFAULT 0,
    credit_limit NUMERIC(12,2) DEFAULT 0,
    notes TEXT,
    status TEXT DEFAULT 'active',
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_shop ON fleet_customers(shop_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON fleet_customers(shop_id, phone);
CREATE INDEX IF NOT EXISTS idx_customers_line ON fleet_customers(shop_id, line_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_status ON fleet_customers(shop_id, status);

-- เพิ่ม customer_id ใน trips
ALTER TABLE fleet_trips ADD COLUMN IF NOT EXISTS customer_id TEXT;
CREATE INDEX IF NOT EXISTS idx_fleet_trips_customer ON fleet_trips(customer_id);
