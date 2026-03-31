package database

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// PostgresDB wrapper สำหรับ PostgreSQL connection pool
type PostgresDB struct {
	pool *pgxpool.Pool
}

// ConnectPostgres เชื่อมต่อ PostgreSQL
func ConnectPostgres(uri string) (*PostgresDB, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	config, err := pgxpool.ParseConfig(uri)
	if err != nil {
		return nil, err
	}

	config.MaxConns = 20
	config.MinConns = 5

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, err
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, err
	}

	log.Println("PostgreSQL connected")
	return &PostgresDB{pool: pool}, nil
}

// Pool ดึง connection pool
func (p *PostgresDB) Pool() *pgxpool.Pool {
	return p.pool
}

// Close ปิด connection pool
func (p *PostgresDB) Close() {
	p.pool.Close()
}
