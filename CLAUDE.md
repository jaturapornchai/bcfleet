# BC Fleet — Project Requirements Document (PRD)
# ระบบควบคุมรถขนส่งครบวงจรสำหรับ SME ไทย
# Version 1.0 — สำหรับ Claude Code

---

## สารบัญ

1. [ภาพรวมโปรเจค](#1-ภาพรวมโปรเจค)
2. [สถาปัตยกรรมข้อมูล MongoDB → Kafka → PostgreSQL](#2-สถาปัตยกรรมข้อมูล)
3. [โครงสร้าง Folder ทั้งหมด](#3-โครงสร้าง-folder)
4. [App 1: Go Backend API + MCP Server](#4-app-1-go-backend-api)
5. [App 2: Flutter Driver App](#5-app-2-flutter-driver-app)
6. [App 3: Flutter Boss App](#6-app-3-flutter-boss-app)
7. [App 4: Web Dashboard](#7-app-4-web-dashboard)
8. [App 5: LINE OA Chatbot](#8-app-5-line-oa-chatbot)
9. [App 6: UCP + A2A Gateway](#9-app-6-ucp-a2a-gateway)
10. [MongoDB Collections (Source of Truth)](#10-mongodb-collections)
11. [Kafka Topics + Consumer → PostgreSQL](#11-kafka-topics)
12. [PostgreSQL Tables (Query Layer)](#12-postgresql-tables)
13. [MCP Tools (46 tools ใหม่)](#13-mcp-tools)
14. [UCP Manifest + Endpoints](#14-ucp-manifest)
15. [External Services Configuration](#15-external-services)
16. [Docker Compose](#16-docker-compose)
17. [Build Order (ลำดับการสร้าง)](#17-build-order)

---

## 1. ภาพรวมโปรเจค

### ชื่อ: BC Fleet
### คำอธิบาย: โมดูลขยายจาก BC Account ERP สำหรับบริหารจัดการรถขนส่ง SME ไทย

### หลักการสถาปัตยกรรมข้อมูล

```
MongoDB (Source of Truth) → Kafka (Stream) → PostgreSQL (Query Layer)
```

- **MongoDB เก็บทุกอย่าง** — ทุก document, ทุก event, ทุก log จะถูกเขียนลง MongoDB ก่อนเสมอ
- **Kafka stream แบบ real-time** — ทุก write ที่เกิดใน MongoDB จะ produce event ไป Kafka
- **PostgreSQL เป็น read-optimized view** — Kafka consumer อ่าน event แล้ว upsert ลง PostgreSQL
- **PostgreSQL สามารถ DROP แล้ว rebuild ใหม่ได้เสมอ** — เพราะ MongoDB มี data ครบ 100%
- **API อ่านจาก PostgreSQL** (เร็ว, JOIN ได้) **แต่เขียนลง MongoDB** (flexible schema, event log)

### Tech Stack

| Component | Technology | เหตุผล |
|-----------|-----------|--------|
| Backend API | Go 1.22+ (Gin framework) | ทีมมีความชำนาญ, performance สูง |
| Primary DB | MongoDB 7+ | Source of truth, flexible schema, event sourcing |
| Query DB | PostgreSQL 16+ | JOIN, aggregate, report, analytics |
| Stream | Apache Kafka (KRaft mode) | Real-time sync MongoDB → PostgreSQL |
| Mobile Apps | Flutter 3.24+ (Dart) | iOS + Android จาก codebase เดียว |
| Web Dashboard | Flutter Web | แชร์ components กับ mobile apps |
| LINE Bot | Go (Gin) — module ใน backend | ใช้ LINE Messaging API |
| Map | Longdo Map API v3 | แผนที่ไทยถูกกว่า Google Maps, เริ่มฟรี |
| Object Storage | Cloudflare R2 | เก็บรูป POD/เอกสาร, ไม่มีค่า egress |
| AI | Claude API (Haiku/Sonnet) | ภาษาไทยดี, MCP native |
| Payment | PromptPay QR + Stripe | PromptPay ฟรี, Stripe สำหรับ UCP |

---

## 2. สถาปัตยกรรมข้อมูล

### Data Flow

```
[Flutter/Web/LINE] → [Go API] → [MongoDB] → [Kafka Producer]
                                                    ↓
                                            [Kafka Topic]
                                                    ↓
                                            [Kafka Consumer (Go)]
                                                    ↓
                                            [PostgreSQL upsert]
                                                    ↓
                        [Go API reads from PostgreSQL for queries]
```

### Write Path (ทุก write operation)

```go
// 1. เขียนลง MongoDB ก่อน (source of truth)
result, err := mongoCollection.InsertOne(ctx, document)

// 2. Produce event ไป Kafka
event := KafkaEvent{
    Type:      "vehicle.created",
    Payload:   document,
    Timestamp: time.Now(),
    ShopID:    shopID,
    EventID:   uuid.New().String(),
}
producer.Produce("fleet.vehicles", event)
```

### Read Path (ทุก read/query operation)

```go
// อ่านจาก PostgreSQL เสมอ (เร็วกว่า, JOIN ได้)
rows, err := pgDB.Query(ctx, `
    SELECT v.*, d.name as driver_name 
    FROM fleet_vehicles v 
    LEFT JOIN fleet_drivers d ON v.current_driver_id = d.id
    WHERE v.shop_id = $1 AND v.status = 'active'
`, shopID)
```

### Rebuild PostgreSQL จาก MongoDB

```bash
# สคริปต์ rebuild — สามารถรันได้ทุกเมื่อ
./scripts/rebuild-pgsql.sh

# ขั้นตอนภายใน:
# 1. DROP ทุก fleet_* tables ใน PostgreSQL
# 2. CREATE tables ใหม่ (schema migration)
# 3. อ่าน MongoDB ทุก collection ที่ขึ้นต้นด้วย fleet_
# 4. Transform + INSERT ลง PostgreSQL
# 5. อัปเดต sequences/indexes
```

### Kafka Consumer → PostgreSQL (Go service)

```go
// consumer/fleet_sync.go
func (c *FleetSyncConsumer) HandleEvent(event KafkaEvent) error {
    switch event.Type {
    case "vehicle.created", "vehicle.updated":
        return c.upsertVehicle(event.Payload)
    case "vehicle.deleted":
        return c.softDeleteVehicle(event.Payload)
    case "trip.created":
        return c.upsertTrip(event.Payload)
    case "maintenance.work_order_created":
        return c.upsertWorkOrder(event.Payload)
    case "driver.created", "driver.updated":
        return c.upsertDriver(event.Payload)
    case "partner.vehicle_registered":
        return c.upsertPartnerVehicle(event.Payload)
    case "gps.location_updated":
        return c.updateVehicleLocation(event.Payload) // high frequency
    case "expense.recorded":
        return c.upsertExpense(event.Payload)
    // ... etc
    }
    return nil
}
```

### MongoDB Event Log (เก็บทุก event ไม่ลบ)

```go
// ทุก operation จะเก็บ event log ด้วยเสมอ
type EventLog struct {
    ID        primitive.ObjectID `bson:"_id,omitempty"`
    ShopID    string             `bson:"shop_id"`
    EventType string             `bson:"event_type"`
    Entity    string             `bson:"entity"`      // "vehicle", "driver", "trip"
    EntityID  string             `bson:"entity_id"`
    Action    string             `bson:"action"`      // "create", "update", "delete"
    Payload   bson.M             `bson:"payload"`     // full document snapshot
    Diff      bson.M             `bson:"diff"`        // what changed (for updates)
    UserID    string             `bson:"user_id"`     // who did it
    UserType  string             `bson:"user_type"`   // "admin", "driver", "system", "ai_agent"
    IP        string             `bson:"ip"`
    CreatedAt time.Time          `bson:"created_at"`
}
// Collection: fleet_event_logs (TTL index: optional, keep forever by default)
```

---

## 3. โครงสร้าง Folder ทั้งหมด

```
bc-fleet/
├── README.md
├── docker-compose.yml
├── docker-compose.dev.yml
├── .env.example
├── Makefile
│
├── backend/                          # Go Backend API + MCP + Kafka
│   ├── cmd/
│   │   ├── api/                      # main API server
│   │   │   └── main.go
│   │   ├── kafka-consumer/           # Kafka → PostgreSQL sync service
│   │   │   └── main.go
│   │   ├── rebuild-pgsql/            # MongoDB → PostgreSQL rebuild tool
│   │   │   └── main.go
│   │   └── line-webhook/             # LINE OA webhook handler
│   │       └── main.go
│   ├── internal/
│   │   ├── config/                   # Configuration (env, secrets)
│   │   │   └── config.go
│   │   ├── middleware/               # Auth, CORS, RateLimit, ShopContext
│   │   │   ├── auth.go
│   │   │   ├── cors.go
│   │   │   ├── ratelimit.go
│   │   │   └── shop_context.go       # multi-tenant shop_id injection
│   │   ├── database/
│   │   │   ├── mongodb.go            # MongoDB connection + helpers
│   │   │   ├── postgres.go           # PostgreSQL connection + helpers
│   │   │   └── kafka.go              # Kafka producer + consumer
│   │   ├── eventlog/                 # Event logging to MongoDB
│   │   │   └── logger.go
│   │   ├── models/                   # Shared domain models
│   │   │   ├── vehicle.go
│   │   │   ├── driver.go
│   │   │   ├── trip.go
│   │   │   ├── maintenance.go
│   │   │   ├── partner_vehicle.go
│   │   │   ├── expense.go
│   │   │   ├── gps_log.go
│   │   │   └── event_log.go
│   │   ├── repository/               # Data access layer
│   │   │   ├── mongo/                # MongoDB repositories (WRITE)
│   │   │   │   ├── vehicle_repo.go
│   │   │   │   ├── driver_repo.go
│   │   │   │   ├── trip_repo.go
│   │   │   │   ├── maintenance_repo.go
│   │   │   │   ├── partner_repo.go
│   │   │   │   ├── expense_repo.go
│   │   │   │   └── gps_repo.go
│   │   │   └── postgres/            # PostgreSQL repositories (READ)
│   │   │       ├── vehicle_query.go
│   │   │       ├── driver_query.go
│   │   │       ├── trip_query.go
│   │   │       ├── maintenance_query.go
│   │   │       ├── partner_query.go
│   │   │       ├── expense_query.go
│   │   │       ├── dashboard_query.go
│   │   │       └── report_query.go
│   │   ├── service/                  # Business logic
│   │   │   ├── vehicle_service.go
│   │   │   ├── driver_service.go
│   │   │   ├── trip_service.go
│   │   │   ├── maintenance_service.go
│   │   │   ├── partner_service.go
│   │   │   ├── expense_service.go
│   │   │   ├── gps_service.go
│   │   │   ├── alert_service.go      # แจ้งเตือน พ.ร.บ./ภาษี/ซ่อม
│   │   │   ├── matching_service.go   # AI จับคู่รถร่วม
│   │   │   └── dashboard_service.go
│   │   ├── handler/                  # HTTP handlers (Gin)
│   │   │   ├── vehicle_handler.go
│   │   │   ├── driver_handler.go
│   │   │   ├── trip_handler.go
│   │   │   ├── maintenance_handler.go
│   │   │   ├── partner_handler.go
│   │   │   ├── expense_handler.go
│   │   │   ├── gps_handler.go
│   │   │   ├── dashboard_handler.go
│   │   │   └── upload_handler.go     # R2 upload
│   │   ├── mcp/                      # MCP Server (JSON-RPC)
│   │   │   ├── server.go             # MCP protocol handler
│   │   │   ├── tools.go              # Tool registry
│   │   │   └── fleet_tools/          # Fleet-specific MCP tools
│   │   │       ├── vehicle_tools.go
│   │   │       ├── driver_tools.go
│   │   │       ├── trip_tools.go
│   │   │       ├── maintenance_tools.go
│   │   │       ├── partner_tools.go
│   │   │       ├── expense_tools.go
│   │   │       └── dashboard_tools.go
│   │   ├── ucp/                      # UCP Gateway
│   │   │   ├── manifest.go           # UCP JSON manifest
│   │   │   ├── discovery.go          # service catalog
│   │   │   ├── cart.go               # booking/checkout
│   │   │   ├── fulfillment.go        # tracking/POD
│   │   │   └── identity.go           # merchant profile
│   │   ├── line/                     # LINE OA integration
│   │   │   ├── webhook.go            # LINE webhook handler
│   │   │   ├── messaging.go          # Send messages (Flex, Text, etc)
│   │   │   ├── rich_menu.go          # Rich menu management
│   │   │   └── ai_agent.go           # AI Agent (Claude) ← MCP tools
│   │   ├── longdo/                   # Longdo Map API client
│   │   │   ├── client.go
│   │   │   ├── geocoding.go
│   │   │   ├── routing.go
│   │   │   └── search.go
│   │   ├── r2/                       # Cloudflare R2 client
│   │   │   └── client.go
│   │   └── kafka/                    # Kafka sync logic
│   │       ├── producer.go
│   │       ├── consumer.go
│   │       └── fleet_sync.go         # MongoDB event → PostgreSQL upsert
│   ├── migrations/
│   │   └── postgres/                 # PostgreSQL schema migrations
│   │       ├── 001_create_fleet_vehicles.sql
│   │       ├── 002_create_fleet_drivers.sql
│   │       ├── 003_create_fleet_trips.sql
│   │       ├── 004_create_fleet_maintenance.sql
│   │       ├── 005_create_fleet_partners.sql
│   │       ├── 006_create_fleet_expenses.sql
│   │       ├── 007_create_fleet_gps_logs.sql
│   │       └── 008_create_fleet_alerts.sql
│   ├── scripts/
│   │   ├── rebuild-pgsql.sh          # Rebuild PostgreSQL from MongoDB
│   │   ├── seed-data.sh              # Seed test data
│   │   └── create-kafka-topics.sh    # Create Kafka topics
│   ├── go.mod
│   └── go.sum
│
├── flutter/                          # Flutter Apps (shared code)
│   ├── packages/
│   │   └── fleet_core/              # Shared package
│   │       ├── lib/
│   │       │   ├── models/          # Shared Dart models
│   │       │   │   ├── vehicle.dart
│   │       │   │   ├── driver.dart
│   │       │   │   ├── trip.dart
│   │       │   │   ├── maintenance.dart
│   │       │   │   ├── partner_vehicle.dart
│   │       │   │   └── expense.dart
│   │       │   ├── services/        # API client + repositories
│   │       │   │   ├── api_client.dart
│   │       │   │   ├── auth_service.dart
│   │       │   │   ├── vehicle_service.dart
│   │       │   │   ├── trip_service.dart
│   │       │   │   └── gps_service.dart
│   │       │   ├── bloc/            # Shared BLoC/Cubit
│   │       │   │   ├── auth_bloc.dart
│   │       │   │   └── connectivity_cubit.dart
│   │       │   └── utils/           # Shared utilities
│   │       │       ├── date_utils.dart
│   │       │       ├── currency_utils.dart
│   │       │       └── thai_utils.dart   # เลขไทย, วันที่ไทย
│   │       └── pubspec.yaml
│   │
│   ├── driver_app/                  # App 2: คนขับรถ
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── home_screen.dart          # รายการงานวันนี้
│   │   │   │   ├── trip_detail_screen.dart    # รายละเอียดเที่ยววิ่ง
│   │   │   │   ├── navigation_screen.dart     # นำทาง (Longdo Map)
│   │   │   │   ├── pod_screen.dart            # ถ่ายรูป/ลายเซ็น POD
│   │   │   │   ├── checklist_screen.dart      # Checklist ก่อนออก
│   │   │   │   ├── expense_screen.dart        # บันทึกน้ำมัน/ทางด่วน
│   │   │   │   ├── repair_report_screen.dart  # แจ้งซ่อมรถ
│   │   │   │   ├── salary_screen.dart         # ดูสลิปเงินเดือน
│   │   │   │   └── profile_screen.dart        # ข้อมูลส่วนตัว
│   │   │   ├── bloc/
│   │   │   │   ├── trip_bloc.dart
│   │   │   │   ├── gps_bloc.dart             # Background GPS tracking
│   │   │   │   ├── expense_bloc.dart
│   │   │   │   └── checklist_bloc.dart
│   │   │   ├── widgets/
│   │   │   │   ├── trip_card.dart
│   │   │   │   ├── status_badge.dart
│   │   │   │   ├── camera_widget.dart
│   │   │   │   └── signature_pad.dart
│   │   │   └── services/
│   │   │       ├── background_gps.dart       # ส่ง GPS ทุก 30 วินาที
│   │   │       ├── push_notification.dart
│   │   │       └── offline_sync.dart         # ทำงาน offline ได้
│   │   ├── android/
│   │   ├── ios/
│   │   └── pubspec.yaml
│   │
│   ├── boss_app/                    # App 3: เจ้าของ/ผู้จัดการ
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── dashboard_screen.dart      # สรุปภาพรวมวันนี้
│   │   │   │   ├── map_screen.dart            # แผนที่รถทุกคัน real-time
│   │   │   │   ├── trips_screen.dart          # จัดเที่ยววิ่ง
│   │   │   │   ├── vehicles_screen.dart       # รายการรถ + สถานะ
│   │   │   │   ├── drivers_screen.dart        # รายการคนขับ + KPI
│   │   │   │   ├── maintenance_screen.dart    # ซ่อมบำรุง + อนุมัติ
│   │   │   │   ├── partners_screen.dart       # รถร่วม
│   │   │   │   ├── costs_screen.dart          # ต้นทุนขนส่ง
│   │   │   │   ├── alerts_screen.dart         # แจ้งเตือน
│   │   │   │   └── reports_screen.dart        # รายงาน
│   │   │   ├── bloc/
│   │   │   │   ├── dashboard_bloc.dart
│   │   │   │   ├── vehicle_bloc.dart
│   │   │   │   ├── trip_bloc.dart
│   │   │   │   ├── maintenance_bloc.dart
│   │   │   │   ├── partner_bloc.dart
│   │   │   │   └── alert_bloc.dart
│   │   │   └── widgets/
│   │   │       ├── kpi_card.dart
│   │   │       ├── vehicle_map_marker.dart
│   │   │       ├── approval_dialog.dart
│   │   │       └── cost_chart.dart
│   │   ├── android/
│   │   ├── ios/
│   │   └── pubspec.yaml
│   │
│   └── web_dashboard/               # App 4: Web Dashboard
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── screens/              # เหมือน boss_app แต่ UI กว้างกว่า
│       │   │   ├── dashboard_screen.dart
│       │   │   ├── vehicles/
│       │   │   │   ├── vehicle_list_screen.dart
│       │   │   │   ├── vehicle_detail_screen.dart
│       │   │   │   └── vehicle_form_screen.dart
│       │   │   ├── drivers/
│       │   │   │   ├── driver_list_screen.dart
│       │   │   │   ├── driver_detail_screen.dart
│       │   │   │   └── driver_form_screen.dart
│       │   │   ├── trips/
│       │   │   │   ├── trip_list_screen.dart
│       │   │   │   ├── trip_planning_screen.dart  # ลาก drop จัดเที่ยว
│       │   │   │   └── trip_map_screen.dart
│       │   │   ├── maintenance/
│       │   │   │   ├── work_order_list_screen.dart
│       │   │   │   ├── work_order_form_screen.dart
│       │   │   │   ├── schedule_screen.dart
│       │   │   │   └── parts_inventory_screen.dart
│       │   │   ├── partners/
│       │   │   │   ├── partner_list_screen.dart
│       │   │   │   ├── partner_register_screen.dart
│       │   │   │   └── partner_settlement_screen.dart
│       │   │   ├── costs/
│       │   │   │   ├── cost_overview_screen.dart
│       │   │   │   ├── fuel_report_screen.dart
│       │   │   │   └── pl_per_vehicle_screen.dart
│       │   │   └── reports/
│       │   │       ├── kpi_dashboard_screen.dart
│       │   │       └── export_screen.dart
│       │   └── bloc/                 # เหมือน boss_app
│       ├── web/
│       └── pubspec.yaml
│
├── scripts/
│   ├── rebuild-pgsql.sh             # Rebuild PostgreSQL จาก MongoDB
│   ├── seed-mongo.sh                # Seed MongoDB test data
│   ├── create-kafka-topics.sh       # สร้าง Kafka topics
│   └── deploy.sh                    # Deploy script
│
└── docs/
    ├── API.md                       # API documentation
    ├── MCP-TOOLS.md                 # MCP tools reference
    ├── UCP-MANIFEST.md              # UCP manifest reference
    ├── DATABASE.md                  # MongoDB + PostgreSQL schema
    └── DEPLOYMENT.md                # Deployment guide
```

---

## 4. App 1: Go Backend API + MCP Server

### entry point: `backend/cmd/api/main.go`

```go
package main

import (
    "bc-fleet/internal/config"
    "bc-fleet/internal/database"
    "bc-fleet/internal/handler"
    "bc-fleet/internal/middleware"
    "bc-fleet/internal/mcp"
    "bc-fleet/internal/ucp"
    "github.com/gin-gonic/gin"
)

func main() {
    cfg := config.Load()
    
    // Connect databases
    mongoDB := database.ConnectMongo(cfg.MongoURI)
    pgDB := database.ConnectPostgres(cfg.PostgresURI)
    kafkaProducer := database.NewKafkaProducer(cfg.KafkaBrokers)
    
    // Setup Gin router
    r := gin.Default()
    r.Use(middleware.CORS())
    r.Use(middleware.Auth(cfg.JWTSecret))
    r.Use(middleware.ShopContext()) // inject shop_id for multi-tenant
    
    // REST API routes
    api := r.Group("/api/v1/fleet")
    {
        handler.RegisterVehicleRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterDriverRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterTripRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterMaintenanceRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterPartnerRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterExpenseRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterGPSRoutes(api, mongoDB, pgDB, kafkaProducer)
        handler.RegisterDashboardRoutes(api, pgDB)
        handler.RegisterUploadRoutes(api, cfg.R2Config)
    }
    
    // MCP Server (JSON-RPC over HTTP)
    mcp.RegisterMCPServer(r, mongoDB, pgDB, kafkaProducer)
    
    // UCP Gateway
    ucp.RegisterUCPRoutes(r, mongoDB, pgDB)
    
    // LINE Webhook
    r.POST("/webhook/line", line.HandleWebhook)
    
    // GPS WebSocket (real-time tracking)
    r.GET("/ws/gps", handler.HandleGPSWebSocket)
    
    r.Run(":" + cfg.Port)
}
```

### API Routes ทั้งหมด

```
# Vehicles (ทะเบียนรถ)
GET    /api/v1/fleet/vehicles              # list (อ่าน PostgreSQL)
GET    /api/v1/fleet/vehicles/:id          # get by id
POST   /api/v1/fleet/vehicles              # create (เขียน MongoDB → Kafka → PG)
PUT    /api/v1/fleet/vehicles/:id          # update
DELETE /api/v1/fleet/vehicles/:id          # soft delete
GET    /api/v1/fleet/vehicles/:id/health   # สุขภาพรถ (เขียว/เหลือง/แดง)
GET    /api/v1/fleet/vehicles/:id/history  # ประวัติทั้งหมด (อ่าน MongoDB event logs)

# Drivers (คนขับ)
GET    /api/v1/fleet/drivers
GET    /api/v1/fleet/drivers/:id
POST   /api/v1/fleet/drivers
PUT    /api/v1/fleet/drivers/:id
DELETE /api/v1/fleet/drivers/:id
GET    /api/v1/fleet/drivers/:id/score     # KPI score
GET    /api/v1/fleet/drivers/:id/schedule  # ตารางเวร
POST   /api/v1/fleet/drivers/:id/schedule  # กำหนดเวร
GET    /api/v1/fleet/drivers/:id/salary    # คำนวณเงินเดือน

# Trips (เที่ยววิ่ง)
GET    /api/v1/fleet/trips
GET    /api/v1/fleet/trips/:id
POST   /api/v1/fleet/trips
PUT    /api/v1/fleet/trips/:id
PUT    /api/v1/fleet/trips/:id/status      # เปลี่ยนสถานะ
POST   /api/v1/fleet/trips/:id/assign      # มอบหมายคนขับ+รถ
POST   /api/v1/fleet/trips/:id/pod         # อัปโหลด POD
GET    /api/v1/fleet/trips/:id/tracking    # GPS tracking data
POST   /api/v1/fleet/trips/calculate-cost  # คำนวณค่าขนส่ง

# Maintenance (ซ่อมบำรุง)
GET    /api/v1/fleet/maintenance/schedule          # ตารางซ่อมบำรุงทั้งหมด
GET    /api/v1/fleet/maintenance/due                # รายการที่ใกล้ถึงกำหนด
POST   /api/v1/fleet/maintenance/work-orders        # สร้างใบสั่งซ่อม
GET    /api/v1/fleet/maintenance/work-orders         # list ใบสั่งซ่อม
GET    /api/v1/fleet/maintenance/work-orders/:id     # รายละเอียด
PUT    /api/v1/fleet/maintenance/work-orders/:id     # อัปเดต
PUT    /api/v1/fleet/maintenance/work-orders/:id/approve  # อนุมัติ
PUT    /api/v1/fleet/maintenance/work-orders/:id/complete  # ปิดงาน
GET    /api/v1/fleet/maintenance/parts               # สต๊อกอะไหล่
POST   /api/v1/fleet/maintenance/parts               # เพิ่มอะไหล่
GET    /api/v1/fleet/maintenance/cost/:vehicle_id    # ต้นทุนซ่อมต่อคัน

# Partners (รถร่วม)
GET    /api/v1/fleet/partners                        # list รถร่วมทั้งหมด
POST   /api/v1/fleet/partners                        # ลงทะเบียนรถร่วม
GET    /api/v1/fleet/partners/:id
PUT    /api/v1/fleet/partners/:id
DELETE /api/v1/fleet/partners/:id
POST   /api/v1/fleet/partners/find-available         # ค้นหารถร่วมว่าง
POST   /api/v1/fleet/partners/book                   # จองรถร่วม
GET    /api/v1/fleet/partners/settlements             # รายการจ่ายเงินรถร่วม
POST   /api/v1/fleet/partners/settlements/:id/pay    # จ่ายเงินรถร่วม

# Expenses (ค่าใช้จ่าย)
GET    /api/v1/fleet/expenses
POST   /api/v1/fleet/expenses
GET    /api/v1/fleet/expenses/fuel-report            # รายงานน้ำมัน
GET    /api/v1/fleet/expenses/pl/:vehicle_id         # P&L ต่อคัน

# GPS
POST   /api/v1/fleet/gps/location                    # รับ GPS จาก driver app
GET    /api/v1/fleet/gps/vehicles                    # ตำแหน่งรถทุกคัน real-time
GET    /api/v1/fleet/gps/vehicle/:id/trail           # เส้นทางย้อนหลัง
WS     /ws/gps                                       # WebSocket real-time tracking

# Dashboard & Reports
GET    /api/v1/fleet/dashboard/summary               # สรุปภาพรวม
GET    /api/v1/fleet/dashboard/kpi                    # KPI metrics
GET    /api/v1/fleet/dashboard/alerts                 # แจ้งเตือนทั้งหมด
GET    /api/v1/fleet/reports/cost-per-trip            # ต้นทุนต่อเที่ยว
GET    /api/v1/fleet/reports/vehicle-utilization      # อัตราการใช้รถ
GET    /api/v1/fleet/reports/fuel-efficiency          # ประสิทธิภาพน้ำมัน
GET    /api/v1/fleet/reports/driver-performance       # ผลงานคนขับ

# Upload
POST   /api/v1/fleet/upload/image                    # อัปโหลดรูป → R2
POST   /api/v1/fleet/upload/document                 # อัปโหลดเอกสาร → R2
```

### Multi-tenant Middleware

```go
// middleware/shop_context.go
// ทุก request ต้องมี shop_id — ดึงจาก JWT token
func ShopContext() gin.HandlerFunc {
    return func(c *gin.Context) {
        shopID := c.GetString("shop_id") // set by Auth middleware from JWT
        if shopID == "" {
            c.AbortWithStatusJSON(401, gin.H{"error": "shop_id required"})
            return
        }
        c.Set("shop_id", shopID)
        c.Next()
    }
}
```

### Write Pattern (ทุก create/update/delete)

```go
// service/vehicle_service.go
func (s *VehicleService) CreateVehicle(ctx context.Context, shopID string, req CreateVehicleRequest) (*Vehicle, error) {
    vehicle := &Vehicle{
        ID:          primitive.NewObjectID(),
        ShopID:      shopID,
        Plate:       req.Plate,
        Brand:       req.Brand,
        Model:       req.Model,
        Type:        req.Type,        // "4ล้อ", "6ล้อ", "10ล้อ", "หัวลาก"
        Year:        req.Year,
        Color:       req.Color,
        Chassis:     req.Chassis,
        Engine:      req.Engine,
        MaxWeight:   req.MaxWeight,    // กก.
        FuelType:    req.FuelType,     // "ดีเซล", "เบนซิน", "EV"
        Ownership:   req.Ownership,    // "own", "partner", "rental"
        Status:      "active",
        Insurance:   req.Insurance,
        Tax:         req.Tax,
        Act:         req.Act,          // พ.ร.บ.
        Mileage:     req.Mileage,
        CreatedAt:   time.Now(),
        UpdatedAt:   time.Now(),
    }

    // 1. เขียน MongoDB (source of truth)
    _, err := s.mongoRepo.Insert(ctx, vehicle)
    if err != nil {
        return nil, err
    }

    // 2. Event log
    s.eventLogger.Log(ctx, EventLog{
        ShopID:    shopID,
        EventType: "vehicle.created",
        Entity:    "vehicle",
        EntityID:  vehicle.ID.Hex(),
        Action:    "create",
        Payload:   vehicle,
    })

    // 3. Produce Kafka event → PostgreSQL consumer จะ upsert
    s.kafkaProducer.Produce("fleet.vehicles", KafkaEvent{
        Type:      "vehicle.created",
        ShopID:    shopID,
        EntityID:  vehicle.ID.Hex(),
        Payload:   vehicle,
        Timestamp: time.Now(),
    })

    return vehicle, nil
}
```

---

## 5. App 2: Flutter Driver App

### Target: คนขับรถประจำ + คนขับรถร่วม
### Platform: iOS + Android

### หน้าจอหลัก

1. **Login** — เบอร์โทร + OTP (ผ่าน LINE หรือ SMS)
2. **Home** — รายการเที่ยววิ่งวันนี้ (pending / in-progress / completed)
3. **Trip Detail** — รายละเอียดงาน + แผนที่ + ปุ่มรับงาน/เริ่มงาน/ส่งมอบ
4. **Navigation** — Longdo Map นำทาง turn-by-turn
5. **Checklist** — ตรวจสภาพรถก่อนออก (เบรค/ยาง/ไฟ/กระจก) + ถ่ายรูป
6. **POD** — ถ่ายรูปหลักฐานส่งมอบ + ลายเซ็นดิจิทัล
7. **Expense** — บันทึกเติมน้ำมัน (ลิตร/บาท/เลขไมล์) + ค่าทางด่วน
8. **Repair Report** — แจ้งซ่อมรถ (ถ่ายรูป + อธิบายอาการ)
9. **Salary** — ดูสลิปเงินเดือน + เบี้ยเลี้ยง + OT
10. **Profile** — ข้อมูลส่วนตัว + ใบขับขี่ + ประวัติ

### Background GPS Service

```dart
// services/background_gps.dart
// ทำงาน background ตลอด เมื่อมีเที่ยววิ่งที่ status = "in_progress"
class BackgroundGPSService {
  Timer? _timer;
  
  void startTracking(String tripId) {
    _timer = Timer.periodic(Duration(seconds: 30), (_) async {
      final position = await Geolocator.getCurrentPosition();
      
      // ส่งไป API
      await apiClient.post('/fleet/gps/location', {
        'trip_id': tripId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'battery': await Battery().batteryLevel,
      });
    });
  }
  
  void stopTracking() => _timer?.cancel();
}
```

### Trip Status Flow (คนขับกด)

```
pending → accepted → started → arrived → delivering → completed
                                                            ↓
                                                      (POD + ลายเซ็น)
```

### Offline Support

- เก็บ pending trips ใน local SQLite/ObjectBox
- เก็บ GPS points ใน local buffer ถ้า offline
- sync ขึ้นเมื่อกลับมา online
- ถ่ายรูป POD เก็บ local ก่อน → upload เมื่อ online

---

## 6. App 3: Flutter Boss App

### Target: เจ้าของ SME + ผู้จัดการขนส่ง
### Platform: iOS + Android

### หน้าจอหลัก

1. **Dashboard** — สรุปวันนี้ (เที่ยววิ่ง/รถว่าง/แจ้งเตือน/ต้นทุน)
2. **Live Map** — แผนที่รถทุกคัน real-time (WebSocket)
3. **Trips** — จัดเที่ยววิ่ง + มอบหมาย + ติดตาม
4. **Vehicles** — สถานะรถ (เขียว/เหลือง/แดง) + ประวัติ
5. **Drivers** — รายชื่อ + KPI score + ตารางเวร
6. **Maintenance** — ใบสั่งซ่อม + อนุมัติ + แจ้งเตือน
7. **Partners** — รถร่วม + จองรถนอก + จ่ายเงิน
8. **Costs** — ต้นทุนขนส่งรายวัน/เดือน + P&L ต่อคัน
9. **Alerts** — แจ้งเตือน พ.ร.บ./ภาษี/ซ่อม/ใบขับขี่หมดอายุ
10. **Reports** — สรุปรายสัปดาห์/เดือน + export PDF

### Push Notifications ที่ส่ง

- รถร่วมกดรับงาน/ปฏิเสธงาน
- คนขับส่งมอบสำเร็จ (พร้อมรูป POD)
- ใบสั่งซ่อมรอนุมัติ
- พ.ร.บ./ภาษี/ประกันใกล้หมดอายุ (30/15/7 วันก่อน)
- รถออกนอก Geofence
- คนขับขับเร็วเกินกำหนด

---

## 7. App 4: Web Dashboard

### Target: แอดมินสำนักงาน + ฝ่ายบัญชี
### Platform: Web browser (Flutter Web)
### หมายเหตุ: แชร์ BLoC/models กับ boss_app ผ่าน fleet_core package

### ฟีเจอร์เพิ่มจาก Boss App

- Drag & drop จัดเที่ยววิ่ง
- ตาราง Gantt สำหรับตารางรถ/คนขับ
- Work Order form (สร้าง/แก้ไข/อนุมัติ)
- รายงาน P&L ต่อคัน/ต่อเดือน
- Export Excel/PDF
- Parts Inventory management (สต๊อกอะไหล่)
- Partner Settlement (จ่ายเงินรถร่วม + หัก ณ ที่จ่าย)
- เชื่อม BC Account — ดูบัญชี ค่าขนส่ง, AP, ค่าซ่อม

---

## 8. App 5: LINE OA Chatbot

### ใช้ LINE Messaging API (Reply ฟรีไม่จำกัด)
### ผู้ใช้: ลูกค้า + เจ้าของ + คนขับ

### Rich Menu Layout (3x2 grid)

```
[ดูรถว่าง]    [จองเที่ยวรถ]    [ติดตามงาน]
[แจ้งซ่อม]    [ดูต้นทุน]       [พูดกับ AI]
```

### AI Agent Flow (ผ่าน MCP)

```
ลูกค้าทัก LINE: "มีรถ 6 ล้อว่างวันพรุ่งนี้ไหม ส่งของไปลำพูน"
   ↓
LINE Webhook → Go Handler
   ↓
AI Agent (Claude Haiku) รับข้อความ
   ↓
เรียก MCP tools:
  1. list_vehicles(type="6ล้อ", status="active")
  2. check_driver_schedule(date="tomorrow")
  3. calculate_route_cost(from="เชียงใหม่", to="ลำพูน")
   ↓
AI ตอบกลับ LINE (Flex Message):
  "รถ 6 ล้อ ทะเบียน กท-1234 ว่างครับ
   คนขับ: สมชาย
   ค่าขนส่ง: 2,500 บาท
   [ปุ่ม: จองเลย] [ปุ่ม: ต่อรองราคา]"
```

---

## 9. App 6: UCP + A2A Gateway

### UCP Manifest

```json
{
  "protocol": "ucp",
  "version": "1.0",
  "merchant": {
    "name": "{{shop_name}}",
    "category": "transportation",
    "subcategory": "freight",
    "coverage": ["เชียงใหม่", "ลำพูน", "เชียงราย"],
    "currency": "THB"
  },
  "capabilities": {
    "discovery": {
      "endpoint": "/ucp/discovery",
      "methods": ["service_catalog", "availability", "coverage_area"]
    },
    "cart": {
      "endpoint": "/ucp/cart",
      "methods": ["create_booking", "get_quote", "update_booking"]
    },
    "checkout": {
      "endpoint": "/ucp/checkout",
      "methods": ["process_payment"],
      "payment_methods": ["promptpay", "bank_transfer", "stripe"],
      "requires_customer_input": ["delivery_date", "pickup_address", "destination_address", "cargo_description"]
    },
    "fulfillment": {
      "endpoint": "/ucp/fulfillment",
      "methods": ["track_delivery", "get_pod", "confirm_delivery"]
    }
  },
  "mcp_compatible": true,
  "a2a_agent_card": "/ucp/agent-card.json"
}
```

### A2A Agent Card

```json
{
  "name": "BC Fleet Transport Agent",
  "description": "จัดการรถขนส่งสำหรับ SME ไทย",
  "url": "https://fleet.bcaccount.com/a2a",
  "capabilities": [
    "transport.freight.booking",
    "transport.freight.tracking",
    "transport.freight.pricing"
  ],
  "authentication": {
    "type": "api_key",
    "header": "X-Agent-Key"
  }
}
```

---

## 10. MongoDB Collections (Source of Truth)

### ทุก collection ใช้ prefix `fleet_` — ข้อมูลทุก document มี `shop_id`

```javascript
// === fleet_vehicles ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  plate: "กท-1234",
  brand: "ISUZU",
  model: "FRR 210",
  type: "6ล้อ",                    // "4ล้อ", "6ล้อ", "10ล้อ", "หัวลาก", "กระบะ"
  year: 2023,
  color: "ขาว",
  chassis_no: "MPATFS66JMT000123",
  engine_no: "4HK1-123456",
  fuel_type: "ดีเซล",              // "ดีเซล", "เบนซิน", "NGV", "EV"
  max_weight_kg: 6000,
  ownership: "own",                // "own", "partner", "rental"
  partner_id: null,                // ถ้าเป็นรถร่วม → ref partner
  status: "active",                // "active", "maintenance", "inactive"
  current_driver_id: "driver_001",
  current_location: { lat: 18.7883, lng: 98.9853 },
  mileage_km: 85000,
  insurance: {
    company: "วิริยะประกันภัย",
    policy_no: "INS-2024-001",
    type: "ชั้น1",
    start_date: ISODate("2024-01-01"),
    end_date: ISODate("2025-01-01"),
    premium: 25000
  },
  tax: {
    due_date: ISODate("2025-03-15"),
    last_paid: ISODate("2024-03-15"),
    amount: 3200
  },
  act: {                           // พ.ร.บ.
    due_date: ISODate("2025-03-15"),
    last_paid: ISODate("2024-03-15"),
    amount: 1800
  },
  maintenance_schedule: [
    { item: "น้ำมันเครื่อง", interval_km: 10000, interval_days: 180, last_done_km: 80000, last_done_date: ISODate("2024-06-01") },
    { item: "ผ้าเบรค", interval_km: 40000, interval_days: null, last_done_km: 60000, last_done_date: ISODate("2024-01-01") },
    { item: "ยาง", interval_km: 50000, interval_days: null, last_done_km: 50000, last_done_date: ISODate("2023-06-01") },
    { item: "สายพาน", interval_km: 80000, interval_days: null, last_done_km: 10000, last_done_date: ISODate("2022-01-01") },
    { item: "น้ำมันเกียร์", interval_km: 40000, interval_days: null, last_done_km: 60000, last_done_date: ISODate("2024-01-01") },
    { item: "กรองอากาศ", interval_km: 20000, interval_days: null, last_done_km: 80000, last_done_date: ISODate("2024-06-01") },
  ],
  documents: [                     // เก็บ URL ใน R2
    { type: "registration", url: "https://r2.../reg_001.pdf", uploaded_at: ISODate() },
    { type: "insurance_policy", url: "https://r2.../ins_001.pdf", uploaded_at: ISODate() },
  ],
  created_at: ISODate(),
  updated_at: ISODate(),
  deleted_at: null                  // soft delete
}

// === fleet_drivers ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  employee_id: "EMP-001",          // รหัสพนักงาน
  name: "สมชาย ใจดี",
  nickname: "ชาย",
  phone: "081-234-5678",
  id_card: "1-1234-12345-12-1",
  address: "123 ม.4 ต.สารภี อ.สารภี จ.เชียงใหม่",
  date_of_birth: ISODate("1985-05-15"),
  photo_url: "https://r2.../driver_001.jpg",
  license: {
    number: "12345678",
    type: "ท.2",                   // ท.1, ท.2, ท.3, ท.4
    issue_date: ISODate("2020-01-01"),
    expiry_date: ISODate("2025-01-01"),
    photo_url: "https://r2.../license_001.jpg"
  },
  dlt_card: {                      // บัตรประจำตัวผู้ขับรถ (กรมขนส่ง)
    number: "DLT-001",
    expiry_date: ISODate("2025-06-01"),
    photo_url: "https://r2.../dlt_001.jpg"
  },
  employment: {
    type: "permanent",             // "permanent", "contract", "daily", "partner"
    start_date: ISODate("2020-01-01"),
    salary: 15000,                 // เงินเดือนฐาน
    daily_allowance: 300,          // เบี้ยเลี้ยงต่อวัน
    trip_bonus: 200,               // โบนัสต่อเที่ยว
    overtime_rate: 100,            // ค่า OT ต่อชั่วโมง
  },
  health_check: {
    last_date: ISODate("2024-06-01"),
    result: "ปกติ",
    next_due: ISODate("2025-06-01"),
    drug_test: "ผ่าน",
  },
  accident_history: [
    { date: ISODate("2023-05-15"), description: "ชนกระบะ", damage: "minor", cost: 5000 }
  ],
  assigned_vehicle_id: "vehicle_001",
  status: "active",               // "active", "on_leave", "suspended", "resigned"
  zones: ["เชียงใหม่", "ลำพูน", "ลำปาง"],
  vehicle_types: ["6ล้อ", "10ล้อ"],
  performance: {
    total_trips: 450,
    on_time_rate: 0.95,
    fuel_efficiency: 5.2,          // km/L เฉลี่ย
    customer_rating: 4.8,          // out of 5
    accident_count: 1,
    violation_count: 0,
    score: 92                      // คะแนนรวม 0-100
  },
  schedule: {
    shift: "เช้า",                 // "เช้า" (06-18), "บ่าย" (18-06), "ปกติ" (08-17)
    days_off: ["sunday"],
    leaves: [
      { type: "ลาป่วย", from: ISODate("2024-12-01"), to: ISODate("2024-12-02"), approved: true }
    ]
  },
  created_at: ISODate(),
  updated_at: ISODate(),
  deleted_at: null
}

// === fleet_trips ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  trip_no: "TRIP-2024-001234",
  status: "in_progress",           // "draft", "pending", "accepted", "started", "arrived", "delivering", "completed", "cancelled"
  vehicle_id: "vehicle_001",
  driver_id: "driver_001",
  is_partner: false,               // true ถ้าใช้รถร่วม
  partner_id: null,
  origin: {
    name: "คลังสินค้า ABC",
    address: "123 ถ.เชียงใหม่-ลำปาง",
    lat: 18.7883,
    lng: 98.9853,
    contact_name: "สมศรี",
    contact_phone: "089-123-4567"
  },
  destinations: [                  // หลายจุดส่งได้
    {
      seq: 1,
      name: "ร้าน XYZ วัสดุ",
      address: "456 ถ.ลำพูน",
      lat: 18.5741,
      lng: 98.9847,
      contact_name: "สมปอง",
      contact_phone: "089-234-5678",
      status: "pending",           // "pending", "arrived", "delivered"
      arrived_at: null,
      delivered_at: null,
      pod: null                    // จะเติมเมื่อส่งมอบ
    }
  ],
  cargo: {
    description: "ปูนซีเมนต์ 200 ถุง",
    weight_kg: 10000,
    volume_cbm: null,
    special_instructions: "ห้ามเปียกน้ำ"
  },
  schedule: {
    planned_start: ISODate("2024-12-15T06:00:00"),
    planned_end: ISODate("2024-12-15T12:00:00"),
    actual_start: ISODate("2024-12-15T06:15:00"),
    actual_end: null
  },
  route: {
    distance_km: 45,
    duration_minutes: 60,
    longdo_route_id: "route_abc123",
    waypoints: []                  // จาก Longdo Map API
  },
  costs: {
    fuel: 800,
    toll: 60,
    other: 0,
    driver_allowance: 300,
    total: 1160,
    revenue: 2500,                 // ค่าขนส่งที่เรียกเก็บ
    profit: 1340
  },
  pod: {                           // Proof of Delivery
    photos: ["https://r2.../pod_001.jpg", "https://r2.../pod_002.jpg"],
    signature_url: "https://r2.../sig_001.png",
    receiver_name: "สมปอง",
    notes: "รับครบ",
    timestamp: ISODate("2024-12-15T10:30:00")
  },
  checklist: {
    pre_trip: {
      completed: true,
      items: [
        { item: "เบรค", status: "ok", photo: null },
        { item: "ยาง", status: "ok", photo: null },
        { item: "ไฟส่องสว่าง", status: "ok", photo: null },
        { item: "น้ำมันเครื่อง", status: "ok", photo: null },
        { item: "น้ำ radiator", status: "warning", photo: "https://r2.../chk_001.jpg" },
      ],
      completed_at: ISODate("2024-12-15T05:50:00")
    },
    post_trip: null
  },
  created_by: "admin_001",
  created_at: ISODate(),
  updated_at: ISODate()
}

// === fleet_maintenance_work_orders ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  wo_no: "WO-2024-000123",
  vehicle_id: "vehicle_001",
  type: "preventive",              // "preventive", "corrective", "emergency"
  priority: "medium",              // "low", "medium", "high", "critical"
  status: "approved",              // "draft", "pending_approval", "approved", "in_progress", "completed", "cancelled"
  reported_by: "driver_001",       // คนแจ้ง
  reported_type: "driver",         // "driver", "system", "admin", "ai_agent"
  description: "น้ำมันเครื่องครบรอบ 10,000 กม.",
  symptoms: "ไม่มีอาการผิดปกติ",
  mileage_at_report: 90000,
  service_provider: {
    type: "internal",              // "internal" (อู่ใน), "external" (อู่นอก)
    name: "ช่างสมศักดิ์",
    phone: "089-345-6789",
    address: null
  },
  parts: [
    { name: "น้ำมันเครื่อง SHELL 15W-40", qty: 8, unit: "ลิตร", unit_price: 280, total: 2240, from_stock: true },
    { name: "กรองน้ำมันเครื่อง", qty: 1, unit: "ชิ้น", unit_price: 350, total: 350, from_stock: true },
    { name: "กรองอากาศ", qty: 1, unit: "ชิ้น", unit_price: 450, total: 450, from_stock: false },
  ],
  labor: {
    hours: 2,
    rate: 500,                     // ค่าแรง/ชม.
    total: 1000
  },
  total_cost: 4040,
  approved_by: "admin_001",
  approved_at: ISODate("2024-12-10T09:00:00"),
  started_at: ISODate("2024-12-10T13:00:00"),
  completed_at: ISODate("2024-12-10T15:00:00"),
  photos: {
    before: ["https://r2.../wo_before_001.jpg"],
    after: ["https://r2.../wo_after_001.jpg"]
  },
  bc_account_entry: {              // เชื่อม BC Account
    synced: true,
    journal_id: "JV-2024-001234",
    expense_account: "5300",       // ค่าซ่อมบำรุง
  },
  created_at: ISODate(),
  updated_at: ISODate()
}

// === fleet_partner_vehicles ===
{
  _id: ObjectId,
  shop_id: "shop_001",            // ร้านที่ลงทะเบียนรถร่วมนี้
  owner: {
    name: "นายสมหมาย รถเยอะ",
    company: "บจก.ขนส่งสมหมาย",
    tax_id: "0105564123456",
    phone: "081-456-7890",
    line_id: "sommai_truck",
    bank_account: {
      bank: "กสิกรไทย",
      account_no: "123-4-56789-0",
      account_name: "บจก.ขนส่งสมหมาย"
    },
    address: "789 ม.2 ต.ป่าแดด อ.เมือง จ.เชียงใหม่"
  },
  vehicle: {
    plate: "2กร-5678",
    brand: "HINO",
    model: "500",
    type: "10ล้อ",
    year: 2022,
    max_weight_kg: 15000,
    fuel_type: "ดีเซล",
    registration_url: "https://r2.../partner_reg_001.pdf",
    insurance_url: "https://r2.../partner_ins_001.pdf",
    act_url: "https://r2.../partner_act_001.pdf"
  },
  driver: {
    name: "นายวิชัย ขับดี",
    phone: "089-567-8901",
    license_type: "ท.2",
    license_expiry: ISODate("2025-06-01")
  },
  pricing: {
    model: "per_trip",             // "per_trip", "per_km", "per_day"
    base_rate: 3000,               // ราคาเริ่มต้น
    per_km: 15,                    // บาท/กม. (ถ้า model = per_km)
    zones: {
      "เชียงใหม่-ลำพูน": 2500,
      "เชียงใหม่-ลำปาง": 4500,
      "เชียงใหม่-เชียงราย": 5500
    }
  },
  coverage_zones: ["เชียงใหม่", "ลำพูน", "ลำปาง"],
  rating: 4.5,
  total_trips: 35,
  status: "active",                // "active", "suspended", "inactive"
  withholding_tax: {
    rate: 0.01,                    // 1% หัก ณ ที่จ่าย
    type: "ภ.ง.ด.3"
  },
  bc_account_creditor_id: "CR-001", // เชื่อม BC Account เจ้าหนี้
  created_at: ISODate(),
  updated_at: ISODate()
}

// === fleet_expenses ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  trip_id: "trip_001",             // null ถ้าไม่ผูกเที่ยว
  vehicle_id: "vehicle_001",
  driver_id: "driver_001",
  type: "fuel",                    // "fuel", "toll", "parking", "repair", "fine", "other"
  description: "เติมดีเซล ปตท. สาขาเชียงใหม่",
  amount: 2000,
  fuel_detail: {                   // เฉพาะ type = "fuel"
    liters: 80,
    price_per_liter: 25,
    odometer_km: 85200,
    station: "ปตท. สาขาเชียงใหม่",
    fuel_type: "ดีเซล B7"
  },
  receipt_url: "https://r2.../receipt_001.jpg",
  bc_account_entry: {
    synced: true,
    journal_id: "JV-2024-001235",
    expense_account: "5200"        // ค่าน้ำมัน
  },
  recorded_by: "driver_001",
  recorded_at: ISODate("2024-12-15T07:30:00"),
  created_at: ISODate()
}

// === fleet_gps_logs ===
// NOTE: high frequency — ทุก 30 วินาที ต่อรถ 1 คัน
// ใช้ TTL index ลบหลัง 90 วัน
{
  _id: ObjectId,
  shop_id: "shop_001",
  vehicle_id: "vehicle_001",
  driver_id: "driver_001",
  trip_id: "trip_001",             // null ถ้าไม่มีเที่ยว
  location: {
    type: "Point",
    coordinates: [98.9853, 18.7883] // [lng, lat] — GeoJSON
  },
  speed_kmh: 65,
  heading: 180,
  accuracy_m: 10,
  battery_pct: 85,
  timestamp: ISODate("2024-12-15T07:30:30"),
  created_at: ISODate()
}
// Index: { shop_id: 1, vehicle_id: 1, timestamp: -1 }
// Index: { location: "2dsphere" }
// TTL Index: { created_at: 1 }, expireAfterSeconds: 7776000 (90 days)

// === fleet_event_logs ===
// เก็บทุก event — ไม่ลบ ไม่มี TTL
{
  _id: ObjectId,
  shop_id: "shop_001",
  event_type: "vehicle.created",
  entity: "vehicle",
  entity_id: "vehicle_001",
  action: "create",
  payload: { /* full document snapshot */ },
  diff: null,                      // สำหรับ update จะเก็บ before/after
  user_id: "admin_001",
  user_type: "admin",              // "admin", "driver", "system", "ai_agent", "ucp_agent"
  ip: "203.150.xxx.xxx",
  metadata: {
    source: "web_dashboard",       // "driver_app", "boss_app", "web_dashboard", "line_bot", "mcp", "ucp"
    user_agent: "..."
  },
  created_at: ISODate()
}

// === fleet_alerts ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  type: "insurance_expiry",        // "insurance_expiry", "tax_due", "act_due", "license_expiry", "maintenance_due", "geofence_alert", "speeding"
  entity: "vehicle",
  entity_id: "vehicle_001",
  title: "ประกันภัยใกล้หมดอายุ",
  message: "รถ กท-1234 ประกันหมดอายุ 15/03/2025 (เหลือ 30 วัน)",
  severity: "warning",             // "info", "warning", "critical"
  due_date: ISODate("2025-03-15"),
  days_remaining: 30,
  status: "active",                // "active", "acknowledged", "resolved"
  notified: {
    line: true,
    push: true,
    email: false
  },
  acknowledged_by: null,
  acknowledged_at: null,
  created_at: ISODate()
}

// === fleet_parts_inventory ===
{
  _id: ObjectId,
  shop_id: "shop_001",
  part_no: "PART-001",
  name: "น้ำมันเครื่อง SHELL Rimula R4 15W-40",
  category: "น้ำมันหล่อลื่น",
  unit: "ลิตร",
  qty_in_stock: 40,
  min_qty: 16,                     // แจ้งเตือนเมื่อต่ำกว่า
  unit_cost: 280,
  supplier: "Shell Thailand",
  location: "ห้องเก็บอะไหล่ A",
  last_restocked: ISODate("2024-12-01"),
  created_at: ISODate(),
  updated_at: ISODate()
}
```

---

## 11. Kafka Topics + Consumer

### Topics

```
fleet.vehicles          — vehicle CRUD events
fleet.drivers           — driver CRUD events
fleet.trips             — trip lifecycle events
fleet.maintenance       — work order events
fleet.partners          — partner vehicle events
fleet.expenses          — expense recording events
fleet.gps               — GPS location updates (high volume)
fleet.alerts            — alert events
fleet.parts             — parts inventory events
fleet.event-logs        — all event logs (for audit)
```

### Kafka Configuration

```yaml
# Kafka KRaft mode (ไม่ต้องใช้ Zookeeper)
# fleet.gps ใช้ retention 7 วัน (high volume)
# อื่นๆ ใช้ retention 30 วัน
```

### Consumer Groups

```
fleet-pgsql-sync        — main consumer: sync ทุก topic ไป PostgreSQL
fleet-alert-processor   — ตรวจจับ alert conditions
fleet-bc-account-sync   — sync ค่าใช้จ่ายไป BC Account
```

---

## 12. PostgreSQL Tables (Query Layer)

### หมายเหตุ: ทุก table สามารถ DROP แล้ว rebuild จาก MongoDB ได้

```sql
-- 001_create_fleet_vehicles.sql
CREATE TABLE IF NOT EXISTS fleet_vehicles (
    id TEXT PRIMARY KEY,               -- MongoDB ObjectID as string
    shop_id TEXT NOT NULL,
    plate TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    type TEXT NOT NULL,                -- "4ล้อ", "6ล้อ", "10ล้อ"
    year INT,
    color TEXT,
    chassis_no TEXT,
    engine_no TEXT,
    fuel_type TEXT,
    max_weight_kg INT,
    ownership TEXT DEFAULT 'own',      -- "own", "partner", "rental"
    partner_id TEXT,
    status TEXT DEFAULT 'active',
    current_driver_id TEXT,
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    mileage_km INT,
    insurance_expiry DATE,
    tax_due_date DATE,
    act_due_date DATE,
    next_maintenance_km INT,
    next_maintenance_date DATE,
    health_status TEXT DEFAULT 'green', -- "green", "yellow", "red"
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    
    CONSTRAINT fk_shop FOREIGN KEY (shop_id) REFERENCES shops(id)
);
CREATE INDEX idx_fleet_vehicles_shop ON fleet_vehicles(shop_id);
CREATE INDEX idx_fleet_vehicles_status ON fleet_vehicles(shop_id, status);
CREATE INDEX idx_fleet_vehicles_plate ON fleet_vehicles(shop_id, plate);

-- 002_create_fleet_drivers.sql
CREATE TABLE IF NOT EXISTS fleet_drivers (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    employee_id TEXT,
    name TEXT NOT NULL,
    nickname TEXT,
    phone TEXT,
    license_type TEXT,
    license_expiry DATE,
    employment_type TEXT,              -- "permanent", "contract", "daily", "partner"
    salary DECIMAL(12,2),
    daily_allowance DECIMAL(12,2),
    trip_bonus DECIMAL(12,2),
    status TEXT DEFAULT 'active',
    assigned_vehicle_id TEXT,
    score INT DEFAULT 0,               -- 0-100
    total_trips INT DEFAULT 0,
    on_time_rate DECIMAL(5,4),
    fuel_efficiency DECIMAL(5,2),
    customer_rating DECIMAL(3,2),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_drivers_shop ON fleet_drivers(shop_id);
CREATE INDEX idx_fleet_drivers_status ON fleet_drivers(shop_id, status);

-- 003_create_fleet_trips.sql
CREATE TABLE IF NOT EXISTS fleet_trips (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    trip_no TEXT UNIQUE,
    status TEXT NOT NULL,
    vehicle_id TEXT,
    driver_id TEXT,
    is_partner BOOLEAN DEFAULT false,
    partner_id TEXT,
    origin_name TEXT,
    origin_lat DOUBLE PRECISION,
    origin_lng DOUBLE PRECISION,
    destination_count INT DEFAULT 1,
    cargo_description TEXT,
    cargo_weight_kg INT,
    planned_start TIMESTAMPTZ,
    planned_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    distance_km DECIMAL(10,2),
    fuel_cost DECIMAL(12,2),
    toll_cost DECIMAL(12,2),
    other_cost DECIMAL(12,2),
    driver_allowance DECIMAL(12,2),
    total_cost DECIMAL(12,2),
    revenue DECIMAL(12,2),
    profit DECIMAL(12,2),
    has_pod BOOLEAN DEFAULT false,
    created_by TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_trips_shop ON fleet_trips(shop_id);
CREATE INDEX idx_fleet_trips_status ON fleet_trips(shop_id, status);
CREATE INDEX idx_fleet_trips_date ON fleet_trips(shop_id, planned_start);
CREATE INDEX idx_fleet_trips_vehicle ON fleet_trips(vehicle_id);
CREATE INDEX idx_fleet_trips_driver ON fleet_trips(driver_id);

-- 004_create_fleet_maintenance.sql
CREATE TABLE IF NOT EXISTS fleet_work_orders (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    wo_no TEXT UNIQUE,
    vehicle_id TEXT NOT NULL,
    type TEXT,                         -- "preventive", "corrective", "emergency"
    priority TEXT,
    status TEXT,
    reported_by TEXT,
    description TEXT,
    mileage_at_report INT,
    service_provider_type TEXT,        -- "internal", "external"
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

-- 005_create_fleet_partners.sql
CREATE TABLE IF NOT EXISTS fleet_partner_vehicles (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    owner_name TEXT,
    owner_company TEXT,
    owner_phone TEXT,
    owner_tax_id TEXT,
    plate TEXT,
    vehicle_type TEXT,
    max_weight_kg INT,
    pricing_model TEXT,                -- "per_trip", "per_km", "per_day"
    base_rate DECIMAL(12,2),
    per_km_rate DECIMAL(8,2),
    rating DECIMAL(3,2),
    total_trips INT DEFAULT 0,
    status TEXT DEFAULT 'active',
    withholding_tax_rate DECIMAL(5,4),
    bc_account_creditor_id TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_partners_shop ON fleet_partner_vehicles(shop_id);

-- 006_create_fleet_expenses.sql
CREATE TABLE IF NOT EXISTS fleet_expenses (
    id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    trip_id TEXT,
    vehicle_id TEXT,
    driver_id TEXT,
    type TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    fuel_liters DECIMAL(8,2),
    fuel_price_per_liter DECIMAL(8,2),
    odometer_km INT,
    receipt_url TEXT,
    bc_account_synced BOOLEAN DEFAULT false,
    recorded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_expenses_shop ON fleet_expenses(shop_id);
CREATE INDEX idx_fleet_expenses_vehicle ON fleet_expenses(vehicle_id);
CREATE INDEX idx_fleet_expenses_date ON fleet_expenses(shop_id, recorded_at);

-- 007_create_fleet_gps_current.sql
-- NOTE: เก็บแค่ตำแหน่งปัจจุบัน (1 row ต่อ vehicle) — ไม่ใช่ log
CREATE TABLE IF NOT EXISTS fleet_vehicle_locations (
    vehicle_id TEXT PRIMARY KEY,
    shop_id TEXT NOT NULL,
    driver_id TEXT,
    trip_id TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    speed_kmh DECIMAL(6,2),
    heading INT,
    battery_pct INT,
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_fleet_locations_shop ON fleet_vehicle_locations(shop_id);

-- 008_create_fleet_alerts.sql
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

-- Dashboard views (สำหรับ query เร็ว)
CREATE OR REPLACE VIEW fleet_dashboard_summary AS
SELECT
    shop_id,
    COUNT(*) FILTER (WHERE status = 'active') as active_vehicles,
    COUNT(*) FILTER (WHERE status = 'maintenance') as vehicles_in_maintenance,
    COUNT(*) FILTER (WHERE health_status = 'red') as critical_vehicles,
    COUNT(*) FILTER (WHERE health_status = 'yellow') as warning_vehicles
FROM fleet_vehicles
WHERE deleted_at IS NULL
GROUP BY shop_id;

CREATE OR REPLACE VIEW fleet_today_trips AS
SELECT
    shop_id,
    COUNT(*) as total_trips,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status IN ('started', 'delivering')) as in_progress,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COALESCE(SUM(total_cost), 0) as total_cost,
    COALESCE(SUM(profit), 0) as total_profit
FROM fleet_trips
WHERE DATE(planned_start) = CURRENT_DATE
GROUP BY shop_id;
```

---

## 13. MCP Tools (46 tools ใหม่)

### Vehicle Tools (8 tools)

```
list_vehicles          — ค้นหารถ (กรอง: type, status, ownership)
get_vehicle            — ข้อมูลรถ by ID
create_vehicle         — ลงทะเบียนรถใหม่
update_vehicle         — อัปเดตข้อมูลรถ
get_vehicle_health     — สถานะสุขภาพ (green/yellow/red)
get_vehicle_location   — ตำแหน่ง GPS ปัจจุบัน
get_vehicle_cost       — ต้นทุนรวมต่อคัน/เดือน
get_vehicle_history    — ประวัติทั้งหมด (จาก MongoDB event logs)
```

### Driver Tools (10 tools)

```
list_drivers           — ค้นหาคนขับ (กรอง: status, zone, vehicle_type)
get_driver             — ข้อมูลคนขับ by ID
create_driver          — ลงทะเบียนคนขับใหม่
update_driver          — อัปเดตข้อมูล
get_driver_score       — คะแนน KPI + breakdown
check_driver_schedule  — ตารางเวร + วันลา
assign_driver_to_trip  — มอบหมายงาน
get_driver_expense     — ค่าใช้จ่ายที่บันทึก
calculate_driver_salary — คำนวณเงินเดือน + เบี้ยเลี้ยง + OT
suggest_best_driver    — AI แนะนำคนขับที่เหมาะสมที่สุด
```

### Trip Tools (8 tools)

```
list_trips             — ค้นหาเที่ยววิ่ง (กรอง: status, date, driver, vehicle)
create_trip            — สร้างเที่ยววิ่งใหม่
update_trip_status     — เปลี่ยนสถานะ
assign_trip            — มอบหมายรถ + คนขับ
calculate_route_cost   — คำนวณค่าขนส่ง (Longdo Map)
track_shipment         — ติดตาม GPS real-time
get_trip_pod           — ดู POD
get_trip_cost_breakdown — รายละเอียดต้นทุนต่อเที่ยว
```

### Maintenance Tools (8 tools)

```
list_maintenance_schedule   — ตารางซ่อมบำรุงที่ใกล้ถึงกำหนด
create_work_order          — สร้างใบสั่งซ่อม
get_work_order             — รายละเอียดใบสั่งซ่อม
update_work_order          — อัปเดตใบสั่งซ่อม
approve_work_order         — อนุมัติ (ผ่าน AI Agent ได้)
complete_work_order        — ปิดงาน + คิดเงิน
get_maintenance_cost       — ต้นทุนซ่อมต่อคัน/เดือน
list_parts_inventory       — สต๊อกอะไหล่คงเหลือ
```

### Partner Tools (6 tools)

```
register_partner_vehicle   — ลงทะเบียนรถร่วม
list_partner_vehicles      — รายการรถร่วมทั้งหมด
find_available_partners    — ค้นหารถร่วมว่าง (zone + type + date)
create_partner_booking     — จองรถร่วม + ส่งงาน
get_partner_settlement     — รายการจ่ายเงินรถร่วม
calculate_partner_payment  — คำนวณค่าจ้างรถร่วม + หัก ณ ที่จ่าย
```

### Dashboard Tools (6 tools)

```
get_fleet_summary          — สรุปภาพรวม (รถ/คนขับ/เที่ยว/ต้นทุน)
get_fleet_kpi              — KPI metrics (utilization, on-time, fuel efficiency)
get_active_alerts          — แจ้งเตือนที่ยัง active
get_cost_report            — รายงานต้นทุนขนส่ง (รายวัน/สัปดาห์/เดือน)
get_fuel_report            — รายงานน้ำมัน + อัตราสิ้นเปลือง
get_driver_leaderboard     — อันดับคนขับตาม score
```

---

## 14. UCP Manifest + Endpoints

```
GET  /ucp/manifest                   — UCP manifest JSON
POST /ucp/discovery/catalog          — service catalog (ประเภทรถ + ราคา)
POST /ucp/discovery/availability     — รถว่าง (date + zone + type)
POST /ucp/discovery/coverage         — พื้นที่ให้บริการ
POST /ucp/cart/quote                 — ขอใบเสนอราคา
POST /ucp/cart/booking               — จองเที่ยวรถ
PUT  /ucp/cart/booking/:id           — แก้ไขการจอง
POST /ucp/checkout/payment           — ชำระเงิน (PromptPay/Stripe)
GET  /ucp/fulfillment/track/:id      — ติดตามเรียลไทม์
GET  /ucp/fulfillment/pod/:id        — หลักฐานส่งมอบ
POST /ucp/fulfillment/confirm/:id    — ยืนยันรับสินค้า
GET  /ucp/identity/merchant          — ข้อมูลร้านค้า
GET  /ucp/agent-card.json            — A2A Agent Card
```

---

## 15. External Services Configuration

```env
# .env.example

# MongoDB
MONGO_URI=mongodb://localhost:27017/bcfleet
MONGO_DB=bcfleet

# PostgreSQL
POSTGRES_URI=postgres://bcfleet:password@localhost:5432/bcfleet?sslmode=disable

# Kafka
KAFKA_BROKERS=localhost:9092
KAFKA_GROUP_ID=fleet-pgsql-sync

# Longdo Map API
LONGDO_MAP_API_KEY=your_longdo_api_key

# LINE OA
LINE_CHANNEL_SECRET=your_line_channel_secret
LINE_CHANNEL_ACCESS_TOKEN=your_line_access_token

# Claude API
ANTHROPIC_API_KEY=your_claude_api_key
CLAUDE_MODEL=claude-haiku-4-5-20251001

# Cloudflare R2
R2_ACCOUNT_ID=your_r2_account_id
R2_ACCESS_KEY=your_r2_access_key
R2_SECRET_KEY=your_r2_secret_key
R2_BUCKET=bcfleet-files
R2_PUBLIC_URL=https://files.bcfleet.com

# Stripe (สำหรับ UCP)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

# JWT
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRY=24h

# Server
PORT=8080
ENV=development
```

---

## 16. Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  # MongoDB — Source of Truth
  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      MONGO_INITDB_DATABASE: bcfleet

  # PostgreSQL — Query Layer (rebuildable)
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: bcfleet
      POSTGRES_USER: bcfleet
      POSTGRES_PASSWORD: bcfleet_password

  # Kafka (KRaft mode — ไม่ต้อง Zookeeper)
  kafka:
    image: apache/kafka:3.7.0
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@localhost:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_LOG_RETENTION_HOURS: 720  # 30 days default

  # Go API Server
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    depends_on:
      - mongodb
      - postgres
      - kafka
    env_file:
      - .env
    command: ["./api"]

  # Kafka Consumer (MongoDB → PostgreSQL sync)
  kafka-consumer:
    build:
      context: ./backend
      dockerfile: Dockerfile
    depends_on:
      - mongodb
      - postgres
      - kafka
    env_file:
      - .env
    command: ["./kafka-consumer"]

volumes:
  mongodb_data:
  postgres_data:
```

---

## 17. Build Order (ลำดับการสร้าง)

### Claude Code ควรสร้างตามลำดับนี้:

```
Step 1: โครงสร้าง folder ทั้งหมด + go.mod + pubspec.yaml
Step 2: docker-compose.yml + .env.example
Step 3: MongoDB connection + models (Go structs)
Step 4: PostgreSQL migrations (CREATE TABLE)
Step 5: Kafka setup (producer + consumer + topics)
Step 6: MongoDB repositories (WRITE operations)
Step 7: Kafka producer integration (หลัง write MongoDB → produce event)
Step 8: Kafka consumer → PostgreSQL upsert (sync service)
Step 9: PostgreSQL repositories (READ operations)
Step 10: Service layer (business logic)
Step 11: HTTP handlers + Gin routes
Step 12: Rebuild script (MongoDB → PostgreSQL)
Step 13: MCP Server + Fleet tools
Step 14: LINE OA webhook + AI agent
Step 15: UCP Gateway + manifest
Step 16: Flutter fleet_core package (shared models + API client)
Step 17: Flutter driver_app
Step 18: Flutter boss_app
Step 19: Flutter web_dashboard
Step 20: Longdo Map integration
Step 21: R2 upload integration
Step 22: Alert service (cron job — ตรวจ พ.ร.บ./ภาษี/ซ่อม)
Step 23: Dashboard views + KPI queries
Step 24: Seed data script (ข้อมูลตัวอย่างภาษาไทย)
```

### คำแนะนำสำหรับ Claude Code

1. **ทุก write operation** ต้องผ่าน pattern: MongoDB → Event Log → Kafka → PostgreSQL
2. **ทุก read operation** ต้องอ่านจาก PostgreSQL (ยกเว้น event logs อ่าน MongoDB)
3. **ทุก collection/table** ต้องมี `shop_id` สำหรับ multi-tenant
4. **ข้อมูลตัวอย่าง** ใช้ภาษาไทย (ชื่อ, ที่อยู่, ทะเบียนรถ)
5. **Error handling** ต้องครบทุก layer
6. **GPS logs** เขียน MongoDB อย่างเดียว (ไม่ต้อง sync ทุก record ไป PG — sync แค่ latest location)
7. **Event logs** เก็บ MongoDB อย่างเดียว (ไม่ sync ไป PG)

---

*Document version: 1.0*
*Created: 2026-03-31*
*For: Claude Code execution*
*Project: BC Fleet by BC Ai Solution Co., Ltd.*