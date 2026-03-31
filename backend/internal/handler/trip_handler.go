package handler

import (
	"net/http"
	"strconv"

	"sml-fleet/internal/database"
	"sml-fleet/internal/eventlog"
	"sml-fleet/internal/osrm"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterTripRoutes ลงทะเบียน routes สำหรับเที่ยววิ่ง
func RegisterTripRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewTripRepo(mongo)
	query := pgquery.NewTripQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewTripService(repo, query, logger, kafka)

	rg.GET("/trips", listTrips(svc))
	rg.GET("/trips/:id", getTrip(svc))
	rg.POST("/trips", createTrip(svc))
	rg.PUT("/trips/:id/status", updateTripStatus(svc))
	rg.POST("/trips/:id/assign", assignTrip(svc))
	rg.POST("/trips/:id/pod", uploadPOD(svc))
	rg.GET("/trips/:id/tracking", getTripTracking(svc))
	rg.GET("/trips/:id/pod", getTripPOD(svc))
	rg.GET("/trips/:id/cost", getTripCostBreakdown(svc))
	rg.POST("/trips/calculate-route", calculateRoute())
}

func listTrips(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		status := c.Query("status")
		driverID := c.Query("driver_id")
		vehicleID := c.Query("vehicle_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		trips, total, err := svc.List(c.Request.Context(), shopID, status, driverID, vehicleID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  trips,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func getTrip(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		trip, err := svc.GetByID(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "trip not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": trip})
	}
}

func createTrip(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.CreateTripRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		trip, err := svc.Create(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": trip})
	}
}

func updateTripStatus(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.UpdateTripStatusRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.UpdateStatus(c.Request.Context(), shopID, userID, id, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "status updated"})
	}
}

func assignTrip(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.AssignTripRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.Assign(c.Request.Context(), shopID, userID, id, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "trip assigned"})
	}
}

func uploadPOD(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.PODRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.UploadPOD(c.Request.Context(), shopID, userID, id, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "POD uploaded"})
	}
}

func getTripTracking(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		trail, err := svc.GetTracking(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": trail})
	}
}

func getTripPOD(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		pod, err := svc.GetPOD(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "trip not found"})
			return
		}
		if pod == nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "POD not available"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": pod})
	}
}

func getTripCostBreakdown(svc *service.TripService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		cost, err := svc.GetCostBreakdown(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "trip not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": cost})
	}
}

// CalculateRouteRequest คำขอคำนวณเส้นทาง
type CalculateRouteRequest struct {
	FromLat    float64       `json:"from_lat" binding:"required"`
	FromLng    float64       `json:"from_lng" binding:"required"`
	ToLat      float64       `json:"to_lat" binding:"required"`
	ToLng      float64       `json:"to_lng" binding:"required"`
	Waypoints  []WaypointReq `json:"waypoints"`
}

// WaypointReq จุดแวะระหว่างทาง
type WaypointReq struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

func calculateRoute() gin.HandlerFunc {
	client := osrm.NewClient("") // ใช้ OSRM Demo Server

	return func(c *gin.Context) {
		var req CalculateRouteRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		from := osrm.LatLng{Lat: req.FromLat, Lng: req.FromLng}
		to := osrm.LatLng{Lat: req.ToLat, Lng: req.ToLng}

		var waypoints []osrm.LatLng
		for _, wp := range req.Waypoints {
			waypoints = append(waypoints, osrm.LatLng{Lat: wp.Lat, Lng: wp.Lng})
		}

		result, err := client.Route(c.Request.Context(), from, to, waypoints)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": result})
	}
}
