package ucp

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

// IdentityHandler จัดการ merchant profile และ A2A agent card
type IdentityHandler struct{}

// NewIdentityHandler สร้าง IdentityHandler
func NewIdentityHandler() *IdentityHandler {
	return &IdentityHandler{}
}

// GetMerchant คืนข้อมูลร้านค้า (merchant profile)
func (h *IdentityHandler) GetMerchant(c *gin.Context) {
	shopID := c.GetString("shop_id")
	if shopID == "" {
		shopID = c.Query("shop_id")
	}

	// ในระบบจริงจะดึงจาก DB ตาม shopID
	merchant := map[string]interface{}{
		"shop_id":     shopID,
		"name":        getEnvOrDefault("SHOP_NAME", "SML Fleet Transport"),
		"description": "บริการขนส่งสินค้าครบวงจรสำหรับ SME ไทย ภาคเหนือ",
		"category":    "transportation",
		"subcategory": "freight",
		"contact": map[string]interface{}{
			"phone":   getEnvOrDefault("SHOP_PHONE", "053-000-000"),
			"email":   getEnvOrDefault("SHOP_EMAIL", "contact@smlfleet.com"),
			"line_id": getEnvOrDefault("SHOP_LINE_ID", "@smlfleet"),
			"address": getEnvOrDefault("SHOP_ADDRESS", "เชียงใหม่ ประเทศไทย"),
		},
		"coverage": map[string]interface{}{
			"zones":       []string{"เชียงใหม่", "ลำพูน", "ลำปาง", "เชียงราย"},
			"description": "ให้บริการภาคเหนือตอนบน",
		},
		"service_hours": map[string]interface{}{
			"weekday": "06:00-22:00",
			"weekend": "08:00-20:00",
			"holiday": "ตามข้อตกลง",
		},
		"vehicle_types": []map[string]interface{}{
			{"type": "กระบะ", "max_weight_kg": 750},
			{"type": "4ล้อ", "max_weight_kg": 2000},
			{"type": "6ล้อ", "max_weight_kg": 6000},
			{"type": "10ล้อ", "max_weight_kg": 15000},
			{"type": "หัวลาก", "max_weight_kg": 25000},
		},
		"payment_methods": []string{"promptpay", "bank_transfer", "stripe"},
		"currency":        "THB",
		"tax_id":          getEnvOrDefault("SHOP_TAX_ID", ""),
		"protocols": []string{"ucp", "a2a", "mcp"},
	}

	c.JSON(http.StatusOK, merchant)
}

// GetAgentCard คืน A2A Agent Card JSON
func (h *IdentityHandler) GetAgentCard(c *gin.Context) {
	baseURL := getEnvOrDefault("BASE_URL", "https://fleet.bcaccount.com")

	agentCard := GetAgentCard(baseURL)

	// เพิ่ม endpoint details
	agentCard["endpoints"] = map[string]interface{}{
		"mcp":         baseURL + "/mcp",
		"ucp":         baseURL + "/ucp",
		"webhook":     baseURL + "/webhook/line",
		"websocket":   "wss://" + getEnvOrDefault("HOST", "fleet.bcaccount.com") + "/ws/gps",
	}

	c.JSON(http.StatusOK, agentCard)
}

func getEnvOrDefault(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}
