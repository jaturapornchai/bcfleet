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

// RegisterCustomerRoutes ลงทะเบียน routes สำหรับลูกค้า
func RegisterCustomerRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewCustomerRepo(mongo)
	query := pgquery.NewCustomerQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewCustomerService(repo, query, logger, kafka)

	rg.GET("/customers", listCustomers(svc))
	rg.GET("/customers/search", searchCustomers(svc))
	rg.GET("/customers/by-line/:lineUserId", getCustomerByLine(svc))
	rg.GET("/customers/:id", getCustomer(svc))
	rg.POST("/customers", createCustomer(svc))
	rg.PUT("/customers/:id", updateCustomer(svc))
}

func listCustomers(svc *service.CustomerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		status := c.Query("status")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		customers, total, err := svc.List(c.Request.Context(), shopID, status, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": customers, "total": total, "page": page, "limit": limit})
	}
}

func searchCustomers(svc *service.CustomerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		keyword := c.Query("q")
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

		if keyword == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' required"})
			return
		}

		customers, err := svc.Search(c.Request.Context(), shopID, keyword, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": customers, "count": len(customers)})
	}
}

func getCustomerByLine(svc *service.CustomerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		lineUserID := c.Param("lineUserId")

		customer, err := svc.GetByLineUserID(c.Request.Context(), shopID, lineUserID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "customer not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": customer})
	}
}

func getCustomer(svc *service.CustomerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		id := c.Param("id")

		customer, err := svc.GetByID(c.Request.Context(), shopID, id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "customer not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": customer})
	}
}

func createCustomer(svc *service.CustomerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.CreateCustomerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		customer, err := svc.Create(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"data":    customer,
			"message": "สร้างลูกค้า " + customer.Name + " สำเร็จ",
		})
	}
}

func updateCustomer(svc *service.CustomerService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")
		id := c.Param("id")

		var updates map[string]interface{}
		if err := c.ShouldBindJSON(&updates); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := svc.Update(c.Request.Context(), shopID, userID, id, updates); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "อัปเดตข้อมูลลูกค้าสำเร็จ"})
	}
}
