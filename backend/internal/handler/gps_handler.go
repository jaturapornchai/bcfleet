package handler

import (
	"fmt"
	"net/http"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/models"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterGPSRoutes ลงทะเบียน routes สำหรับ GPS tracking
func RegisterGPSRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewGPSRepo(mongo)
	movementRepo := mongorepo.NewMovementRepo(mongo)
	query := pgquery.NewGPSQuery(pg)
	svc := service.NewGPSService(repo, query, kafka)

	rg.POST("/gps/location", recordLocation(svc))
	rg.GET("/gps/vehicles", getVehicleLocations(svc))
	rg.GET("/gps/moving", getMovingVehicles(svc))
	rg.POST("/gps/movement-analysis", publishMovementAnalysis(kafka, movementRepo))
	rg.GET("/gps/movement-events", getMovementEvents(movementRepo))
	rg.GET("/gps/vehicle/:id/trail", getVehicleTrail(svc))
}

func recordLocation(svc *service.GPSService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		var req service.RecordLocationRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.RecordLocation(c.Request.Context(), shopID, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "location recorded"})
	}
}

func getVehicleLocations(svc *service.GPSService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		locations, err := svc.GetVehicleLocations(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": locations})
	}
}

func getMovingVehicles(svc *service.GPSService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		minDistStr := c.DefaultQuery("min_distance_m", "50")
		maxAgeStr := c.DefaultQuery("max_age_minutes", "2")

		var minDist float64
		if _, err := fmt.Sscanf(minDistStr, "%f", &minDist); err != nil || minDist <= 0 {
			minDist = 50
		}
		var maxAge int
		if _, err := fmt.Sscanf(maxAgeStr, "%d", &maxAge); err != nil || maxAge <= 0 {
			maxAge = 2
		}

		vehicles, err := svc.GetMovingVehicles(c.Request.Context(), shopID, minDist, maxAge)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":           vehicles,
			"count":          len(vehicles),
			"min_distance_m": minDist,
			"max_age_minutes": maxAge,
		})
	}
}

// MovementAnalysisRequest AI ส่งผลวิเคราะห์ movement events
type MovementAnalysisRequest struct {
	Events []MovementEventInput `json:"events" binding:"required"`
}

// MovementEventInput event จาก AI analysis
type MovementEventInput struct {
	VehicleID  string  `json:"vehicle_id" binding:"required"`
	Plate      string  `json:"plate"`
	EventType  string  `json:"event_type" binding:"required"`  // movement.started, speeding, geofence.exit, etc.
	Severity   string  `json:"severity" binding:"required"`    // info, warning, critical
	Analysis   string  `json:"analysis" binding:"required"`    // AI สรุปภาษาไทย
	Lat        float64 `json:"lat"`
	Lng        float64 `json:"lng"`
	PrevLat    float64 `json:"prev_lat"`
	PrevLng    float64 `json:"prev_lng"`
	SpeedKmh   float64 `json:"speed_kmh"`
	DistanceM  float64 `json:"distance_m"`
	TripID     string  `json:"trip_id"`
	DriverID   string  `json:"driver_id"`
	AnalyzedBy string  `json:"analyzed_by"`
}

func publishMovementAnalysis(kafka *database.KafkaProducer, movementRepo *mongorepo.MovementRepo) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		var req MovementAnalysisRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if len(req.Events) == 0 {
			c.JSON(http.StatusOK, gin.H{"message": "no events", "count": 0})
			return
		}

		// บันทึก MongoDB + publish Kafka
		var events []*models.MovementEvent
		for _, ev := range req.Events {
			event := &models.MovementEvent{
				ShopID:    shopID,
				VehicleID: ev.VehicleID,
				Plate:     ev.Plate,
				EventType: ev.EventType,
				Severity:  ev.Severity,
				Analysis:  ev.Analysis,
				Data: &models.MovementData{
					Lat:       ev.Lat,
					Lng:       ev.Lng,
					PrevLat:   ev.PrevLat,
					PrevLng:   ev.PrevLng,
					SpeedKmh:  ev.SpeedKmh,
					DistanceM: ev.DistanceM,
					TripID:    ev.TripID,
					DriverID:  ev.DriverID,
				},
				AnalyzedBy: ev.AnalyzedBy,
			}
			events = append(events, event)

			// Publish to Kafka
			kafka.Produce("fleet.movement.analysis", database.KafkaEvent{
				Type:     "movement." + ev.EventType,
				ShopID:   shopID,
				EntityID: ev.VehicleID,
				Payload:  event,
			})
		}

		// Batch insert to MongoDB
		if err := movementRepo.InsertMany(c.Request.Context(), events); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": fmt.Sprintf("บันทึก %d movement events สำเร็จ", len(events)),
			"count":   len(events),
		})
	}
}

func getMovementEvents(movementRepo *mongorepo.MovementRepo) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		vehicleID := c.Query("vehicle_id")

		var limitVal int
		if _, err := fmt.Sscanf(c.DefaultQuery("limit", "50"), "%d", &limitVal); err != nil || limitVal <= 0 {
			limitVal = 50
		}

		var events []*models.MovementEvent
		var err error
		if vehicleID != "" {
			events, err = movementRepo.FindByVehicle(c.Request.Context(), shopID, vehicleID, limitVal)
		} else {
			events, err = movementRepo.FindRecent(c.Request.Context(), shopID, limitVal)
		}
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": events, "count": len(events)})
	}
}

func getVehicleTrail(svc *service.GPSService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		vehicleID := c.Param("id")

		// parse from/to จาก query params (default: 24 ชม. ที่ผ่านมา)
		now := time.Now()
		fromStr := c.DefaultQuery("from", now.Add(-24*time.Hour).Format("2006-01-02T15:04:05"))
		toStr := c.DefaultQuery("to", now.Format("2006-01-02T15:04:05"))

		from, err := time.Parse("2006-01-02T15:04:05", fromStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid from datetime"})
			return
		}
		to, err := time.Parse("2006-01-02T15:04:05", toStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid to datetime"})
			return
		}

		trail, err := svc.GetTrail(c.Request.Context(), shopID, vehicleID, from, to)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": trail})
	}
}
