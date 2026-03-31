package fleet_tools

import (
	"context"
	"fmt"

	"bc-fleet/internal/models"
	"bc-fleet/internal/service"
)

// RegisterMaintenanceTools ลงทะเบียน maintenance tools ทั้งหมด (8 tools)
func RegisterMaintenanceTools(registry *ToolRegistry, maintenanceSvc *service.MaintenanceService) {

	// ── 1. list_maintenance_schedule ──────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "list_maintenance_schedule",
		Description: "ดูรายการรถที่ใกล้ถึงกำหนดซ่อมบำรุง (แยกตามระยะทางและวันที่)",
		InputSchema: map[string]interface{}{
			"type":       "object",
			"properties": map[string]interface{}{},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		rows, err := maintenanceSvc.GetDue(ctx, shopID)
		if err != nil {
			return nil, fmt.Errorf("ดึงตารางซ่อมบำรุงล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"schedule": rows,
			"count":    len(rows),
		}, nil
	})

	// ── 2. create_work_order ──────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "create_work_order",
		Description: "สร้างใบสั่งซ่อมรถ (preventive/corrective/emergency)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
				"type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทงานซ่อม: preventive (ป้องกัน), corrective (แก้ไข), emergency (ฉุกเฉิน)",
				},
				"priority": map[string]interface{}{
					"type":        "string",
					"description": "ความเร่งด่วน: low, medium, high, critical",
				},
				"description": map[string]interface{}{
					"type":        "string",
					"description": "รายละเอียดงานซ่อม",
				},
				"symptoms": map[string]interface{}{
					"type":        "string",
					"description": "อาการที่พบ",
				},
				"mileage_at_report": map[string]interface{}{
					"type":        "integer",
					"description": "เลขไมล์ ณ วันแจ้งซ่อม",
				},
				"service_provider_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทช่าง: internal (อู่ใน), external (อู่นอก)",
				},
				"service_provider_name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อช่าง/อู่",
				},
			},
			"required": []string{"vehicle_id", "type", "description"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.CreateWorkOrderRequest{
			VehicleID:       getString(params, "vehicle_id"),
			Type:            getString(params, "type"),
			Priority:        getString(params, "priority"),
			Description:     getString(params, "description"),
			Symptoms:        getString(params, "symptoms"),
			MileageAtReport: getInt(params, "mileage_at_report", 0),
		}
		if req.VehicleID == "" || req.Type == "" || req.Description == "" {
			return nil, fmt.Errorf("กรุณาระบุ vehicle_id, type, description")
		}
		// build ServiceProvider ถ้ามีข้อมูล
		if spType := getString(params, "service_provider_type"); spType != "" {
			req.ServiceProvider = &models.ServiceProvider{
				Type: spType,
				Name: getString(params, "service_provider_name"),
			}
		}
		wo, err := maintenanceSvc.CreateWorkOrder(ctx, shopID, "mcp_agent", req)
		if err != nil {
			return nil, fmt.Errorf("สร้างใบสั่งซ่อมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success":      true,
			"work_order":   wo,
			"message":      fmt.Sprintf("สร้างใบสั่งซ่อม %s สำเร็จ", wo.WONo),
		}, nil
	})

	// ── 3. get_work_order ─────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_work_order",
		Description: "ดูรายละเอียดใบสั่งซ่อม",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Work Order ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		wo, err := maintenanceSvc.GetWorkOrder(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงใบสั่งซ่อมล้มเหลว: %w", err)
		}
		return wo, nil
	})

	// ── 4. update_work_order ──────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "update_work_order",
		Description: "อัปเดตข้อมูลใบสั่งซ่อม (อะไหล่ ค่าแรง สถานะ)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Work Order ID",
				},
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: draft, pending_approval, approved, in_progress, completed, cancelled",
				},
				"description": map[string]interface{}{
					"type":        "string",
					"description": "รายละเอียดงาน",
				},
				"total_cost": map[string]interface{}{
					"type":        "number",
					"description": "ค่าใช้จ่ายรวม (บาท)",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		req := service.UpdateWorkOrderRequest{
			Status:      getString(params, "status"),
			Description: getString(params, "description"),
			TotalCost:   getFloat(params, "total_cost", 0),
		}
		if err := maintenanceSvc.UpdateWorkOrder(ctx, shopID, "mcp_agent", id, req); err != nil {
			return nil, fmt.Errorf("อัปเดตใบสั่งซ่อมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"message": "อัปเดตใบสั่งซ่อมสำเร็จ",
		}, nil
	})

	// ── 5. approve_work_order ─────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "approve_work_order",
		Description: "อนุมัติใบสั่งซ่อม (สามารถทำผ่าน AI Agent ได้)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Work Order ID ที่ต้องการอนุมัติ",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		if err := maintenanceSvc.Approve(ctx, shopID, "mcp_agent", id); err != nil {
			return nil, fmt.Errorf("อนุมัติใบสั่งซ่อมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"wo_id":   id,
			"message": "อนุมัติใบสั่งซ่อมสำเร็จ",
		}, nil
	})

	// ── 6. complete_work_order ────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "complete_work_order",
		Description: "ปิดงานซ่อม พร้อมคิดค่าใช้จ่ายทั้งหมด",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Work Order ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		if err := maintenanceSvc.Complete(ctx, shopID, "mcp_agent", id); err != nil {
			return nil, fmt.Errorf("ปิดงานซ่อมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"wo_id":   id,
			"message": "ปิดงานซ่อมสำเร็จ",
		}, nil
	})

	// ── 7. get_maintenance_cost ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_maintenance_cost",
		Description: "ดูต้นทุนซ่อมบำรุงต่อคัน แยกตามประเภทและเดือน",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
			},
			"required": []string{"vehicle_id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		vehicleID := getString(params, "vehicle_id")
		if vehicleID == "" {
			return nil, fmt.Errorf("กรุณาระบุ vehicle_id")
		}
		cost, err := maintenanceSvc.GetMaintenanceCost(ctx, shopID, vehicleID)
		if err != nil {
			return nil, fmt.Errorf("ดึงต้นทุนซ่อมล้มเหลว: %w", err)
		}
		return cost, nil
	})

	// ── 8. list_parts_inventory ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "list_parts_inventory",
		Description: "ดูสต๊อกอะไหล่คงเหลือทั้งหมด รวมถึงอะไหล่ที่ต่ำกว่า min_qty",
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
		parts, total, err := maintenanceSvc.ListParts(ctx, shopID, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงสต๊อกอะไหล่ล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"parts": parts,
			"total": total,
			"page":  page,
			"limit": limit,
		}, nil
	})
}
