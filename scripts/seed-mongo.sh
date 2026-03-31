#!/bin/bash
# Seed ข้อมูลตัวอย่างลง MongoDB สำหรับทดสอบ
set -e

MONGO_URI="${MONGO_URI:-mongodb://localhost:27017/smlfleet}"

echo "=== SML Fleet: Seed Test Data ==="

mongosh "$MONGO_URI" <<'SEED'

// ลบข้อมูลเก่า
db.fleet_vehicles.drop();
db.fleet_drivers.drop();
db.fleet_trips.drop();
db.fleet_maintenance_work_orders.drop();
db.fleet_partner_vehicles.drop();
db.fleet_expenses.drop();
db.fleet_alerts.drop();
db.fleet_event_logs.drop();
db.fleet_gps_logs.drop();
db.fleet_parts_inventory.drop();

// === รถขนส่ง ===
db.fleet_vehicles.insertMany([
  {
    shop_id: "shop_001",
    plate: "กท-1234",
    brand: "ISUZU",
    model: "FRR 210",
    type: "6ล้อ",
    year: 2023,
    color: "ขาว",
    chassis_no: "MPATFS66JMT000123",
    engine_no: "4HK1-123456",
    fuel_type: "ดีเซล",
    max_weight_kg: 6000,
    ownership: "own",
    status: "active",
    mileage_km: 85000,
    insurance: { company: "วิริยะประกันภัย", policy_no: "INS-2024-001", type: "ชั้น1", start_date: new Date("2024-01-01"), end_date: new Date("2025-01-01"), premium: 25000 },
    tax: { due_date: new Date("2025-03-15"), last_paid: new Date("2024-03-15"), amount: 3200 },
    act: { due_date: new Date("2025-03-15"), last_paid: new Date("2024-03-15"), amount: 1800 },
    maintenance_schedule: [
      { item: "น้ำมันเครื่อง", interval_km: 10000, interval_days: 180, last_done_km: 80000, last_done_date: new Date("2024-06-01") },
      { item: "ผ้าเบรค", interval_km: 40000, last_done_km: 60000, last_done_date: new Date("2024-01-01") },
      { item: "ยาง", interval_km: 50000, last_done_km: 50000, last_done_date: new Date("2023-06-01") },
    ],
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    shop_id: "shop_001",
    plate: "2กบ-5678",
    brand: "HINO",
    model: "500 Series",
    type: "10ล้อ",
    year: 2022,
    color: "น้ำเงิน",
    fuel_type: "ดีเซล",
    max_weight_kg: 15000,
    ownership: "own",
    status: "active",
    mileage_km: 120000,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    shop_id: "shop_001",
    plate: "ขก-9012",
    brand: "TOYOTA",
    model: "Revo",
    type: "กระบะ",
    year: 2024,
    color: "ดำ",
    fuel_type: "ดีเซล",
    max_weight_kg: 1000,
    ownership: "own",
    status: "active",
    mileage_km: 15000,
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// === คนขับ ===
db.fleet_drivers.insertMany([
  {
    shop_id: "shop_001",
    employee_id: "EMP-001",
    name: "สมชาย ใจดี",
    nickname: "ชาย",
    phone: "081-234-5678",
    id_card: "1-1234-12345-12-1",
    address: "123 ม.4 ต.สารภี อ.สารภี จ.เชียงใหม่",
    license: { number: "12345678", type: "ท.2", issue_date: new Date("2020-01-01"), expiry_date: new Date("2025-01-01") },
    employment: { type: "permanent", start_date: new Date("2020-01-01"), salary: 15000, daily_allowance: 300, trip_bonus: 200, overtime_rate: 100 },
    status: "active",
    zones: ["เชียงใหม่", "ลำพูน", "ลำปาง"],
    vehicle_types: ["6ล้อ", "10ล้อ"],
    performance: { total_trips: 450, on_time_rate: 0.95, fuel_efficiency: 5.2, customer_rating: 4.8, accident_count: 1, violation_count: 0, score: 92 },
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    shop_id: "shop_001",
    employee_id: "EMP-002",
    name: "สมหญิง แก้วใส",
    nickname: "หญิง",
    phone: "082-345-6789",
    license: { number: "23456789", type: "ท.2", issue_date: new Date("2021-06-01"), expiry_date: new Date("2026-06-01") },
    employment: { type: "permanent", start_date: new Date("2021-06-01"), salary: 14000, daily_allowance: 300, trip_bonus: 200, overtime_rate: 100 },
    status: "active",
    zones: ["เชียงใหม่", "เชียงราย"],
    vehicle_types: ["กระบะ", "6ล้อ"],
    performance: { total_trips: 280, on_time_rate: 0.98, fuel_efficiency: 6.1, customer_rating: 4.9, accident_count: 0, violation_count: 0, score: 96 },
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// === เที่ยววิ่ง ===
db.fleet_trips.insertMany([
  {
    shop_id: "shop_001",
    trip_no: "TRIP-2024-001234",
    status: "completed",
    vehicle_id: "vehicle_001",
    driver_id: "driver_001",
    is_partner: false,
    origin: { name: "คลังสินค้า ABC", address: "123 ถ.เชียงใหม่-ลำปาง", lat: 18.7883, lng: 98.9853, contact_name: "สมศรี", contact_phone: "089-123-4567" },
    destinations: [
      { seq: 1, name: "ร้าน XYZ วัสดุ", address: "456 ถ.ลำพูน", lat: 18.5741, lng: 98.9847, status: "delivered" }
    ],
    cargo: { description: "ปูนซีเมนต์ 200 ถุง", weight_kg: 10000 },
    schedule: { planned_start: new Date("2024-12-15T06:00:00"), planned_end: new Date("2024-12-15T12:00:00") },
    route: { distance_km: 45, duration_minutes: 60 },
    costs: { fuel: 800, toll: 60, other: 0, driver_allowance: 300, total: 1160, revenue: 2500, profit: 1340 },
    created_by: "admin_001",
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    shop_id: "shop_001",
    trip_no: "TRIP-2024-001235",
    status: "pending",
    origin: { name: "โรงงาน DEF", address: "789 ถ.ซุปเปอร์ไฮเวย์", lat: 18.8200, lng: 98.9700 },
    destinations: [
      { seq: 1, name: "ร้านค้า GHI", address: "321 ถ.ช้างเผือก", lat: 18.8100, lng: 98.9900, status: "pending" }
    ],
    cargo: { description: "อุปกรณ์ก่อสร้าง 50 กล่อง", weight_kg: 3000 },
    schedule: { planned_start: new Date("2025-01-15T08:00:00"), planned_end: new Date("2025-01-15T14:00:00") },
    created_by: "admin_001",
    created_at: new Date(),
    updated_at: new Date()
  }
]);

// === รถร่วม ===
db.fleet_partner_vehicles.insertOne({
  shop_id: "shop_001",
  owner: {
    name: "นายสมหมาย รถเยอะ",
    company: "บจก.ขนส่งสมหมาย",
    tax_id: "0105564123456",
    phone: "081-456-7890",
    line_id: "sommai_truck",
    bank_account: { bank: "กสิกรไทย", account_no: "123-4-56789-0", account_name: "บจก.ขนส่งสมหมาย" },
  },
  vehicle: { plate: "2กร-5678", brand: "HINO", model: "500", type: "10ล้อ", year: 2022, max_weight_kg: 15000, fuel_type: "ดีเซล" },
  driver: { name: "นายวิชัย ขับดี", phone: "089-567-8901", license_type: "ท.2", license_expiry: new Date("2025-06-01") },
  pricing: { model: "per_trip", base_rate: 3000, per_km: 15, zones: { "เชียงใหม่-ลำพูน": 2500, "เชียงใหม่-ลำปาง": 4500 } },
  coverage_zones: ["เชียงใหม่", "ลำพูน", "ลำปาง"],
  rating: 4.5,
  total_trips: 35,
  status: "active",
  withholding_tax: { rate: 0.01, type: "ภ.ง.ด.3" },
  created_at: new Date(),
  updated_at: new Date()
});

// === แจ้งเตือน ===
db.fleet_alerts.insertMany([
  {
    shop_id: "shop_001",
    type: "insurance_expiry",
    entity: "vehicle",
    entity_id: "vehicle_001",
    title: "ประกันภัยใกล้หมดอายุ",
    message: "รถ กท-1234 ประกันหมดอายุ 01/01/2025",
    severity: "warning",
    due_date: new Date("2025-01-01"),
    days_remaining: 30,
    status: "active",
    created_at: new Date()
  },
  {
    shop_id: "shop_001",
    type: "maintenance_due",
    entity: "vehicle",
    entity_id: "vehicle_001",
    title: "ครบรอบเปลี่ยนน้ำมันเครื่อง",
    message: "รถ กท-1234 ครบรอบเปลี่ยนน้ำมันเครื่องที่ 90,000 กม. (ปัจจุบัน 85,000 กม.)",
    severity: "info",
    status: "active",
    created_at: new Date()
  }
]);

// === อะไหล่ ===
db.fleet_parts_inventory.insertMany([
  { shop_id: "shop_001", part_no: "PART-001", name: "น้ำมันเครื่อง SHELL Rimula R4 15W-40", category: "น้ำมันหล่อลื่น", unit: "ลิตร", qty_in_stock: 40, min_qty: 16, unit_cost: 280, supplier: "Shell Thailand", location: "ห้องเก็บอะไหล่ A", created_at: new Date(), updated_at: new Date() },
  { shop_id: "shop_001", part_no: "PART-002", name: "กรองน้ำมันเครื่อง", category: "กรอง", unit: "ชิ้น", qty_in_stock: 10, min_qty: 5, unit_cost: 350, supplier: "ISUZU", location: "ห้องเก็บอะไหล่ A", created_at: new Date(), updated_at: new Date() },
  { shop_id: "shop_001", part_no: "PART-003", name: "ผ้าเบรคหน้า", category: "เบรค", unit: "ชุด", qty_in_stock: 4, min_qty: 2, unit_cost: 1200, supplier: "Bendix", location: "ห้องเก็บอะไหล่ B", created_at: new Date(), updated_at: new Date() }
]);

// สร้าง Indexes
db.fleet_gps_logs.createIndex({ shop_id: 1, vehicle_id: 1, timestamp: -1 });
db.fleet_gps_logs.createIndex({ location: "2dsphere" });
db.fleet_gps_logs.createIndex({ created_at: 1 }, { expireAfterSeconds: 7776000 }); // 90 days TTL
db.fleet_event_logs.createIndex({ shop_id: 1, entity: 1, entity_id: 1 });
db.fleet_event_logs.createIndex({ shop_id: 1, created_at: -1 });

print("=== Seed data complete! ===");
print("Vehicles: " + db.fleet_vehicles.countDocuments());
print("Drivers: " + db.fleet_drivers.countDocuments());
print("Trips: " + db.fleet_trips.countDocuments());
print("Partners: " + db.fleet_partner_vehicles.countDocuments());
print("Alerts: " + db.fleet_alerts.countDocuments());
print("Parts: " + db.fleet_parts_inventory.countDocuments());
SEED

echo "Done!"
