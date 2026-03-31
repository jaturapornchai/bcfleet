# SML Fleet MCP Tools Reference

MCP Server endpoint: `POST /mcp`  
Protocol: JSON-RPC 2.0  
Authentication: Bearer token (JWT)

รวม 46 tools สำหรับให้ AI Agent (Claude) ควบคุมระบบขนส่งผ่าน MCP protocol

---

## Vehicle Tools (8 tools)

### 1. `list_vehicles`
ค้นหารายการรถขนส่ง พร้อมกรองและ pagination

**Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| shop_id | string | yes | รหัสร้าน |
| type | string | no | "4ล้อ", "6ล้อ", "10ล้อ", "หัวลาก", "กระบะ" |
| status | string | no | "active", "maintenance", "inactive" |
| ownership | string | no | "own", "partner", "rental" |
| page | int | no | หน้า (default: 1) |
| limit | int | no | จำนวนต่อหน้า (default: 20) |

**Returns:** รายการรถ + total count

---

### 2. `get_vehicle`
ดูข้อมูลรถโดยละเอียด

**Parameters:** `shop_id`, `vehicle_id`

**Returns:** ข้อมูลรถครบถ้วน รวม insurance, tax, act, maintenance schedule

---

### 3. `create_vehicle`
ลงทะเบียนรถใหม่ — เขียน MongoDB → Kafka → PostgreSQL

**Parameters:**
| Field | Type | Required |
|-------|------|----------|
| shop_id | string | yes |
| plate | string | yes |
| brand | string | no |
| model | string | no |
| type | string | yes |
| year | int | no |
| fuel_type | string | no |
| max_weight_kg | int | no |
| ownership | string | no |
| mileage_km | int | no |

---

### 4. `update_vehicle`
อัปเดตข้อมูลรถ — บันทึก diff ใน event log

**Parameters:** `shop_id`, `vehicle_id` + fields ที่ต้องการแก้ไข

---

### 5. `get_vehicle_health`
ตรวจสอบสถานะสุขภาพรถ

**Parameters:** `shop_id`, `vehicle_id`

**Returns:**
```json
{
  "status": "yellow",
  "issues": [
    "ประกันหมดอีก 15 วัน",
    "น้ำมันเครื่องใกล้ครบกำหนด 500 km"
  ]
}
```

---

### 6. `get_vehicle_location`
ดูตำแหน่ง GPS ปัจจุบันของรถ

**Parameters:** `shop_id`, `vehicle_id`

**Returns:** lat, lng, speed, heading, updated_at

---

### 7. `get_vehicle_cost`
สรุปต้นทุนรวมต่อคัน

**Parameters:** `shop_id`, `vehicle_id`, `period` ("daily", "monthly", "yearly")

**Returns:** fuel_cost, maintenance_cost, toll_cost, total_cost, revenue, profit

---

### 8. `get_vehicle_history`
ประวัติทั้งหมดของรถ (อ่านจาก MongoDB event logs)

**Parameters:** `shop_id`, `vehicle_id`, `limit` (default: 50)

**Returns:** รายการ events เรียงตามเวลา

---

## Driver Tools (10 tools)

### 9. `list_drivers`
ค้นหาคนขับ

**Parameters:** `shop_id`, `status`, `zone`, `vehicle_type`, `page`, `limit`

---

### 10. `get_driver`
ข้อมูลคนขับโดยละเอียด รวม license, performance, schedule

**Parameters:** `shop_id`, `driver_id`

---

### 11. `create_driver`
ลงทะเบียนคนขับใหม่

**Parameters:** `shop_id`, `name`, `phone`, `license_type`, `license_expiry`, `employment_type`, `salary`

---

### 12. `update_driver`
อัปเดตข้อมูลคนขับ

**Parameters:** `shop_id`, `driver_id` + fields ที่ต้องการแก้ไข

---

### 13. `get_driver_score`
KPI score พร้อม breakdown

**Parameters:** `shop_id`, `driver_id`

**Returns:**
```json
{
  "score": 92,
  "breakdown": {
    "on_time_rate": 95,
    "fuel_efficiency": 88,
    "customer_rating": 96,
    "accident_free": 100,
    "violation_free": 100
  }
}
```

---

### 14. `check_driver_schedule`
ตรวจสอบตารางเวรและวันลา

**Parameters:** `shop_id`, `driver_id`, `date` (YYYY-MM-DD)

**Returns:** shift, available, leave_reason (ถ้าลา)

---

### 15. `assign_driver_to_trip`
มอบหมายงานให้คนขับ

**Parameters:** `shop_id`, `trip_id`, `driver_id`, `vehicle_id`

---

### 16. `get_driver_expense`
รายการค่าใช้จ่ายที่คนขับบันทึก

**Parameters:** `shop_id`, `driver_id`, `date_from`, `date_to`

---

### 17. `calculate_driver_salary`
คำนวณเงินเดือน + เบี้ยเลี้ยง + OT + โบนัสเที่ยว

**Parameters:** `shop_id`, `driver_id`, `month` (YYYY-MM)

**Returns:** base_salary, allowances, trip_bonus, overtime, total, deductions, net_pay

---

### 18. `suggest_best_driver`
AI แนะนำคนขับที่เหมาะสมที่สุดสำหรับงาน

**Parameters:** `shop_id`, `trip_id`, `vehicle_type`, `date`

**Returns:** รายชื่อคนขับ เรียงตามความเหมาะสม พร้อมเหตุผล

---

## Trip Tools (8 tools)

### 19. `list_trips`
ค้นหาเที่ยววิ่ง

**Parameters:** `shop_id`, `status`, `date_from`, `date_to`, `driver_id`, `vehicle_id`, `page`, `limit`

---

### 20. `create_trip`
สร้างเที่ยววิ่งใหม่

**Parameters:**
| Field | Type | Required |
|-------|------|----------|
| shop_id | string | yes |
| origin | object | yes |
| destinations | array | yes |
| cargo | object | no |
| planned_start | datetime | yes |
| planned_end | datetime | no |

---

### 21. `update_trip_status`
เปลี่ยนสถานะเที่ยววิ่ง

**Parameters:** `shop_id`, `trip_id`, `status`

**Valid transitions:**
```
draft → pending → accepted → started → arrived → delivering → completed
                                                              ↳ cancelled
```

---

### 22. `assign_trip`
มอบหมายรถ + คนขับให้เที่ยว

**Parameters:** `shop_id`, `trip_id`, `driver_id`, `vehicle_id`

---

### 23. `calculate_route_cost`
คำนวณค่าขนส่งโดยใช้ Longdo Map API

**Parameters:** `shop_id`, `from_address`, `to_address`, `vehicle_type`, `weight_kg`

**Returns:** distance_km, duration_minutes, estimated_fuel_cost, toll_cost, suggested_price

---

### 24. `track_shipment`
ติดตาม GPS real-time ของเที่ยววิ่ง

**Parameters:** `shop_id`, `trip_id`

**Returns:** current_location, speed, status, eta, trail (จุด GPS ย้อนหลัง 1 ชั่วโมง)

---

### 25. `get_trip_pod`
ดูหลักฐานส่งมอบ (POD)

**Parameters:** `shop_id`, `trip_id`

**Returns:** photos, signature_url, receiver_name, notes, timestamp

---

### 26. `get_trip_cost_breakdown`
รายละเอียดต้นทุนต่อเที่ยว

**Parameters:** `shop_id`, `trip_id`

**Returns:** fuel, toll, driver_allowance, other, total_cost, revenue, profit, profit_margin

---

## Maintenance Tools (8 tools)

### 27. `list_maintenance_schedule`
ตารางซ่อมบำรุงที่ใกล้ถึงกำหนด

**Parameters:** `shop_id`, `days_ahead` (default: 30), `vehicle_id` (optional)

**Returns:** รายการที่ใกล้ถึงกำหนด เรียงตาม urgency

---

### 28. `create_work_order`
สร้างใบสั่งซ่อม

**Parameters:** `shop_id`, `vehicle_id`, `type`, `priority`, `description`, `parts`, `service_provider`

---

### 29. `get_work_order`
รายละเอียดใบสั่งซ่อม

**Parameters:** `shop_id`, `work_order_id`

---

### 30. `update_work_order`
อัปเดตใบสั่งซ่อม (เพิ่มอะไหล่, อัปเดตค่าใช้จ่าย)

**Parameters:** `shop_id`, `work_order_id` + fields ที่ต้องการแก้ไข

---

### 31. `approve_work_order`
อนุมัติใบสั่งซ่อม (AI Agent สามารถอนุมัติได้ตามเงื่อนไข)

**Parameters:** `shop_id`, `work_order_id`, `approved_by`, `notes`

**Business Rule:** AI อนุมัติอัตโนมัติได้เมื่อ total_cost < 5,000 บาท

---

### 32. `complete_work_order`
ปิดงาน + คิดเงิน + sync BC Account

**Parameters:** `shop_id`, `work_order_id`, `actual_cost`, `photos_after`

---

### 33. `get_maintenance_cost`
ต้นทุนซ่อมต่อคัน

**Parameters:** `shop_id`, `vehicle_id`, `period`

**Returns:** total_cost, by_type (preventive/corrective/emergency), by_month

---

### 34. `list_parts_inventory`
สต๊อกอะไหล่คงเหลือ

**Parameters:** `shop_id`, `low_stock_only` (boolean)

**Returns:** รายการอะไหล่ + qty_in_stock, min_qty, แจ้งเตือนเมื่อต่ำกว่า min

---

## Partner Tools (6 tools)

### 35. `register_partner_vehicle`
ลงทะเบียนรถร่วม

**Parameters:** `shop_id`, `owner`, `vehicle`, `driver`, `pricing`, `coverage_zones`

---

### 36. `list_partner_vehicles`
รายการรถร่วมทั้งหมด

**Parameters:** `shop_id`, `status`, `vehicle_type`, `zone`, `page`, `limit`

---

### 37. `find_available_partners`
ค้นหารถร่วมว่าง (AI Matching)

**Parameters:** `shop_id`, `zone`, `vehicle_type`, `weight_kg`, `date`

**Returns:** รายการรถร่วม เรียงตาม match score พร้อมเหตุผล

---

### 38. `create_partner_booking`
จองรถร่วม + ส่งงาน (แจ้ง LINE เจ้าของรถ)

**Parameters:** `shop_id`, `partner_id`, `trip_id`, `agreed_price`, `notes`

---

### 39. `get_partner_settlement`
รายการจ่ายเงินรถร่วม

**Parameters:** `shop_id`, `partner_id`, `month` (YYYY-MM)

**Returns:** รายการเที่ยว + ค่าจ้าง + หัก ณ ที่จ่าย + ยอดสุทธิ

---

### 40. `calculate_partner_payment`
คำนวณค่าจ้างรถร่วม + หัก ณ ที่จ่าย

**Parameters:** `shop_id`, `partner_id`, `trip_ids`

**Returns:** gross_amount, withholding_tax (1%), net_amount, breakdown per trip

---

## Dashboard Tools (6 tools)

### 41. `get_fleet_summary`
สรุปภาพรวมทั้งหมด

**Parameters:** `shop_id`, `date` (default: today)

**Returns:**
```json
{
  "vehicles": { "total": 12, "active": 10, "maintenance": 2 },
  "drivers": { "total": 8, "active": 7, "on_leave": 1 },
  "trips": { "today": 5, "completed": 3, "in_progress": 2 },
  "revenue_today": 25000,
  "cost_today": 8500,
  "profit_today": 16500,
  "active_alerts": 3
}
```

---

### 42. `get_fleet_kpi`
KPI metrics สำหรับ dashboard

**Parameters:** `shop_id`, `period` ("daily", "weekly", "monthly")

**Returns:**
- vehicle_utilization_rate (% รถที่วิ่งจริง)
- on_time_delivery_rate (% ส่งตรงเวลา)
- average_fuel_efficiency (km/L)
- cost_per_km (บาท/km)
- revenue_per_vehicle (บาท/คัน)
- top_driver_score

---

### 43. `get_active_alerts`
แจ้งเตือนที่ยัง active ทั้งหมด

**Parameters:** `shop_id`, `severity` (optional), `type` (optional)

**Returns:** รายการ alerts เรียงตาม severity + days_remaining

---

### 44. `get_cost_report`
รายงานต้นทุนขนส่ง

**Parameters:** `shop_id`, `period`, `vehicle_id` (optional), `group_by` ("vehicle", "driver", "date")

**Returns:** ต้นทุนแยกตาม fuel, toll, maintenance, partner, total

---

### 45. `get_fuel_report`
รายงานน้ำมัน + อัตราสิ้นเปลือง

**Parameters:** `shop_id`, `period`, `vehicle_id` (optional)

**Returns:** total_liters, total_cost, avg_price_per_liter, km_per_liter, fuel_by_vehicle

---

### 46. `get_driver_leaderboard`
อันดับคนขับตาม KPI score

**Parameters:** `shop_id`, `period`, `limit` (default: 10)

**Returns:** รายชื่อคนขับ เรียง score สูงสุด พร้อม breakdown

---

## MCP Request Format

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_fleet_summary",
    "arguments": {
      "shop_id": "shop_001",
      "date": "2024-12-15"
    }
  },
  "id": 1
}
```

## MCP Response Format

```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"vehicles\":{\"total\":12,...}}"
      }
    ]
  },
  "id": 1
}
```
