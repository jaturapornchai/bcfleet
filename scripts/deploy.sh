#!/bin/bash
# Deploy SML Fleet
set -e

echo "=== SML Fleet Deploy ==="

# Build Go binaries
echo "1. Building Go backend..."
cd backend
go build -o bin/api cmd/api/main.go
go build -o bin/kafka-consumer cmd/kafka-consumer/main.go
go build -o bin/rebuild-pgsql cmd/rebuild-pgsql/main.go
cd ..

# Build Docker images
echo "2. Building Docker images..."
docker compose build

# Start services
echo "3. Starting services..."
docker compose up -d

# Wait for Kafka
echo "4. Waiting for Kafka to be ready..."
sleep 10

# Create Kafka topics
echo "5. Creating Kafka topics..."
./scripts/create-kafka-topics.sh

echo ""
echo "=== Deploy complete! ==="
echo "API: http://localhost:8080"
echo "MongoDB: localhost:27017"
echo "PostgreSQL: localhost:5432"
echo "Kafka: localhost:9092"
