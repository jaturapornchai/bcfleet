package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// Auth ตรวจสอบ JWT token จาก Authorization header
func Auth(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "authorization header required"})
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
			return
		}

		token := parts[1]

		// TODO: ใช้ JWT library จริงสำหรับ verify token
		// ตอนนี้ set ค่าจาก token claims
		claims, err := parseJWT(token, jwtSecret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
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
