package handler

import (
	"net/http"
	"strconv"

	"sml-fleet/internal/database"
	"sml-fleet/internal/eventlog"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterVehicleRoutes ลงทะเบียน routes สำหรับรถขนส่ง
func RegisterVehicleRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewVehicleRepo(mongo)
	query := pgquery.NewVehicleQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewVehicleService(repo, query, logger, kafka).WithMongoDB(mongo)

	rg.GET("/vehicles", listVehicles(svc))
	rg.GET("/vehicles/:id", getVehicle(svc))
	rg.POST("/vehicles", createVehicle(svc))
	rg.PUT("/vehicles/:id", updateVehicle(svc))
	rg.DELETE("/vehicles/:id", deleteVehicle(svc))
	rg.GET("/vehicles/:id/health", getVehicleHealth(svc))
	rg.GET("/vehicles/:id/history", getVehicleHistory(svc))
}

func listVehicles(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		status := c.Query("status")
		vehicleType := c.Query("type")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		vehicles, total, err := svc.List(c.Request.Context(), shopID, status, vehicleType, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  vehicles,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func getVehicle(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		vehicle, err := svc.GetByID(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "vehicle not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": vehicle})
	}
}

func createVehicle(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.CreateVehicleRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		vehicle, err := svc.Create(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": vehicle})
	}
}

func updateVehicle(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.UpdateVehicleRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.Update(c.Request.Context(), shopID, userID, id, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "updated"})
	}
}

func deleteVehicle(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		if err := svc.Delete(c.Request.Context(), shopID, userID, id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "deleted"})
	}
}

func getVehicleHealth(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		health, err := svc.GetHealth(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "vehicle not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": health})
	}
}

func getVehicleHistory(svc *service.VehicleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		history, err := svc.GetHistory(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": history})
	}
}
