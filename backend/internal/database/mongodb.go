package database

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MongoDB wrapper สำหรับจัดการ connection
type MongoDB struct {
	client *mongo.Client
	db     *mongo.Database
	dbName string
}

// ConnectMongo เชื่อมต่อ MongoDB
func ConnectMongo(uri, dbName string) (*MongoDB, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOpts := options.Client().ApplyURI(uri)
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		return nil, err
	}

	// Ping เพื่อตรวจสอบการเชื่อมต่อ
	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}

	log.Printf("MongoDB connected: %s", dbName)
	return &MongoDB{
		client: client,
		db:     client.Database(dbName),
		dbName: dbName,
	}, nil
}

// Collection ดึง collection ตามชื่อ
func (m *MongoDB) Collection(name string) *mongo.Collection {
	return m.db.Collection(name)
}

// DB ดึง database instance
func (m *MongoDB) DB() *mongo.Database {
	return m.db
}

// Disconnect ปิด connection
func (m *MongoDB) Disconnect() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := m.client.Disconnect(ctx); err != nil {
		log.Printf("MongoDB disconnect error: %v", err)
	}
}
