package handler

import (
	"net/http"
	"strconv"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/eventlog"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterDriverRoutes ลงทะเบียน routes สำหรับคนขับรถ
func RegisterDriverRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewDriverRepo(mongo)
	query := pgquery.NewDriverQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewDriverService(repo, query, logger, kafka)

	rg.GET("/drivers", listDrivers(svc))
	rg.GET("/drivers/:id", getDriver(svc))
	rg.POST("/drivers", createDriver(svc))
	rg.PUT("/drivers/:id", updateDriver(svc))
	rg.DELETE("/drivers/:id", deleteDriver(svc))
	rg.GET("/drivers/:id/score", getDriverScore(svc))
	rg.GET("/drivers/:id/schedule", getDriverSchedule(svc))
	rg.GET("/drivers/:id/salary", getDriverSalary(svc))
}

func listDrivers(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		status := c.Query("status")
		zone := c.Query("zone")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		drivers, total, err := svc.List(c.Request.Context(), shopID, status, zone, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  drivers,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func getDriver(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		driver, err := svc.GetByID(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": driver})
	}
}

func createDriver(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.CreateDriverRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		driver, err := svc.Create(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": driver})
	}
}

func updateDriver(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.UpdateDriverRequest
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

func deleteDriver(svc *service.DriverService) gin.HandlerFunc {
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

func getDriverScore(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		score, err := svc.GetScore(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": score})
	}
}

func getDriverSchedule(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		driver, err := svc.GetSchedule(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "driver not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": gin.H{
			"shift":    driver.Schedule,
			"zones":    driver.Zones,
			"vehicle_types": driver.VehicleTypes,
		}})
	}
}

func getDriverSalary(svc *service.DriverService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")
		month, _ := strconv.Atoi(c.DefaultQuery("month", "0"))
		year, _ := strconv.Atoi(c.DefaultQuery("year", "0"))

		// ถ้าไม่ระบุ ใช้เดือนปัจจุบัน
		if month == 0 || year == 0 {
			now := time.Now()
			month = int(now.Month())
			year = now.Year()
		}

		result, err := svc.CalculateSalary(c.Request.Context(), shopID, id, month, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": result})
	}
}
