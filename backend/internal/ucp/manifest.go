package ucp

// GetManifest คืน UCP manifest JSON ตาม spec
func GetManifest(shopName string) map[string]interface{} {
	return map[string]interface{}{
		"protocol": "ucp",
		"version":  "1.0",
		"merchant": map[string]interface{}{
			"name":        shopName,
			"category":    "transportation",
			"subcategory": "freight",
			"coverage":    []string{"เชียงใหม่", "ลำพูน", "เชียงราย", "ลำปาง"},
			"currency":    "THB",
		},
		"capabilities": map[string]interface{}{
			"discovery": map[string]interface{}{
				"endpoint": "/ucp/discovery",
				"methods":  []string{"service_catalog", "availability", "coverage_area"},
			},
			"cart": map[string]interface{}{
				"endpoint": "/ucp/cart",
				"methods":  []string{"create_booking", "get_quote", "update_booking"},
			},
			"checkout": map[string]interface{}{
				"endpoint":        "/ucp/checkout",
				"methods":         []string{"process_payment"},
				"payment_methods": []string{"promptpay", "bank_transfer", "stripe"},
				"requires_customer_input": []string{
					"delivery_date",
					"pickup_address",
					"destination_address",
					"cargo_description",
				},
			},
			"fulfillment": map[string]interface{}{
				"endpoint": "/ucp/fulfillment",
				"methods":  []string{"track_delivery", "get_pod", "confirm_delivery"},
			},
		},
		"mcp_compatible": true,
		"a2a_agent_card": "/ucp/agent-card.json",
	}
}

// GetAgentCard คืน A2A Agent Card JSON
func GetAgentCard(baseURL string) map[string]interface{} {
	return map[string]interface{}{
		"name":        "BC Fleet Transport Agent",
		"description": "จัดการรถขนส่งสำหรับ SME ไทย — จอง ติดตาม และรับ POD",
		"url":         baseURL + "/a2a",
		"version":     "1.0",
		"capabilities": []string{
			"transport.freight.booking",
			"transport.freight.tracking",
			"transport.freight.pricing",
			"transport.freight.pod",
		},
		"authentication": map[string]interface{}{
			"type":   "api_key",
			"header": "X-Agent-Key",
		},
		"languages": []string{"th", "en"},
		"timezone":  "Asia/Bangkok",
	}
}
