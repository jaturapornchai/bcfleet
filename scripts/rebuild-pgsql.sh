#!/bin/bash
# Rebuild PostgreSQL จาก MongoDB — รันได้ทุกเมื่อโดยไม่กลัวข้อมูลหาย
# MongoDB เป็น source of truth — PostgreSQL เป็นแค่ query layer

set -e

echo "=== SML Fleet: Rebuild PostgreSQL from MongoDB ==="
echo ""

# ตรวจสอบ environment variables
POSTGRES_URI="${POSTGRES_URI:-postgres://smlfleet:smlfleet_password@localhost:5432/smlfleet?sslmode=disable}"

echo "1. Dropping all fleet_* tables..."
psql "$POSTGRES_URI" <<'EOF'
DROP VIEW IF EXISTS fleet_today_trips CASCADE;
DROP VIEW IF EXISTS fleet_dashboard_summary CASCADE;
DROP TABLE IF EXISTS fleet_alerts CASCADE;
DROP TABLE IF EXISTS fleet_vehicle_locations CASCADE;
DROP TABLE IF EXISTS fleet_expenses CASCADE;
DROP TABLE IF EXISTS fleet_partner_vehicles CASCADE;
DROP TABLE IF EXISTS fleet_work_orders CASCADE;
DROP TABLE IF EXISTS fleet_trips CASCADE;
DROP TABLE IF EXISTS fleet_drivers CASCADE;
DROP TABLE IF EXISTS fleet_vehicles CASCADE;
EOF

echo "2. Running migrations..."
for f in backend/migrations/postgres/*.sql; do
    echo "  Running: $f"
    psql "$POSTGRES_URI" -f "$f"
done

echo "3. Running Go rebuild tool (MongoDB → PostgreSQL)..."
cd backend && go run cmd/rebuild-pgsql/main.go

echo ""
echo "=== Rebuild complete! ==="
