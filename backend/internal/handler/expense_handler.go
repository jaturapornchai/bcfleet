package handler

import (
	"net/http"
	"strconv"
	"time"

	"bc-fleet/internal/database"
	"bc-fleet/internal/eventlog"
	mongorepo "bc-fleet/internal/repository/mongo"
	pgquery "bc-fleet/internal/repository/postgres"
	"bc-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// RegisterExpenseRoutes ลงทะเบียน routes สำหรับค่าใช้จ่าย
func RegisterExpenseRoutes(rg *gin.RouterGroup, mongo *database.MongoDB, pg *database.PostgresDB, kafka *database.KafkaProducer) {
	repo := mongorepo.NewExpenseRepo(mongo)
	query := pgquery.NewExpenseQuery(pg)
	logger := eventlog.NewLogger(mongo)
	svc := service.NewExpenseService(repo, query, logger, kafka)

	rg.GET("/expenses", listExpenses(svc))
	rg.POST("/expenses", createExpense(svc))
	rg.GET("/expenses/fuel-report", getFuelReport(svc))
	rg.GET("/expenses/pl/:vehicle_id", getVehiclePL(svc))
}

func listExpenses(svc *service.ExpenseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		vehicleID := c.Query("vehicle_id")
		expType := c.Query("type")
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

		expenses, total, err := svc.List(c.Request.Context(), shopID, vehicleID, expType, page, limit)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data":  expenses,
			"total": total,
			"page":  page,
			"limit": limit,
		})
	}
}

func createExpense(svc *service.ExpenseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		userID := c.GetString("user_id")

		var req service.CreateExpenseRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		expense, err := svc.Create(c.Request.Context(), shopID, userID, req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": expense})
	}
}

func getFuelReport(svc *service.ExpenseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		vehicleID := c.Query("vehicle_id")

		// parse from/to จาก query params (default: เดือนปัจจุบัน)
		now := time.Now()
		fromStr := c.DefaultQuery("from", time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local).Format("2006-01-02"))
		toStr := c.DefaultQuery("to", now.Format("2006-01-02"))

		from, err := time.Parse("2006-01-02", fromStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid from date"})
			return
		}
		to, err := time.Parse("2006-01-02", toStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid to date"})
			return
		}

		report, err := svc.GetFuelReport(c.Request.Context(), shopID, vehicleID, from, to)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": report})
	}
}

func getVehiclePL(svc *service.ExpenseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		vehicleID := c.Param("vehicle_id")

		now := time.Now()
		month, _ := strconv.Atoi(c.DefaultQuery("month", strconv.Itoa(int(now.Month()))))
		year, _ := strconv.Atoi(c.DefaultQuery("year", strconv.Itoa(now.Year())))

		pl, err := svc.GetPLPerVehicle(c.Request.Context(), shopID, vehicleID, month, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": pl})
	}
}
