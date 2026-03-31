#!/bin/bash
# create-kafka-topics.sh — สร้าง Kafka topics สำหรับ BC Fleet

set -e

KAFKA_BIN="${KAFKA_BIN:-/opt/kafka/bin}"
BROKER="${KAFKA_BROKER:-localhost:9092}"

TOPICS=(
    "fleet.vehicles"
    "fleet.drivers"
    "fleet.trips"
    "fleet.maintenance"
    "fleet.partners"
    "fleet.expenses"
    "fleet.gps"
    "fleet.alerts"
    "fleet.parts"
    "fleet.event-logs"
)

echo "=== BC Fleet — สร้าง Kafka Topics ==="
echo "Broker: $BROKER"
echo ""

for TOPIC in "${TOPICS[@]}"; do
    echo "Creating topic: $TOPIC"
    $KAFKA_BIN/kafka-topics.sh \
        --create \
        --bootstrap-server "$BROKER" \
        --topic "$TOPIC" \
        --partitions 3 \
        --replication-factor 1 \
        --if-not-exists
done

echo ""
echo "=== ตั้งค่า retention สำหรับ fleet.gps (7 วัน) ==="
$KAFKA_BIN/kafka-configs.sh \
    --alter \
    --bootstrap-server "$BROKER" \
    --entity-type topics \
    --entity-name fleet.gps \
    --add-config retention.ms=604800000

echo ""
echo "=== ตั้งค่า retention สำหรับ fleet.event-logs (ไม่จำกัด = -1) ==="
$KAFKA_BIN/kafka-configs.sh \
    --alter \
    --bootstrap-server "$BROKER" \
    --entity-type topics \
    --entity-name fleet.event-logs \
    --add-config retention.ms=-1

echo ""
echo "=== Topics ที่สร้างแล้ว ==="
$KAFKA_BIN/kafka-topics.sh \
    --list \
    --bootstrap-server "$BROKER" \
    | grep "^fleet\."

echo ""
echo "Done! สร้าง Kafka topics เสร็จแล้ว"
