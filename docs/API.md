# BC Fleet API Documentation

## Base URL
```
http://localhost:8080/api/v1/fleet
```

## Authentication
ทุก request ต้องมี JWT token:
```
Authorization: Bearer <token>
```

## Endpoints

### Vehicles (ทะเบียนรถ)
| Method | Path | Description |
|--------|------|-------------|
| GET | /vehicles | รายการรถ (?status=active&type=6ล้อ&page=1&limit=20) |
| GET | /vehicles/:id | ข้อมูลรถ |
| POST | /vehicles | สร้างรถใหม่ |
| PUT | /vehicles/:id | อัปเดตรถ |
| DELETE | /vehicles/:id | ลบรถ (soft) |
| GET | /vehicles/:id/health | สุขภาพรถ (green/yellow/red) |
| GET | /vehicles/:id/history | ประวัติทั้งหมด |

### Drivers (คนขับ)
| Method | Path | Description |
|--------|------|-------------|
| GET | /drivers | รายการคนขับ |
| GET | /drivers/:id | ข้อมูลคนขับ |
| POST | /drivers | สร้างคนขับใหม่ |
| PUT | /drivers/:id | อัปเดตคนขับ |
| DELETE | /drivers/:id | ลบคนขับ (soft) |
| GET | /drivers/:id/score | KPI score |
| GET | /drivers/:id/schedule | ตารางเวร |
| GET | /drivers/:id/salary | คำนวณเงินเดือน |

### Trips (เที่ยววิ่ง)
| Method | Path | Description |
|--------|------|-------------|
| GET | /trips | รายการเที่ยววิ่ง |
| GET | /trips/:id | รายละเอียดเที่ยว |
| POST | /trips | สร้างเที่ยวใหม่ |
| PUT | /trips/:id | อัปเดตเที่ยว |
| PUT | /trips/:id/status | เปลี่ยนสถานะ |
| POST | /trips/:id/assign | มอบหมายคนขับ+รถ |
| POST | /trips/:id/pod | อัปโหลด POD |
| GET | /trips/:id/tracking | GPS tracking |

### Maintenance (ซ่อมบำรุง)
| Method | Path | Description |
|--------|------|-------------|
| GET | /maintenance/schedule | ตารางซ่อมบำรุง |
| GET | /maintenance/due | รายการใกล้ถึงกำหนด |
| POST | /maintenance/work-orders | สร้างใบสั่งซ่อม |
| GET | /maintenance/work-orders | รายการใบสั่งซ่อม |
| GET | /maintenance/work-orders/:id | รายละเอียด |
| PUT | /maintenance/work-orders/:id | อัปเดต |
| PUT | /maintenance/work-orders/:id/approve | อนุมัติ |
| PUT | /maintenance/work-orders/:id/complete | ปิดงาน |

### Partners (รถร่วม)
| Method | Path | Description |
|--------|------|-------------|
| GET | /partners | รายการรถร่วม |
| POST | /partners | ลงทะเบียนรถร่วม |
| POST | /partners/find-available | ค้นหารถร่วมว่าง |
| POST | /partners/book | จองรถร่วม |

### Expenses (ค่าใช้จ่าย)
| Method | Path | Description |
|--------|------|-------------|
| GET | /expenses | รายการค่าใช้จ่าย |
| POST | /expenses | บันทึกค่าใช้จ่าย |
| GET | /expenses/fuel-report | รายงานน้ำมัน |
| GET | /expenses/pl/:vehicle_id | P&L ต่อคัน |

### GPS
| Method | Path | Description |
|--------|------|-------------|
| POST | /gps/location | รับ GPS จาก driver app |
| GET | /gps/vehicles | ตำแหน่งรถทุกคัน |
| GET | /gps/vehicle/:id/trail | เส้นทางย้อนหลัง |

### Dashboard & Reports
| Method | Path | Description |
|--------|------|-------------|
| GET | /dashboard/summary | สรุปภาพรวม |
| GET | /dashboard/kpi | KPI metrics |
| GET | /dashboard/alerts | แจ้งเตือน |
| GET | /reports/cost-per-trip | ต้นทุนต่อเที่ยว |
| GET | /reports/vehicle-utilization | อัตราใช้รถ |
| GET | /reports/fuel-efficiency | ประสิทธิภาพน้ำมัน |
| GET | /reports/driver-performance | ผลงานคนขับ |

## Data Flow
```
Write: Client → Go API → MongoDB → Kafka → PostgreSQL
Read:  Client → Go API → PostgreSQL
```
