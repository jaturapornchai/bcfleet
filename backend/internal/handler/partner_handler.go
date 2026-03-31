package handler

import (
	"net/http"
	"strconv"

	"bc-fleet/internal/database"
	"bc-fleet/internal/eventlog"
	mongorepo "bc-fleet/internal/repository/mongo"
	pgquery "bc-fleet/internal/repository/postgres"
	"bc-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterPartnerRoutes ลงทะเบียน routes สำหรับรถร่วม
func RegisterPartnerRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewPartnerRepo(mongo)
	query := pgquery.NewPartnerQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewPartnerService(repo, query, logger, kafka)

	rg.GET("/partners", listPartners(svc))
	rg.GET("/partners/:id", getPartner(svc))
	rg.POST("/partners", registerPartner(svc))
	rg.PUT("/partners/:id", updatePartner(svc))
	rg.DELETE("/partners/:id", deletePartner(svc))
	rg.POST("/partners/find-available", findAvailablePartners(svc))
	rg.POST("/partners/book", bookPartner(svc))
	rg.GET("/partners/settlements", getPartnerSettlements(svc))
	rg.POST("/partners/settlements/:id/calculate", calculatePartnerPayment(svc))
}

func listPartners(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		status := c.Query("status")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		partners, total, err := svc.List(c.Request.Context(), shopID, status, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  partners,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func getPartner(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		partner, err := svc.GetByID(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "partner not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": partner})
	}
}

func registerPartner(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.RegisterPartnerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		partner, err := svc.Register(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": partner})
	}
}

func updatePartner(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var req service.UpdatePartnerRequest
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

func deletePartner(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		if err := svc.Delete(c.Request.Context(), shopID, userID, id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "deactivated"})
	}
}

func findAvailablePartners(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")

		var req service.FindAvailablePartnersRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		partners, err := svc.FindAvailable(c.Request.Context(), shopID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": partners})
	}
}

func bookPartner(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.BookPartnerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.Book(c.Request.Context(), shopID, userID, req); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "partner booked"})
	}
}

func getPartnerSettlements(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		settlements, total, err := svc.GetSettlements(c.Request.Context(), shopID, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  settlements,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func calculatePartnerPayment(svc *service.PartnerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		partnerID := c.Param("id")

		var body struct {
			TripIDs []string `json:"trip_ids"`
		}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		result, err := svc.CalculatePayment(c.Request.Context(), shopID, partnerID, body.TripIDs)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": result})
	}
}
