.PHONY: dev api consumer rebuild migrate seed docker-up docker-down

# รัน API server (development)
api:
	cd backend && go run cmd/api/main.go

# รัน Kafka consumer
consumer:
	cd backend && go run cmd/kafka-consumer/main.go

# Rebuild PostgreSQL จาก MongoDB
rebuild:
	cd backend && go run cmd/rebuild-pgsql/main.go

# รัน API + consumer พร้อมกัน
dev:
	@echo "Starting BC Fleet development..."
	$(MAKE) -j2 api consumer

# Docker
docker-up:
	docker compose up -d

docker-down:
	docker compose down

# สร้าง Kafka topics
kafka-topics:
	./scripts/create-kafka-topics.sh

# Seed ข้อมูลตัวอย่าง
seed:
	./scripts/seed-mongo.sh

# Go build
build:
	cd backend && go build -o bin/api cmd/api/main.go
	cd backend && go build -o bin/kafka-consumer cmd/kafka-consumer/main.go
	cd backend && go build -o bin/rebuild-pgsql cmd/rebuild-pgsql/main.go
