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

// RegisterMaintenanceRoutes ลงทะเบียน routes สำหรับซ่อมบำรุง
func RegisterMaintenanceRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewMaintenanceRepo(mongo)
	query := pgquery.NewMaintenanceQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewMaintenanceService(repo, query, logger, kafka)

	rg.GET("/maintenance/schedule", getMaintenanceSchedule(svc))
	rg.GET("/maintenance/due", getMaintenanceDue(svc))
	rg.POST("/maintenance/work-orders", createWorkOrder(svc))
	rg.GET("/maintenance/work-orders", listWorkOrders(svc))
	rg.GET("/maintenance/work-orders/:id", getWorkOrder(svc))
	rg.PUT("/maintenance/work-orders/:id", updateWorkOrder(svc))
	rg.PUT("/maintenance/work-orders/:id/approve", approveWorkOrder(svc))
	rg.PUT("/maintenance/work-orders/:id/complete", completeWorkOrder(svc))
	rg.GET("/maintenance/parts", listParts(svc))
	rg.GET("/maintenance/cost/:vehicle_id", getMaintenanceCost(svc))
}

func getMaintenanceSchedule(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		schedule, err := svc.GetSchedule(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": schedule})
	}
}

func getMaintenanceDue(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		due, err := svc.GetDue(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": due})
	}
}

func createWorkOrder(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.CreateWorkOrderRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		wo, err := svc.CreateWorkOrder(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": wo})
	}
}

func listWorkOrders(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		status := c.Query("status")
		vehicleID := c.Query("vehicle_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		orders, total, err := svc.ListWorkOrders(c.Request.Context(), shopID, status, vehicleID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  orders,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func getWorkOrder(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		wo, err := svc.GetWorkOrder(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "work order not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": wo})
	}
}

func updateWorkOrder(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.UpdateWorkOrderRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.UpdateWorkOrder(c.Request.Context(), shopID, userID, id, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "updated"})
	}
}

func approveWorkOrder(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		if err := svc.Approve(c.Request.Context(), shopID, userID, id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "approved"})
	}
}

func completeWorkOrder(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		if err := svc.Complete(c.Request.Context(), shopID, userID, id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "completed"})
	}
}

func listParts(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))

		parts, total, err := svc.ListParts(c.Request.Context(), shopID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  parts,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func getMaintenanceCost(svc *service.MaintenanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		vehicleID := c.Param("vehicle_id")

		cost, err := svc.GetMaintenanceCost(c.Request.Context(), shopID, vehicleID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": cost})
	}
}

// _ suppresses unused import warning for strconv
var _ = strconv.Itoa
