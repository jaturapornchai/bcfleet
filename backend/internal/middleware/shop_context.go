package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ShopContext ดึง shop_id จาก JWT claims เพื่อ multi-tenant isolation
func ShopContext() gin.HandlerFunc {
	return func(c *gin.Context) {
		shopID := c.GetString("shop_id")
		if shopID == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "shop_id required"})
			return
		}
		c.Set("shop_id", shopID)
		c.Next()
	}
}
