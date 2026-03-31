package config

import "os"

// Config เก็บ configuration ทั้งหมดของระบบ
type Config struct {
	// Server
	Port string
	Env  string

	// MongoDB — Source of Truth
	MongoURI string
	MongoDB  string

	// PostgreSQL — Query Layer
	PostgresURI string

	// Kafka
	KafkaBrokers string
	KafkaGroupID string

	// Longdo Map API
	LongdoMapAPIKey string

	// LINE OA
	LineChannelSecret      string
	LineChannelAccessToken string

	// Claude API
	AnthropicAPIKey string
	ClaudeModel     string

	// Cloudflare R2
	R2AccountID string
	R2AccessKey string
	R2SecretKey string
	R2Bucket    string
	R2PublicURL string

	// Stripe
	StripeSecretKey    string
	StripeWebhookSecret string

	// JWT
	JWTSecret string
	JWTExpiry string
}

// Load อ่าน configuration จาก environment variables
func Load() *Config {
	return &Config{
		Port: getEnv("PORT", "8080"),
		Env:  getEnv("ENV", "development"),

		MongoURI: getEnv("MONGO_URI", "mongodb://localhost:27017/smlfleet"),
		MongoDB:  getEnv("MONGO_DB", "smlfleet"),

		PostgresURI: getEnv("POSTGRES_URI", "postgres://smlfleet:smlfleet_password@localhost:5432/smlfleet?sslmode=disable"),

		KafkaBrokers: getEnv("KAFKA_BROKERS", "localhost:9092"),
		KafkaGroupID: getEnv("KAFKA_GROUP_ID", "fleet-pgsql-sync"),

		LongdoMapAPIKey: getEnv("LONGDO_MAP_API_KEY", ""),

		LineChannelSecret:      getEnv("LINE_CHANNEL_SECRET", ""),
		LineChannelAccessToken: getEnv("LINE_CHANNEL_ACCESS_TOKEN", ""),

		AnthropicAPIKey: getEnv("ANTHROPIC_API_KEY", ""),
		ClaudeModel:     getEnv("CLAUDE_MODEL", "claude-haiku-4-5-20251001"),

		R2AccountID: getEnv("R2_ACCOUNT_ID", ""),
		R2AccessKey: getEnv("R2_ACCESS_KEY", ""),
		R2SecretKey: getEnv("R2_SECRET_KEY", ""),
		R2Bucket:    getEnv("R2_BUCKET", "smlfleet-files"),
		R2PublicURL: getEnv("R2_PUBLIC_URL", ""),

		StripeSecretKey:    getEnv("STRIPE_SECRET_KEY", ""),
		StripeWebhookSecret: getEnv("STRIPE_WEBHOOK_SECRET", ""),

		JWTSecret: getEnv("JWT_SECRET", "smlfleet-dev-secret"),
		JWTExpiry: getEnv("JWT_EXPIRY", "24h"),
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
