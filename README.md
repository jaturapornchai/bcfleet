# 🚛 SML Fleet — ระบบควบคุมรถขนส่งครบวงจรสำหรับ SME ไทย

> โมดูลขยายจาก BC Account ERP — บริหารจัดการรถ คนขับ เที่ยววิ่ง ซ่อมบำรุง รถร่วม ต้นทุน ทั้งหมดในที่เดียว

## 🌐 Demo

**https://smlfleet.satistang.com**

| URL | ระบบ | สำหรับ |
|-----|------|--------|
| [smlfleet.satistang.com](https://smlfleet.satistang.com) | Landing Page | หน้าแรก เลือกระบบ |
| [/dashboard/](https://smlfleet.satistang.com/dashboard/) | Web Dashboard | แอดมิน / ฝ่ายบัญชี |
| [/boss/](https://smlfleet.satistang.com/boss/) | Boss App (Web) | เจ้าของ / ผู้จัดการ |
| [/driver/](https://smlfleet.satistang.com/driver/) | Driver App (Web) | คนขับรถ |
| [/health](https://smlfleet.satistang.com/health) | Health Check | API Status |
| [/docs/](https://smlfleet.satistang.com/docs/index.html) | Documentation | Showcase + API Docs |

## 📊 สถาปัตยกรรม

```
Flutter/Web/LINE → Go API (Gin) → MongoDB (Source of Truth)
                                          ↓ Kafka Event
                                   PostgreSQL (Query Layer)
```

- **Write**: API → MongoDB → Kafka → PostgreSQL
- **Read**: API → PostgreSQL (เร็ว, JOIN ได้)
- **Rebuild**: PostgreSQL สามารถ DROP แล้ว rebuild จาก MongoDB ได้ทุกเมื่อ

## 🏗️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend API | Go 1.23 (Gin) |
| Primary DB | MongoDB 7 |
| Query DB | PostgreSQL 16 |
| Stream | Apache Kafka (KRaft) |
| Mobile + Web | Flutter 3.24 |
| Maps | OpenStreetMap (flutter_map) — ฟรี ไม่ต้อง Key |
| AI | Claude API (MCP) |
| Storage | Cloudflare R2 |
| LINE Bot | LINE Messaging API |
| Payment | PromptPay + Stripe |
| Reverse Proxy | Caddy 2 (Auto SSL) |

## 📱 6 แอปพลิเคชัน

| # | App | Platform | หน้าจอ |
|---|-----|----------|--------|
| 1 | **Go Backend API** | Docker | 60+ REST endpoints, 46 MCP tools |
| 2 | **Driver App** | Flutter (iOS/Android/Web) | 10 screens — รับงาน, GPS, POD, เช็คลิสต์ |
| 3 | **Boss App** | Flutter (iOS/Android/Web) | 10 screens — Dashboard, Map, อนุมัติ |
| 4 | **Web Dashboard** | Flutter Web | 15+ screens — DataTable, Reports, Export |
| 5 | **LINE OA Chatbot** | Go + Claude AI | AI Agent ตอบลูกค้าอัตโนมัติ |
| 6 | **UCP Gateway** | Go | A2A protocol สำหรับ AI agents ภายนอก |

## 🔧 MCP Tools (46 tools)

| กลุ่ม | จำนวน | ตัวอย่าง |
|-------|--------|---------|
| Vehicle | 8 | list_vehicles, get_vehicle_health, get_vehicle_cost |
| Driver | 10 | get_driver_score, calculate_driver_salary, suggest_best_driver |
| Trip | 8 | create_trip, track_shipment, get_trip_cost_breakdown |
| Maintenance | 8 | create_work_order, approve_work_order, list_parts_inventory |
| Partner | 6 | find_available_partners, calculate_partner_payment |
| Dashboard | 6 | get_fleet_summary, get_fleet_kpi, get_driver_leaderboard |

## 🚀 Quick Start

### Prerequisites
- Docker + Docker Compose
- Go 1.23+ (สำหรับ local dev)
- Flutter 3.24+ (สำหรับ mobile/web)
- PostgreSQL 16+

### Run with Docker

```bash
# 1. Clone
git clone https://github.com/jaturapornchai/smlfleet.git
cd smlfleet

# 2. Start infrastructure
docker compose up -d mongodb postgres kafka

# 3. Run migrations
for f in backend/migrations/postgres/*.sql; do
  psql -h localhost -U smlfleet -d smlfleet -f "$f"
done

# 4. Build & Start API
docker compose up -d api kafka-consumer

# 5. Check
curl http://localhost:8081/health
```

### Run Flutter Web (local)

```bash
# Dashboard
cd flutter/web_dashboard
flutter pub get
flutter run -d chrome

# Boss App
cd flutter/boss_app
flutter pub get
flutter run -d chrome

# Driver App
cd flutter/driver_app
flutter pub get
flutter run -d chrome
```

## 📁 โครงสร้างโปรเจค

```
sml-fleet/
├── backend/                    # Go Backend (82 Go files)
│   ├── cmd/                    # Entry points (api, kafka-consumer, rebuild)
│   ├── internal/
│   │   ├── config/             # Configuration
│   │   ├── database/           # MongoDB, PostgreSQL, Kafka connections
│   │   ├── models/             # Domain models (8 files)
│   │   ├── repository/mongo/   # Write operations (7 repos)
│   │   ├── repository/postgres/# Read operations (9 queries)
│   │   ├── service/            # Business logic (10 services)
│   │   ├── handler/            # HTTP handlers (9 handlers)
│   │   ├── kafka/              # Producer, Consumer, Sync, Rebuild
│   │   ├── mcp/                # MCP Server + 46 tools
│   │   ├── line/               # LINE OA Bot + AI Agent
│   │   ├── ucp/                # UCP Gateway + A2A
│   │   ├── longdo/             # Longdo Map integration
│   │   └── r2/                 # Cloudflare R2 storage
│   └── migrations/postgres/    # 9 SQL files
├── flutter/
│   ├── packages/fleet_core/    # Shared models + services (16 files)
│   ├── driver_app/             # Driver App (20 files)
│   ├── boss_app/               # Boss App (23 files)
│   └── web_dashboard/          # Web Dashboard (25 files)
├── scripts/                    # Deploy, seed, rebuild, kafka-topics
├── docs/                       # API.md, DATABASE.md, MCP-TOOLS.md, index.html
├── landing/                    # Landing page
├── docker-compose.yml
├── Makefile
└── CLAUDE.md                   # PRD (Project Requirements Document)
```

## 🎯 คุณสมบัติหลัก

### ทะเบียนรถ (Vehicle Management)
- รองรับ: 4ล้อ, 6ล้อ, 10ล้อ, หัวลาก, กระบะ
- สุขภาพรถ: เขียว/เหลือง/แดง — ประกัน/ภาษี/พ.ร.บ. แจ้งเตือนก่อนหมดอายุ
- ประวัติซ่อมบำรุง + เอกสาร (เก็บใน R2)

### คนขับ (Driver Management)
- KPI Score 0-100 (ตรงเวลา, ประหยัดน้ำมัน, Rating ลูกค้า)
- ตารางเวร + วันลา + OT + คำนวณเงินเดือนอัตโนมัติ
- AI แนะนำคนขับที่เหมาะสม

### เที่ยววิ่ง (Trip Management)
- สร้าง → มอบหมาย → ติดตาม GPS → ส่งมอบ POD
- ต้นทุนต่อเที่ยว: น้ำมัน + ทางด่วน + คนขับ = กำไร/ขาดทุน
- POD: รูปถ่าย + ลายเซ็นดิจิทัลผู้รับ

### GPS Tracking Real-time
- แผนที่ OpenStreetMap (ฟรี ไม่ต้อง API Key)
- GPS จาก Driver App ทุก 30 วินาที + Markers ทะเบียนรถ
- เส้นทางย้อนหลัง + แจ้งเตือน Geofence/ขับเร็ว

### ซ่อมบำรุง (Maintenance)
- ใบสั่งซ่อม: ซ่อมตามรอบ / ตามอาการ / ฉุกเฉิน
- Approval flow + คิดค่าอะไหล่+แรง + สต๊อกอะไหล่

### รถร่วม (Partner Vehicles)
- ลงทะเบียนรถร่วม + ราคาต่อเที่ยว/กม./วัน
- AI Matching Score 100 คะแนน + จ่ายเงิน + หัก ณ ที่จ่าย

### แจ้งเตือนอัตโนมัติ (7 ประเภท)
- ประกัน / ภาษี / พ.ร.บ. / ใบขับขี่ / ซ่อมบำรุง / ขับเร็ว / Geofence

### AI Agent + LINE Bot
- Claude AI + 46 MCP Tools — ตอบลูกค้าอัตโนมัติ
- ค้นหารถว่าง คำนวณราคา จองเที่ยว ผ่าน LINE

### UCP + A2A Gateway
- AI จากระบบอื่นจองรถได้ (Claude Desktop, OpenClaw, HiClaw)
- PromptPay + Stripe payment

### ต้นทุนขนส่ง (Cost Analysis)
- P&L ต่อคัน/เดือน + รายงานน้ำมัน + Export Excel/PDF

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| Total Files | 198 |
| Go Files | 82 |
| Dart Files | 84 |
| SQL Files | 9 |
| API Endpoints | 60+ |
| MCP Tools | 46 |
| MongoDB Collections | 10 |
| PostgreSQL Tables | 8 + 2 views |
| Kafka Topics | 10 |

## 📄 License

Private — BC AI Solution Co., Ltd.
