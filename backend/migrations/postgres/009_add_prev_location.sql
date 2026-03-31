-- 009_add_prev_location_and_monitoring.sql
-- เพิ่ม prev_lat/prev_lng เพื่อ detect รถที่เปลี่ยนตำแหน่ง (moving vehicles)
-- เพิ่ม monitoring_prompt สำหรับ AI วิเคราะห์รถแต่ละคัน

ALTER TABLE fleet_vehicle_locations
    ADD COLUMN IF NOT EXISTS prev_lat        DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS prev_lng        DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS prev_updated_at TIMESTAMPTZ;

ALTER TABLE fleet_vehicles
    ADD COLUMN IF NOT EXISTS monitoring_prompt TEXT;
