package main

import (
	"context"
	"log"
	"time"

	"sml-fleet/internal/config"
	"sml-fleet/internal/database"
	"sml-fleet/internal/handler"
	"sml-fleet/internal/middleware"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	// เชื่อมต่อ databases
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

	kafkaProducer := database.NewKafkaProducer(cfg.KafkaBrokers)
	defer kafkaProducer.Close()

	// Setup Gin router
	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(middleware.CORS())

	// Health check (ไม่ต้อง auth)
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "sml-fleet"})
	})

	// REST API routes (ต้อง auth)
	api := r.Group("/api/v1/fleet")
	api.Use(middleware.Auth(cfg.JWTSecret))
	api.Use(middleware.ShopContext())
	{
		handler.RegisterVehicleRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterDriverRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterTripRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterMaintenanceRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterPartnerRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterExpenseRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterGPSRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterCustomerRoutes(api, mongoDB, pgDB, kafkaProducer)
		handler.RegisterDashboardRoutes(api, pgDB)
	}

	// Alert cron job — ตรวจสอบ พ.ร.บ./ภาษี/ซ่อม/ใบขับขี่ ทุกชั่วโมง
	alertSvc := service.NewAlertService(pgDB, mongoDB, kafkaProducer)
	go func() {
		// รันครั้งแรกทันทีตอน startup
		if err := alertSvc.RunAlertCheck(context.Background()); err != nil {
			log.Printf("[Alert] startup check error: %v", err)
		}
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			if err := alertSvc.RunAlertCheck(context.Background()); err != nil {
				log.Printf("[Alert] check error: %v", err)
			}
		}
	}()

	log.Printf("SML Fleet API starting on port %s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
