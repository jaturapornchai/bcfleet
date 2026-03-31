package fleet_tools

import (
	"context"
	"fmt"

	"sml-fleet/internal/service"
)

// RegisterDashboardTools ลงทะเบียน dashboard tools ทั้งหมด (6 tools)
func RegisterDashboardTools(registry *ToolRegistry, dashboardSvc *service.DashboardService) {

	// ── 1. get_fleet_summary ──────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_fleet_summary",
		Description: "สรุปภาพรวมฝูงรถ: จำนวนรถ คนขับ เที่ยววิ่งวันนี้ ต้นทุน-รายได้",
		InputSchema: map[string]interface{}{
			"type":       "object",
			"properties": map[string]interface{}{},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		summary, err := dashboardSvc.GetSummary(ctx, shopID)
		if err != nil {
			return nil, fmt.Errorf("ดึงสรุปภาพรวมล้มเหลว: %w", err)
		}
		return summary, nil
	})

	// ── 2. get_fleet_kpi ──────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_fleet_kpi",
		Description: "ดู KPI หลักของฝูงรถ: อัตราใช้รถ, ตรงเวลา, ประสิทธิภาพน้ำมัน",
		InputSchema: map[string]interface{}{
			"type":       "object",
			"properties": map[string]interface{}{},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		kpi, err := dashboardSvc.GetKPI(ctx, shopID)
		if err != nil {
			return nil, fmt.Errorf("ดึง KPI ล้มเหลว: %w", err)
		}
		return kpi, nil
	})

	// ── 3. get_active_alerts ──────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_active_alerts",
		Description: "ดูแจ้งเตือนที่ยัง active ทั้งหมด (พ.ร.บ.หมด, ภาษีค้าง, ซ่อมเกินกำหนด, ใบขับขี่หมดอายุ)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"page": map[string]interface{}{
					"type":        "integer",
					"description": "หน้าที่ต้องการ (เริ่มต้น 1)",
				},
				"limit": map[string]interface{}{
					"type":        "integer",
					"description": "จำนวนต่อหน้า (เริ่มต้น 20)",
				},
			},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)

		alerts, total, err := dashboardSvc.GetAlerts(ctx, shopID, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงแจ้งเตือนล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"alerts": alerts,
			"total":  total,
			"page":   page,
			"limit":  limit,
		}, nil
	})

	// ── 4. get_cost_overview ──────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_cost_overview",
		Description: "ดูภาพรวมต้นทุนขนส่ง: ต้นทุนต่อเที่ยว รายได้ กำไร แยกตามช่วงเวลา",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"page": map[string]interface{}{
					"type":        "integer",
					"description": "หน้าที่ต้องการ (เริ่มต้น 1)",
				},
				"limit": map[string]interface{}{
					"type":        "integer",
					"description": "จำนวนต่อหน้า",
				},
			},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)

		costs, total, err := dashboardSvc.GetCostPerTrip(ctx, shopID, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงต้นทุนต่อเที่ยวล้มเหลว: %w", err)
		}
		utilization, err := dashboardSvc.GetVehicleUtilization(ctx, shopID)
		if err != nil {
			return nil, fmt.Errorf("ดึงอัตราการใช้รถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"cost_per_trip": costs,
			"total":         total,
			"page":          page,
			"utilization":   utilization,
		}, nil
	})

	// ── 5. get_fuel_efficiency_report ─────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_fuel_efficiency_report",
		Description: "รายงานประสิทธิภาพน้ำมันทุกคัน (กม./ลิตร) เรียงจากดีไปแย่",
		InputSchema: map[string]interface{}{
			"type":       "object",
			"properties": map[string]interface{}{},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		efficiency, err := dashboardSvc.GetFuelEfficiency(ctx, shopID)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายงานประสิทธิภาพน้ำมันล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"fuel_efficiency": efficiency,
			"count":           len(efficiency),
		}, nil
	})

	// ── 6. get_driver_leaderboard ─────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_driver_leaderboard",
		Description: "อันดับคนขับรถตาม KPI score (ตรงเวลา, ประสิทธิภาพน้ำมัน, คะแนนลูกค้า)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"page": map[string]interface{}{
					"type":        "integer",
					"description": "หน้าที่ต้องการ (เริ่มต้น 1)",
				},
				"limit": map[string]interface{}{
					"type":        "integer",
					"description": "จำนวนต่อหน้า (เริ่มต้น 10)",
				},
			},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 10)

		drivers, total, err := dashboardSvc.GetDriverPerformance(ctx, shopID, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึง leaderboard คนขับล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"leaderboard": drivers,
			"total":       total,
			"page":        page,
			"limit":       limit,
		}, nil
	})
}
