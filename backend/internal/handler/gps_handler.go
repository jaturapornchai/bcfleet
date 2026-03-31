package handler

import (
	"net/http"
	"time"

	"sml-fleet/internal/database"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterGPSRoutes ลงทะเบียน routes สำหรับ GPS tracking
func RegisterGPSRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewGPSRepo(mongo)
	query := pgquery.NewGPSQuery(pg)
	svc := service.NewGPSService(repo, query, kafka)

	rg.POST("/gps/location", recordLocation(svc))
	rg.GET("/gps/vehicles", getVehicleLocations(svc))
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
