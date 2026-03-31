package main

import (
	"context"
	"log"

	"sml-fleet/internal/config"
	"sml-fleet/internal/database"
	"sml-fleet/internal/kafka"
)

// Rebuild PostgreSQL จาก MongoDB — รันได้ทุกเมื่อ
func main() {
	cfg := config.Load()

	mongoDB, err := database.ConnectMongo(cfg.MongoURI, cfg.MongoDB)
	if err != nil {
		log.Fatalf("MongoDB connection failed: %v", err)
	}
	defer mongoDB.Disconnect()

	pgDB, err := database.ConnectPostgres(cfg.PostgresURI)
	if err != nil {
		log.Fatalf("PostgreSQL connection failed: %v", err)
	}
	defer pgDB.Close()

	ctx := context.Background()
	rebuilder := kafka.NewRebuildService(mongoDB, pgDB)

	log.Println("Starting PostgreSQL rebuild from MongoDB...")
	if err := rebuilder.RebuildAll(ctx); err != nil {
		log.Fatalf("Rebuild failed: %v", err)
	}
	log.Println("PostgreSQL rebuild completed successfully!")
}
