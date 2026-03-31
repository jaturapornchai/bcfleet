package mcp

import (
	"encoding/json"
	"net/http"

	"sml-fleet/internal/database"
	"sml-fleet/internal/eventlog"
	"sml-fleet/internal/mcp/fleet_tools"
	mongorepo "sml-fleet/internal/repository/mongo"
	pgquery "sml-fleet/internal/repository/postgres"
	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// MCPRequest JSON-RPC 2.0 request
type MCPRequest struct {
	JSONRPC string      `json:"jsonrpc"`
	ID      interface{} `json:"id"`
	Method  string      `json:"method"`
	Params  interface{} `json:"params,omitempty"`
}

// MCPResponse JSON-RPC 2.0 response
type MCPResponse struct {
	JSONRPC string      `json:"jsonrpc"`
	ID      interface{} `json:"id"`
	Result  interface{} `json:"result,omitempty"`
	Error   *MCPError   `json:"error,omitempty"`
}

// MCPError JSON-RPC error object
type MCPError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// ToolDefinition คำอธิบาย tool สำหรับ MCP protocol
type ToolDefinition struct {
	Name        string      `json:"name"`
	Description string      `json:"description"`
	InputSchema interface{} `json:"inputSchema"`
}

// toolsCallParams params สำหรับ tools/call
type toolsCallParams struct {
	Name      string                 `json:"name"`
	Arguments map[string]interface{} `json:"arguments"`
}

// MCPServer จัดการ MCP JSON-RPC requests
type MCPServer struct {
	registry *fleet_tools.ToolRegistry
}

// RegisterMCPServer ลงทะเบียน MCP server routes กับ Gin
func RegisterMCPServer(
	r *gin.Engine,
	mongo *database.MongoDB,
	pg *database.PostgresDB,
	kafka *database.KafkaProducer,
) {
	// สร้าง event logger
	evLogger := eventlog.NewLogger(mongo)

	// สร้าง repositories
	vehicleMongoRepo := mongorepo.NewVehicleRepo(mongo)
	driverMongoRepo := mongorepo.NewDriverRepo(mongo)
	tripMongoRepo := mongorepo.NewTripRepo(mongo)
	maintenanceMongoRepo := mongorepo.NewMaintenanceRepo(mongo)
	partnerMongoRepo := mongorepo.NewPartnerRepo(mongo)
	expenseMongoRepo := mongorepo.NewExpenseRepo(mongo)

	vehiclePgQuery := pgquery.NewVehicleQuery(pg)
	driverPgQuery := pgquery.NewDriverQuery(pg)
	tripPgQuery := pgquery.NewTripQuery(pg)
	maintenancePgQuery := pgquery.NewMaintenanceQuery(pg)
	partnerPgQuery := pgquery.NewPartnerQuery(pg)
	expensePgQuery := pgquery.NewExpenseQuery(pg)
	dashboardPgQuery := pgquery.NewDashboardQuery(pg)

	// สร้าง services
	vehicleSvc := service.NewVehicleService(vehicleMongoRepo, vehiclePgQuery, evLogger, kafka).WithMongoDB(mongo)
	driverSvc := service.NewDriverService(driverMongoRepo, driverPgQuery, evLogger, kafka)
	tripSvc := service.NewTripService(tripMongoRepo, tripPgQuery, evLogger, kafka)
	maintenanceSvc := service.NewMaintenanceService(maintenanceMongoRepo, maintenancePgQuery, evLogger, kafka)
	partnerSvc := service.NewPartnerService(partnerMongoRepo, partnerPgQuery, evLogger, kafka)
	expenseSvc := service.NewExpenseService(expenseMongoRepo, expensePgQuery, evLogger, kafka)
	dashboardSvc := service.NewDashboardService(dashboardPgQuery)

	// สร้าง tool registry และลงทะเบียน tools ทั้งหมด
	registry := fleet_tools.NewToolRegistry()
	fleet_tools.RegisterVehicleTools(registry, vehicleSvc)
	fleet_tools.RegisterDriverTools(registry, driverSvc)
	fleet_tools.RegisterTripTools(registry, tripSvc)
	fleet_tools.RegisterMaintenanceTools(registry, maintenanceSvc)
	fleet_tools.RegisterPartnerTools(registry, partnerSvc)
	fleet_tools.RegisterExpenseTools(registry, expenseSvc)
	fleet_tools.RegisterDashboardTools(registry, dashboardSvc)

	server := &MCPServer{registry: registry}

	// MCP endpoint — JSON-RPC over HTTP POST
	r.POST("/mcp", server.handleRPC)
	// HealthCheck
	r.GET("/mcp/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "tools": registry.Count()})
	})
}

// handleRPC รับ JSON-RPC request และ route ไปยัง method ที่เหมาะสม
func (s *MCPServer) handleRPC(c *gin.Context) {
	var req MCPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, MCPResponse{
			JSONRPC: "2.0",
			Error:   &MCPError{Code: -32700, Message: "Parse error: " + err.Error()},
		})
		return
	}

	if req.JSONRPC != "2.0" {
		c.JSON(http.StatusOK, MCPResponse{
			JSONRPC: "2.0",
			ID:      req.ID,
			Error:   &MCPError{Code: -32600, Message: "Invalid Request: jsonrpc must be '2.0'"},
		})
		return
	}

	switch req.Method {
	case "tools/list":
		s.handleToolsList(c, req)
	case "tools/call":
		s.handleToolsCall(c, req)
	case "initialize":
		s.handleInitialize(c, req)
	default:
		c.JSON(http.StatusOK, MCPResponse{
			JSONRPC: "2.0",
			ID:      req.ID,
			Error:   &MCPError{Code: -32601, Message: "Method not found: " + req.Method},
		})
	}
}

// handleInitialize ตอบ MCP initialize handshake
func (s *MCPServer) handleInitialize(c *gin.Context, req MCPRequest) {
	c.JSON(http.StatusOK, MCPResponse{
		JSONRPC: "2.0",
		ID:      req.ID,
		Result: map[string]interface{}{
			"protocolVersion": "2024-11-05",
			"serverInfo": map[string]interface{}{
				"name":    "sml-fleet-mcp",
				"version": "1.0.0",
			},
			"capabilities": map[string]interface{}{
				"tools": map[string]interface{}{},
			},
		},
	})
}

// handleToolsList ส่งรายการ tools ทั้งหมด
func (s *MCPServer) handleToolsList(c *gin.Context, req MCPRequest) {
	tools := s.registry.List()
	defs := make([]map[string]interface{}, 0, len(tools))
	for _, t := range tools {
		defs = append(defs, map[string]interface{}{
			"name":        t.Name,
			"description": t.Description,
			"inputSchema": t.InputSchema,
		})
	}
	c.JSON(http.StatusOK, MCPResponse{
		JSONRPC: "2.0",
		ID:      req.ID,
		Result:  map[string]interface{}{"tools": defs},
	})
}

// handleToolsCall เรียก tool ที่ระบุ
func (s *MCPServer) handleToolsCall(c *gin.Context, req MCPRequest) {
	// parse params — รองรับทั้ง map และ JSON raw
	var params toolsCallParams
	raw, err := json.Marshal(req.Params)
	if err != nil {
		c.JSON(http.StatusOK, MCPResponse{
			JSONRPC: "2.0",
			ID:      req.ID,
			Error:   &MCPError{Code: -32602, Message: "Invalid params"},
		})
		return
	}
	if err := json.Unmarshal(raw, &params); err != nil {
		c.JSON(http.StatusOK, MCPResponse{
			JSONRPC: "2.0",
			ID:      req.ID,
			Error:   &MCPError{Code: -32602, Message: "Invalid params: " + err.Error()},
		})
		return
	}

	// ดึง shop_id จาก context (set โดย Auth middleware)
	shopID, _ := c.Get("shop_id")
	shopIDStr, _ := shopID.(string)
	if shopIDStr == "" {
		shopIDStr = "default" // fallback สำหรับ dev/testing
	}

	// เรียก tool handler
	result, err := s.registry.Call(c.Request.Context(), params.Name, shopIDStr, params.Arguments)
	if err != nil {
		c.JSON(http.StatusOK, MCPResponse{
			JSONRPC: "2.0",
			ID:      req.ID,
			Error:   &MCPError{Code: -32000, Message: err.Error()},
		})
		return
	}

	c.JSON(http.StatusOK, MCPResponse{
		JSONRPC: "2.0",
		ID:      req.ID,
		Result: map[string]interface{}{
			"content": []map[string]interface{}{
				{"type": "text", "text": mustJSON(result)},
			},
		},
	})
}

// mustJSON แปลง interface เป็น JSON string
func mustJSON(v interface{}) string {
	b, err := json.Marshal(v)
	if err != nil {
		return `{"error":"marshal failed"}`
	}
	return string(b)
}
