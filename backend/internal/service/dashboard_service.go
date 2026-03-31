package service

import (
	"context"

	pgquery "sml-fleet/internal/repository/postgres"
)

// DashboardService business logic สำหรับ dashboard และรายงาน (read-only, ไม่มี Kafka)
type DashboardService struct {
	pgQuery *pgquery.DashboardQuery
}

// NewDashboardService สร้าง DashboardService ใหม่
func NewDashboardService(pgQuery *pgquery.DashboardQuery) *DashboardService {
	return &DashboardService{pgQuery: pgQuery}
}

// GetSummary ดึงสรุปภาพรวมฝูงรถ
func (s *DashboardService) GetSummary(ctx context.Context, shopID string) (*pgquery.FleetSummaryRow, error) {
	return s.pgQuery.GetFleetSummary(ctx, shopID)
}

// GetKPI ดึง KPI metrics
func (s *DashboardService) GetKPI(ctx context.Context, shopID string) (*pgquery.FleetKPIRow, error) {
	return s.pgQuery.GetFleetKPI(ctx, shopID)
}

// GetAlerts ดึงแจ้งเตือน active ทั้งหมด
func (s *DashboardService) GetAlerts(ctx context.Context, shopID string, page, limit int) ([]pgquery.AlertRow, int, error) {
	return s.pgQuery.GetActiveAlerts(ctx, shopID, page, limit)
}

// GetCostReport ดึงรายงานต้นทุนขนส่ง
func (s *DashboardService) GetCostReport(ctx context.Context, shopID, period string) (*pgquery.CostReportRow, error) {
	return s.pgQuery.GetCostReport(ctx, shopID, period)
}

// GetCostPerTrip ดึงต้นทุนต่อเที่ยว
func (s *DashboardService) GetCostPerTrip(ctx context.Context, shopID string, page, limit int) ([]pgquery.CostPerTripRow, int, error) {
	return s.pgQuery.GetCostPerTrip(ctx, shopID, page, limit)
}

// GetVehicleUtilization ดึงอัตราการใช้รถ
func (s *DashboardService) GetVehicleUtilization(ctx context.Context, shopID string) ([]pgquery.VehicleUtilizationRow, error) {
	return s.pgQuery.GetVehicleUtilization(ctx, shopID)
}

// GetFuelEfficiency ดึงประสิทธิภาพน้ำมัน
func (s *DashboardService) GetFuelEfficiency(ctx context.Context, shopID string) ([]pgquery.FuelEfficiencyRow, error) {
	return s.pgQuery.GetFuelEfficiency(ctx, shopID)
}

// GetDriverPerformance ดึงผลงานคนขับ
func (s *DashboardService) GetDriverPerformance(ctx context.Context, shopID string, page, limit int) ([]pgquery.DriverPerformanceRow, int, error) {
	return s.pgQuery.GetDriverPerformance(ctx, shopID, page, limit)
}
