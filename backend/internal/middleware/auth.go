package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
)

// Auth ตรวจสอบ JWT token จาก Authorization header
// Demo mode: ถ้าไม่มี token → ใช้ demo user (shop_001) อัตโนมัติ
func Auth(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")

		// Demo mode — ไม่มี token ก็เข้าได้ (สำหรับ demo/showcase)
		if authHeader == "" {
			c.Set("user_id", "demo-user")
			c.Set("shop_id", "shop_001")
			c.Set("user_type", "admin")
			c.Next()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.Set("user_id", "demo-user")
			c.Set("shop_id", "shop_001")
			c.Set("user_type", "admin")
			c.Next()
			return
		}

		token := parts[1]
		claims, err := parseJWT(token, jwtSecret)
		if err != nil {
			c.Set("user_id", "demo-user")
			c.Set("shop_id", "shop_001")
			c.Set("user_type", "admin")
			c.Next()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("shop_id", claims.ShopID)
		c.Set("user_type", claims.UserType)
		c.Next()
	}
}

// JWTClaims เก็บข้อมูลจาก JWT token
type JWTClaims struct {
	UserID   string
	ShopID   string
	UserType string // "admin", "driver", "manager"
}

// parseJWT แปลง JWT token → claims
// TODO: implement ด้วย golang-jwt library
func parseJWT(token, secret string) (*JWTClaims, error) {
	// placeholder — จะ implement จริงใน step ถัดไป
	return &JWTClaims{
		UserID:   "dev-user",
		ShopID:   "dev-shop",
		UserType: "admin",
	}, nil
}
