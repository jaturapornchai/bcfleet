# BC Fleet Database Schema

## Architecture

```
MongoDB (Source of Truth) → Kafka (Stream) → PostgreSQL (Query Layer)
```

- MongoDB เก็บทุก document, event, log — เป็น source of truth
- Kafka stream real-time ทุก write ที่เกิดใน MongoDB
- PostgreSQL เป็น read-optimized view — สามารถ DROP แล้ว rebuild ได้เสมอ
- API อ่านจาก PostgreSQL (เร็ว, JOIN ได้) แต่เขียนลง MongoDB

---

## MongoDB Collections

| Collection | Purpose | TTL |
|-----------|---------|-----|
| `fleet_vehicles` | ข้อมูลรถขนส่ง | ไม่มี |
| `fleet_drivers` | ข้อมูลคนขับ | ไม่มี |
| `fleet_trips` | เที่ยววิ่ง + POD + checklist | ไม่มี |
| `fleet_maintenance_work_orders` | ใบสั่งซ่อม + อะไหล่ | ไม่มี |
| `fleet_partner_vehicles` | รถร่วม + pricing | ไม่มี |
| `fleet_expenses` | ค่าใช้จ่าย (น้ำมัน/ทางด่วน/ซ่อม) | ไม่มี |
| `fleet_gps_logs` | GPS logs ทุก 30 วินาที | 90 วัน |
| `fleet_event_logs` | Event audit log ทุก action | เก็บถาวร |
| `fleet_alerts` | แจ้งเตือน (พ.ร.บ./ซ่อม/ใบขับขี่) | ไม่มี |
| `fleet_parts_inventory` | สต๊อกอะไหล่ | ไม่มี |

### สำคัญ: ทุก document มี `shop_id` สำหรับ multi-tenant

---

## MongoDB Indexes

```javascript
// fleet_vehicles
{ shop_id: 1, status: 1 }
{ shop_id: 1, plate: 1 }

// fleet_drivers
{ shop_id: 1, status: 1 }
{ shop_id: 1, phone: 1 }

// fleet_trips
{ shop_id: 1, status: 1 }
{ shop_id: 1, vehicle_id: 1 }
{ shop_id: 1, driver_id: 1 }
{ planned_start: -1 }

// fleet_gps_logs
{ shop_id: 1, vehicle_id: 1, timestamp: -1 }
{ location: "2dsphere" }
{ created_at: 1 }  // TTL — expireAfterSeconds: 7776000 (90 days)

// fleet_event_logs
{ shop_id: 1, entity: 1, entity_id: 1 }
{ created_at: -1 }
```

---

## PostgreSQL Tables (Query Layer)

### fleet_vehicles

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | MongoDB ObjectID |
| shop_id | TEXT NOT NULL | multi-tenant |
| plate | TEXT NOT NULL | ทะเบียนรถ |
| brand | TEXT | ยี่ห้อ |
| model | TEXT | รุ่น |
| type | TEXT NOT NULL | "4ล้อ", "6ล้อ", "10ล้อ", "หัวลาก", "กระบะ" |
| year | INT | ปีผลิต |
| color | TEXT | สี |
| chassis_no | TEXT | เลขตัวถัง |
| engine_no | TEXT | เลขเครื่อง |
| fuel_type | TEXT | "ดีเซล", "เบนซิน", "NGV", "EV" |
| max_weight_kg | INT | น้ำหนักบรรทุกสูงสุด |
| ownership | TEXT | "own", "partner", "rental" |
| partner_id | TEXT | ref partner (ถ้าเป็นรถร่วม) |
| status | TEXT | "active", "maintenance", "inactive" |
| current_driver_id | TEXT | คนขับปัจจุบัน |
| current_lat | DOUBLE PRECISION | ละติจูดปัจจุบัน |
| current_lng | DOUBLE PRECISION | ลองจิจูดปัจจุบัน |
| mileage_km | INT | เลขไมล์ |
| insurance_expiry | DATE | วันหมดประกัน |
| tax_due_date | DATE | วันต่อภาษี |
| act_due_date | DATE | วันต่อ พ.ร.บ. |
| next_maintenance_km | INT | กม.ซ่อมครั้งถัดไป |
| next_maintenance_date | DATE | วันซ่อมครั้งถัดไป |
| health_status | TEXT | "green", "yellow", "red" |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |
| deleted_at | TIMESTAMPTZ | soft delete |

### fleet_drivers

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| employee_id | TEXT | รหัสพนักงาน |
| name | TEXT NOT NULL | ชื่อ-นามสกุล |
| nickname | TEXT | ชื่อเล่น |
| phone | TEXT | เบอร์โทร |
| license_type | TEXT | ท.1, ท.2, ท.3, ท.4 |
| license_expiry | DATE | วันหมดใบขับขี่ |
| employment_type | TEXT | "permanent", "contract", "daily", "partner" |
| salary | DECIMAL(12,2) | เงินเดือนฐาน |
| daily_allowance | DECIMAL(12,2) | เบี้ยเลี้ยงต่อวัน |
| trip_bonus | DECIMAL(12,2) | โบนัสต่อเที่ยว |
| status | TEXT | "active", "on_leave", "suspended", "resigned" |
| assigned_vehicle_id | TEXT | รถที่รับผิดชอบ |
| score | INT | KPI score 0-100 |
| total_trips | INT | จำนวนเที่ยวทั้งหมด |
| on_time_rate | DECIMAL(5,4) | อัตราตรงเวลา |
| fuel_efficiency | DECIMAL(5,2) | km/L เฉลี่ย |
| customer_rating | DECIMAL(3,2) | คะแนนลูกค้า |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |
| deleted_at | TIMESTAMPTZ | |

### fleet_trips

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| trip_no | TEXT UNIQUE | รหัสเที่ยว เช่น TRIP-2024-001234 |
| status | TEXT NOT NULL | "draft"→"pending"→"accepted"→"started"→"arrived"→"delivering"→"completed"/"cancelled" |
| vehicle_id | TEXT | |
| driver_id | TEXT | |
| is_partner | BOOLEAN | รถร่วมหรือไม่ |
| partner_id | TEXT | |
| origin_name | TEXT | ต้นทาง |
| origin_lat/lng | DOUBLE PRECISION | |
| destination_count | INT | จำนวนจุดส่ง |
| cargo_description | TEXT | รายละเอียดสินค้า |
| cargo_weight_kg | INT | |
| planned_start/end | TIMESTAMPTZ | เวลาวางแผน |
| actual_start/end | TIMESTAMPTZ | เวลาจริง |
| distance_km | DECIMAL(10,2) | |
| fuel_cost | DECIMAL(12,2) | |
| toll_cost | DECIMAL(12,2) | |
| other_cost | DECIMAL(12,2) | |
| driver_allowance | DECIMAL(12,2) | |
| total_cost | DECIMAL(12,2) | |
| revenue | DECIMAL(12,2) | ค่าขนส่งที่เรียกเก็บ |
| profit | DECIMAL(12,2) | กำไร |
| has_pod | BOOLEAN | มี POD หรือไม่ |
| created_by | TEXT | |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### fleet_work_orders

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| wo_no | TEXT UNIQUE | รหัสใบสั่งซ่อม เช่น WO-2024-000123 |
| vehicle_id | TEXT NOT NULL | |
| type | TEXT | "preventive", "corrective", "emergency" |
| priority | TEXT | "low", "medium", "high", "critical" |
| status | TEXT | "draft"→"pending_approval"→"approved"→"in_progress"→"completed"/"cancelled" |
| reported_by | TEXT | |
| description | TEXT | |
| mileage_at_report | INT | เลขไมล์ตอนแจ้ง |
| service_provider_type | TEXT | "internal", "external" |
| service_provider_name | TEXT | |
| parts_cost | DECIMAL(12,2) | |
| labor_cost | DECIMAL(12,2) | |
| total_cost | DECIMAL(12,2) | |
| approved_by | TEXT | |
| approved_at | TIMESTAMPTZ | |
| completed_at | TIMESTAMPTZ | |
| bc_account_synced | BOOLEAN | sync กับ BC Account แล้วหรือยัง |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### fleet_partner_vehicles

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| owner_name | TEXT | |
| owner_company | TEXT | |
| owner_phone | TEXT | |
| owner_tax_id | TEXT | เลขผู้เสียภาษี |
| plate | TEXT | |
| vehicle_type | TEXT | |
| max_weight_kg | INT | |
| pricing_model | TEXT | "per_trip", "per_km", "per_day" |
| base_rate | DECIMAL(12,2) | |
| per_km_rate | DECIMAL(8,2) | |
| rating | DECIMAL(3,2) | |
| total_trips | INT | |
| status | TEXT | "active", "suspended", "inactive" |
| withholding_tax_rate | DECIMAL(5,4) | อัตราหัก ณ ที่จ่าย |
| bc_account_creditor_id | TEXT | ref เจ้าหนี้ใน BC Account |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### fleet_expenses

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| trip_id | TEXT | ผูกกับเที่ยวหรือไม่ |
| vehicle_id | TEXT | |
| driver_id | TEXT | |
| type | TEXT NOT NULL | "fuel", "toll", "parking", "repair", "fine", "other" |
| description | TEXT | |
| amount | DECIMAL(12,2) NOT NULL | |
| fuel_liters | DECIMAL(8,2) | |
| fuel_price_per_liter | DECIMAL(8,2) | |
| odometer_km | INT | |
| receipt_url | TEXT | URL ใน Cloudflare R2 |
| bc_account_synced | BOOLEAN | |
| recorded_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | |

### fleet_vehicle_locations (ตำแหน่งปัจจุบัน)

| Column | Type | Description |
|--------|------|-------------|
| vehicle_id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| driver_id | TEXT | |
| trip_id | TEXT | |
| lat | DOUBLE PRECISION | |
| lng | DOUBLE PRECISION | |
| speed_kmh | DECIMAL(6,2) | |
| heading | INT | |
| battery_pct | INT | |
| updated_at | TIMESTAMPTZ | |

หมายเหตุ: เก็บแค่ตำแหน่งล่าสุด (1 row ต่อ vehicle) — GPS log ทั้งหมดอยู่ใน MongoDB

### fleet_alerts

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | |
| shop_id | TEXT NOT NULL | |
| type | TEXT NOT NULL | "insurance_expiry", "tax_due", "act_due", "license_expiry", "maintenance_due", "geofence_alert", "speeding" |
| entity | TEXT | "vehicle", "driver" |
| entity_id | TEXT | |
| title | TEXT | |
| message | TEXT | |
| severity | TEXT | "info", "warning", "critical" |
| due_date | DATE | |
| days_remaining | INT | |
| status | TEXT | "active", "acknowledged", "resolved" |
| acknowledged_by | TEXT | |
| acknowledged_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | |

---

## Dashboard Views

```sql
-- สรุปสถานะรถต่อ shop
CREATE VIEW fleet_dashboard_summary AS
SELECT shop_id,
    COUNT(*) FILTER (WHERE status = 'active') as active_vehicles,
    COUNT(*) FILTER (WHERE status = 'maintenance') as vehicles_in_maintenance,
    COUNT(*) FILTER (WHERE health_status = 'red') as critical_vehicles,
    COUNT(*) FILTER (WHERE health_status = 'yellow') as warning_vehicles
FROM fleet_vehicles WHERE deleted_at IS NULL GROUP BY shop_id;

-- สรุปเที่ยววิ่งวันนี้
CREATE VIEW fleet_today_trips AS
SELECT shop_id,
    COUNT(*) as total_trips,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status IN ('started','delivering')) as in_progress,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COALESCE(SUM(profit), 0) as total_profit
FROM fleet_trips WHERE DATE(planned_start) = CURRENT_DATE GROUP BY shop_id;
```

---

## Data Flow

| Operation | Write Path | Read Path |
|-----------|-----------|-----------|
| สร้าง/แก้ไขข้อมูล | API → MongoDB → Kafka → PostgreSQL | - |
| Query/รายงาน | - | API → PostgreSQL |
| GPS update | API → MongoDB (fleet_gps_logs) + PostgreSQL (fleet_vehicle_locations latest) | - |
| Event log | API → MongoDB (fleet_event_logs) เท่านั้น | MongoDB |
| Rebuild | - | run rebuild-pgsql.sh |

## Rebuild PostgreSQL

```bash
# DROP และสร้างใหม่ทั้งหมดจาก MongoDB
./scripts/rebuild-pgsql.sh
```
