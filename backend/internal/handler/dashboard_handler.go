package handler

import (
	"net/http"
	"strconv"

	"sml-fleet/internal/database"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterDashboardRoutes ลงทะเบียน routes สำหรับ dashboard + reports
func RegisterDashboardRoutes(rg *gin.RouterGroup, pg *database.PostgresDB) {
	dashQuery := pgquery.NewDashboardQuery(pg)
	svc := service.NewDashboardService(dashQuery)

	// Dashboard
	rg.GET("/dashboard/summary", getDashboardSummary(svc))
	rg.GET("/dashboard/kpi", getDashboardKPI(svc))
	rg.GET("/dashboard/alerts", getDashboardAlerts(svc))

	// Reports
	rg.GET("/reports/cost-per-trip", getCostPerTrip(svc))
	rg.GET("/reports/vehicle-utilization", getVehicleUtilization(svc))
	rg.GET("/reports/fuel-efficiency", getFuelEfficiency(svc))
	rg.GET("/reports/driver-performance", getDriverPerformance(svc))
}

func getDashboardSummary(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		summary, err := svc.GetSummary(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": summary})
	}
}

func getDashboardKPI(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		kpi, err := svc.GetKPI(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": kpi})
	}
}

func getDashboardAlerts(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
		alerts, total, err := svc.GetAlerts(c.Request.Context(), shopID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": alerts, "total": total})
	}
}

func getCostPerTrip(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
		report, total, err := svc.GetCostPerTrip(c.Request.Context(), shopID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": report, "total": total})
	}
}

func getVehicleUtilization(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		report, err := svc.GetVehicleUtilization(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": report})
	}
}

func getFuelEfficiency(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		report, err := svc.GetFuelEfficiency(c.Request.Context(), shopID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": report})
	}
}

func getDriverPerformance(svc *service.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
		report, total, err := svc.GetDriverPerformance(c.Request.Context(), shopID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": report, "total": total})
	}
}
