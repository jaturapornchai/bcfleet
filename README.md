# SML Fleet — AI-Powered Fleet Management for Thai SME

> ระบบควบคุมรถขนส่งครบวงจร + **HiClaw AI Agent Team** + **Movement Intelligence** — CEO สั่งงาน Workers ทำงานอัตโนมัติ ผ่าน 47 MCP Tools + ตรวจจับรถเคลื่อนที่ทุก 1 นาที

## Demo

**https://smlfleet.satistang.com**

| URL | ระบบ | สำหรับ |
|-----|------|--------|
| [smlfleet.satistang.com](https://smlfleet.satistang.com) | Landing Page | หน้าแรก |
| [/dashboard/](https://smlfleet.satistang.com/dashboard/) | Web Dashboard | แอดมิน / ฝ่ายบัญชี |
| [/boss/](https://smlfleet.satistang.com/boss/) | Boss App | เจ้าของ / ผู้จัดการ |
| [/driver/](https://smlfleet.satistang.com/driver/) | Driver App | คนขับรถ |
| [/health](https://smlfleet.satistang.com/health) | Health Check | API Status |

## HiClaw AI Agent Team

SML Fleet ขับเคลื่อนด้วย **HiClaw** — AI Agent orchestration platform ที่ทำงานเป็นทีม:

```
Admin (Matrix Chat) → CEO วิเคราะห์ → แจกงาน Workers → MCP Tools → SML Fleet API
```

### 4 AI Workers

| Agent | ชื่อเล่น | หน้าที่ | Tools |
|-------|----------|---------|-------|
| **fleet-ceo** | บอส | สั่งงาน ตามงาน ตัดสินใจ สรุปรายงาน | 47 tools |
| **fleet-ops** | แอดมินรถ | จัดการรถ คนขับ เที่ยววิ่ง GPS **+ Movement Intelligence** | 20 tools |
| **fleet-maint** | ช่าง | ซ่อมบำรุง อะไหล่ แจ้งเตือนประกัน/ภาษี | 12 tools |
| **fleet-cs** | พี่บริการ | จอง ค้นหารถว่าง ติดตาม รถร่วม | 15 tools |

### HiClaw Architecture

```
┌─────────────────────────────────────────────────┐
│  HiClaw Manager                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ fleet-ceo│  │fleet-ops │  │fleet-maint│ ...  │
│  │ (CEO)    │  │(Ops)     │  │(Maint)   │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       └──────────────┼──────────────┘            │
│                      ▼                           │
│           ┌─────────────────┐                    │
│           │ Higress Gateway │ ← AI Gateway       │
│           │  47 MCP Tools   │                    │
│           └────────┬────────┘                    │
│                    ▼                             │
│           ┌─────────────────┐                    │
│           │ SML Fleet API   │ ← Go (Gin)        │
│           │  (smlfleet-api) │                    │
│           └────────┬────────┘                    │
└────────────────────┼────────────────────────────┘
                     ▼
        MongoDB → Kafka → PostgreSQL
```

### Movement Intelligence (AI อัตโนมัติ)

HiClaw fleet-ops ตรวจจับรถเคลื่อนที่ **ทุก 1 นาที** — วิเคราะห์ด้วย AI ส่ง Kafka → MongoDB log

```
Infinite Task (*/1 * * * *)
  → get_moving_vehicles (Haversine > 50m)
  → AI วิเคราะห์ + อ่าน monitoring_prompt ของรถ
  → publish_movement_analysis → Kafka → MongoDB
  → Auto-alert ถ้า warning/critical
```

| Event Type | ความหมาย | Severity |
|-----------|---------|----------|
| `movement.started` | รถเพิ่งเริ่มวิ่ง | info |
| `speeding` | ขับเร็วเกิน 90 กม./ชม. | warning |
| `geofence.exit` | ออกนอกพื้นที่ | warning |
| `night.movement` | วิ่งกลางคืนไม่มี trip | warning |
| `erratic.driving` | speed เปลี่ยนเร็วผิดปกติ | critical |

**monitoring_prompt**: กำหนด AI rules ต่อรถแต่ละคัน เช่น "ห้ามเกิน 80 กม./ชม. บรรทุกสารเคมี"

### OSRM Routing (เส้นทางตามถนน)

คำนวณเส้นทางจริงบนถนน — polyline + turn-by-turn navigation ภาษาไทย

```
POST /api/v1/fleet/trips/calculate-route
→ OSRM Demo Server (router.project-osrm.org)
→ ระยะทาง + เวลา + polyline + steps + waypoints
```

พร้อมอัปเกรดเป็น **Valhalla** self-hosted (map matching, isochrone, truck profile)

### MCP Tools (47 tools)

| กลุ่ม | จำนวน | ตัวอย่าง |
|-------|--------|---------|
| Vehicle | 8 | `list_vehicles`, `get_vehicle_health`, `get_vehicle_cost` |
| Driver | 6 | `get_driver_score`, `calculate_driver_salary`, `check_driver_schedule` |
| Trip | 9 | `create_trip`, `assign_trip`, `track_shipment`, **`calculate_route`** (OSRM) |
| Maintenance | 6 | `create_work_order`, `approve_work_order`, `list_parts_inventory` |
| Partner | 4 | `find_available_partners`, `create_partner_booking` |
| Expense | 3 | `create_expense`, `get_fuel_report` |
| GPS & Movement | 5 | `get_moving_vehicles`, **`publish_movement_analysis`**, `get_movement_events` |
| Dashboard | 6 | `get_fleet_summary`, `get_fleet_kpi`, `get_driver_leaderboard` |

## Data Architecture

```
Flutter/Web → Go API (Gin) → MongoDB (Source of Truth)
                                     ↓ Kafka Event
                              PostgreSQL (Query Layer)
```

- **Write**: API → MongoDB → Kafka → PostgreSQL
- **Read**: API → PostgreSQL (เร็ว, JOIN ได้)
- **Rebuild**: PostgreSQL สามารถ DROP แล้ว rebuild จาก MongoDB ได้ทุกเมื่อ

## Tech Stack

| Component | Technology | หมายเหตุ |
|-----------|-----------|----------|
| **AI Orchestration** | **HiClaw v1.0.8** | Manager-Worker AI agents |
| **AI Gateway** | **Higress** | MCP Tools routing + auth |
| **Agent Chat** | **Matrix (Element Web)** | AI สื่อสารกันผ่าน rooms |
| **Multi-LLM** | **Gemini Flash / Claude / GPT** | ผ่าน OpenRouter |
| Backend API | Go 1.23 (Gin) | 60+ REST endpoints |
| Primary DB | MongoDB 7 | Source of truth |
| Query DB | PostgreSQL 16 | JOIN, aggregate, report |
| Stream | Apache Kafka (KRaft) | Event-driven sync |
| Mobile + Web | Flutter 3.41 | iOS/Android/Web |
| Maps | OpenStreetMap | ฟรี ไม่ต้อง API Key |
| **Routing** | **OSRM** | เส้นทางตามถนนจริง (พร้อมอัปเกรด Valhalla) |
| File Storage | Cloudflare R2 | รูป POD, เอกสาร |
| Reverse Proxy | Caddy 2 | Auto SSL (Let's Encrypt) |

## Apps

| # | App | Platform | หน้าจอ |
|---|-----|----------|--------|
| 1 | **Go Backend API** | Docker | 60+ REST endpoints, 47 MCP tools |
| 2 | **Driver App** | Flutter Web/iOS/Android | รับงาน, GPS, POD, เช็คลิสต์ |
| 3 | **Boss App** | Flutter Web/iOS/Android | Dashboard, Map, อนุมัติ |
| 4 | **Web Dashboard** | Flutter Web | DataTable, Reports, Export |
| 5 | **HiClaw AI Team** | Matrix Chat | 4 AI Workers, 47 MCP Tools |

## Quick Start

### Prerequisites
- Docker + Docker Compose
- Go 1.23+ (สำหรับ local dev)
- Flutter 3.41+ (สำหรับ mobile/web)
- PostgreSQL 16+

### Run with Docker

```bash
git clone https://github.com/jaturapornchai/bcfleet.git
cd bcfleet
docker compose up -d
curl http://localhost:8082/health
```

### Chat with AI Team

เข้า Element Web → login → พิมพ์ภาษาไทยในห้อง fleet-ceo:
- "สรุปภาพรวมกองรถวันนี้"
- "รถว่างมีกี่คัน"
- "คำนวณค่าส่งเชียงใหม่ไปลำพูน"

## Features

- **Vehicle Management** — ลงทะเบียน สุขภาพรถ ประกัน/ภาษี/พ.ร.บ.
- **Driver Management** — KPI Score, ตารางเวร, เงินเดือนอัตโนมัติ
- **Trip Management** — สร้าง → มอบหมาย → GPS ติดตาม → POD
- **GPS Real-time** — OpenStreetMap ฟรี, Markers, Trail
- **Movement Intelligence** — AI ตรวจจับรถเคลื่อนที่ทุก 1 นาที, speeding, geofence, night movement
- **OSRM Routing** — เส้นทางตามถนนจริง, polyline, turn-by-turn ภาษาไทย
- **monitoring_prompt** — กำหนด AI rules ต่อรถแต่ละคัน
- **Maintenance** — ใบสั่งซ่อม, Approval flow, สต๊อกอะไหล่
- **Partner Vehicles** — รถร่วม, AI Matching, หัก ณ ที่จ่าย
- **Alerts** — 7+ ประเภท แจ้งเตือนอัตโนมัติ + AI movement alerts
- **Cost Analysis** — P&L ต่อคัน, รายงานน้ำมัน, Export Excel/PDF

## Project Stats

| Metric | Value |
|--------|-------|
| AI Workers | 4 (CEO, Ops, Maint, CS) |
| MCP Tools | 47 |
| API Endpoints | 60+ |
| Movement Event Types | 8 (speeding, geofence, night, erratic, ...) |
| Go Files | 82 |
| Dart Files | 84 |
| MongoDB Collections | 11 (+fleet_movement_events) |
| PostgreSQL Tables | 8 + 2 views |
| Kafka Topics | 11 (+fleet.movement.analysis) |

## License

Private — BC AI Solution Co., Ltd.
