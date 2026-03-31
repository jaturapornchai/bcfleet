package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"sml-fleet/internal/config"
	"sml-fleet/internal/database"
	"sml-fleet/internal/kafka"
)

func main() {
	cfg := config.Load()

	// เชื่อมต่อ PostgreSQL สำหรับ upsert
	pgDB, err := database.ConnectPostgres(cfg.PostgresURI)
	if err != nil {
		log.Fatalf("PostgreSQL connection failed: %v", err)
	}
	defer pgDB.Close()

	// สร้าง consumer
	consumer := kafka.NewFleetSyncConsumer(cfg.KafkaBrokers, cfg.KafkaGroupID, pgDB)

	// Graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigCh
		log.Println("Shutting down Kafka consumer...")
		cancel()
	}()

	log.Println("SML Fleet Kafka Consumer starting...")
	if err := consumer.Start(ctx); err != nil {
		log.Fatalf("Consumer failed: %v", err)
	}
}
