# SML Fleet Deployment Guide

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker | 24+ | https://docs.docker.com/get-docker/ |
| Docker Compose | v2 | bundled กับ Docker Desktop |
| Go | 1.22+ | https://go.dev/dl/ |
| Flutter | 3.24+ | https://docs.flutter.dev/get-started |
| Make | any | OS package manager |

---

## 1. Clone + Setup

```bash
git clone https://github.com/bcaisolution/sml-fleet.git
cd sml-fleet

# Copy env file
cp .env.example .env

# แก้ไข .env ให้ครบ (API keys, secrets)
nano .env
```

### .env ที่ต้องกรอก

```
MONGO_URI=mongodb://localhost:27017/smlfleet
POSTGRES_URI=postgres://smlfleet:smlfleet_password@localhost:5432/smlfleet
KAFKA_BROKERS=localhost:9092
LONGDO_MAP_API_KEY=<your_key>
LINE_CHANNEL_SECRET=<your_secret>
LINE_CHANNEL_ACCESS_TOKEN=<your_token>
ANTHROPIC_API_KEY=<your_key>
R2_ACCOUNT_ID=<your_id>
R2_ACCESS_KEY=<your_key>
R2_SECRET_KEY=<your_key>
R2_BUCKET=smlfleet-files
JWT_SECRET=<random_32_chars>
```

---

## 2. Start Infrastructure (Docker Compose)

```bash
# Production
docker compose up -d mongodb postgres kafka

# Development (hot reload + exposed ports)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### ตรวจสอบ services

```bash
docker compose ps
docker compose logs -f kafka
```

---

## 3. Create Kafka Topics

```bash
# รอ Kafka พร้อม (~30 วินาที) แล้วรัน
./scripts/create-kafka-topics.sh

# หรือรันด้วยตัวเอง
docker exec sml-fleet-kafka-1 kafka-topics.sh \
  --create --bootstrap-server localhost:9092 \
  --topic fleet.vehicles --partitions 3 --replication-factor 1

# Topics ที่ต้องสร้าง:
# fleet.vehicles, fleet.drivers, fleet.trips, fleet.maintenance,
# fleet.partners, fleet.expenses, fleet.gps, fleet.alerts,
# fleet.parts, fleet.event-logs
```

---

## 4. PostgreSQL Migrations

```bash
# รัน migrations ทั้งหมด
./scripts/run-migrations.sh

# หรือรัน manually
for f in backend/migrations/postgres/*.sql; do
  psql $POSTGRES_URI -f "$f"
done

# ตรวจสอบ tables
psql $POSTGRES_URI -c "\dt fleet_*"
```

---

## 5. Seed MongoDB (ข้อมูลทดสอบ)

```bash
# Seed ข้อมูลตัวอย่างภาษาไทย
./scripts/seed-mongo.sh

# ข้อมูลที่ seed:
# - 5 รถ (4ล้อ, 6ล้อ, 10ล้อ)
# - 8 คนขับ
# - 10 เที่ยววิ่ง
# - 3 ใบสั่งซ่อม
# - 5 รถร่วม
```

---

## 6. Build Go Backend

```bash
cd backend

# Build all binaries
make build

# หรือ build ทีละตัว
go build -o bin/api ./cmd/api/
go build -o bin/kafka-consumer ./cmd/kafka-consumer/
go build -o bin/rebuild-pgsql ./cmd/rebuild-pgsql/
```

---

## 7. Run Services

### Development

```bash
# Terminal 1: API Server (port 8080)
cd backend && go run ./cmd/api/

# Terminal 2: Kafka Consumer (MongoDB → PostgreSQL sync)
cd backend && go run ./cmd/kafka-consumer/

# Terminal 3: Watch logs
docker compose logs -f
```

### Production (Docker)

```bash
# Build Docker images
docker compose build

# Start all services
docker compose up -d

# ตรวจสอบ logs
docker compose logs -f api kafka-consumer
```

---

## 8. Rebuild PostgreSQL จาก MongoDB

ใช้เมื่อต้องการ reset PostgreSQL หรือ schema เปลี่ยน

```bash
# Option 1: ใช้ script
./scripts/rebuild-pgsql.sh

# Option 2: ใช้ binary
cd backend && go run ./cmd/rebuild-pgsql/

# ขั้นตอนภายใน:
# 1. DROP ทุก fleet_* tables ใน PostgreSQL
# 2. CREATE tables ใหม่ (run migrations)
# 3. อ่าน MongoDB ทุก collection fleet_*
# 4. Transform + INSERT ลง PostgreSQL
# 5. อัปเดต sequences/indexes
```

---

## 9. Build Flutter Apps

### Driver App (Android/iOS)

```bash
cd flutter/driver_app

# Android
flutter build apk --release

# iOS
flutter build ios --release

# Debug
flutter run
```

### Boss App

```bash
cd flutter/boss_app
flutter build apk --release
flutter build ios --release
```

### Web Dashboard

```bash
cd flutter/web_dashboard
flutter build web --release

# Copy ไปที่ web server
cp -r build/web/ /var/www/fleet-dashboard/
```

---

## 10. LINE Webhook Setup

1. เปิด [LINE Developers Console](https://developers.line.biz)
2. Create Messaging API channel
3. ตั้ง Webhook URL: `https://your-domain.com/webhook/line`
4. เปิด "Use webhook"
5. Verify webhook
6. เปิด "Auto-reply messages" = OFF

```bash
# ทดสอบ webhook locally ด้วย ngrok
ngrok http 8080

# ตั้ง webhook URL ใน LINE console:
# https://xxxx.ngrok.io/webhook/line
```

---

## 11. Cloudflare R2 Setup

1. สร้าง R2 bucket ชื่อ `smlfleet-files`
2. ตั้ง custom domain (เช่น `files.smlfleet.com`)
3. สร้าง API token ที่มีสิทธิ์ R2 read/write
4. กรอกใน `.env`:

```
R2_ACCOUNT_ID=xxxxxxxxxxxx
R2_ACCESS_KEY=xxxxxxxxxxxx
R2_SECRET_KEY=xxxxxxxxxxxx
R2_BUCKET=smlfleet-files
R2_PUBLIC_URL=https://files.smlfleet.com
```

---

## 12. Health Check

```bash
# API health
curl http://localhost:8080/health

# PostgreSQL
psql $POSTGRES_URI -c "SELECT COUNT(*) FROM fleet_vehicles;"

# MongoDB
mongosh $MONGO_URI --eval "db.fleet_vehicles.countDocuments()"

# Kafka topics
docker exec sml-fleet-kafka-1 kafka-topics.sh \
  --list --bootstrap-server localhost:9092
```

---

## 13. Docker Registry (Production)

```bash
# Build + tag + push
docker build -t ghcr.io/bcai/smlfleet-api:latest ./backend
docker push ghcr.io/bcai/smlfleet-api:latest

# Pull + deploy ใน production server
ssh prod-server
cd /opt/sml-fleet
docker compose pull
docker compose up -d --no-build
```

---

## 14. Useful Make Commands

```bash
make build          # Build all Go binaries
make test           # Run tests
make migrate        # Run PostgreSQL migrations
make seed           # Seed MongoDB test data
make rebuild-pg     # Rebuild PostgreSQL from MongoDB
make kafka-topics   # Create Kafka topics
make docker-up      # Start all Docker services
make docker-down    # Stop all Docker services
make logs           # Show Docker logs
make clean          # Clean build artifacts
```

---

## Troubleshooting

### Kafka consumer lag สูง

```bash
# ดู consumer lag
docker exec sml-fleet-kafka-1 kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group fleet-pgsql-sync --describe
```

### PostgreSQL ข้อมูลไม่ครบ

```bash
# Rebuild จาก MongoDB
./scripts/rebuild-pgsql.sh
```

### GPS ไม่อัปเดต

```bash
# ตรวจสอบ topic fleet.gps
docker exec sml-fleet-kafka-1 kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic fleet.gps --from-beginning --max-messages 10
```

### MongoDB connection timeout

```bash
# ตรวจสอบ MongoDB status
docker compose ps mongodb
docker compose logs mongodb | tail -50
```
