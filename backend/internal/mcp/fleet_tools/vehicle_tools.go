package fleet_tools

import (
	"context"
	"fmt"

	"bc-fleet/internal/service"
)

// RegisterVehicleTools ลงทะเบียน vehicle tools ทั้งหมด (8 tools)
func RegisterVehicleTools(registry *ToolRegistry, vehicleSvc *service.VehicleService) {

	// ── 1. list_vehicles ─────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "list_vehicles",
		Description: "ค้นหารถขนส่งทั้งหมด กรองด้วย type (ประเภทรถ), status (สถานะ), ownership (ความเป็นเจ้าของ)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทรถ: 4ล้อ, 6ล้อ, 10ล้อ, หัวลาก, กระบะ",
				},
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: active, maintenance, inactive",
				},
				"ownership": map[string]interface{}{
					"type":        "string",
					"description": "ความเป็นเจ้าของ: own, partner, rental",
				},
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
		status := getString(params, "status")
		vehicleType := getString(params, "type")
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)

		rows, total, err := vehicleSvc.List(ctx, shopID, status, vehicleType, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายการรถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"vehicles": rows,
			"total":    total,
			"page":     page,
			"limit":    limit,
		}, nil
	})

	// ── 2. get_vehicle ────────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_vehicle",
		Description: "ดึงข้อมูลรถคันเดียวด้วย ID",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID (MongoDB ObjectID)",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		vehicle, err := vehicleSvc.GetByID(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงข้อมูลรถล้มเหลว: %w", err)
		}
		return vehicle, nil
	})

	// ── 3. create_vehicle ─────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "create_vehicle",
		Description: "ลงทะเบียนรถขนส่งใหม่เข้าระบบ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"plate": map[string]interface{}{
					"type":        "string",
					"description": "เลขทะเบียนรถ เช่น กท-1234",
				},
				"brand": map[string]interface{}{
					"type":        "string",
					"description": "ยี่ห้อรถ เช่น ISUZU, HINO",
				},
				"model": map[string]interface{}{
					"type":        "string",
					"description": "รุ่นรถ เช่น FRR 210",
				},
				"type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทรถ: 4ล้อ, 6ล้อ, 10ล้อ, หัวลาก, กระบะ",
				},
				"year": map[string]interface{}{
					"type":        "integer",
					"description": "ปีผลิต (ค.ศ.)",
				},
				"color": map[string]interface{}{
					"type":        "string",
					"description": "สีรถ",
				},
				"chassis_no": map[string]interface{}{
					"type":        "string",
					"description": "หมายเลขตัวถัง",
				},
				"engine_no": map[string]interface{}{
					"type":        "string",
					"description": "หมายเลขเครื่องยนต์",
				},
				"fuel_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทเชื้อเพลิง: ดีเซล, เบนซิน, NGV, EV",
				},
				"max_weight_kg": map[string]interface{}{
					"type":        "integer",
					"description": "น้ำหนักบรรทุกสูงสุด (กิโลกรัม)",
				},
				"ownership": map[string]interface{}{
					"type":        "string",
					"description": "ความเป็นเจ้าของ: own, partner, rental",
				},
				"mileage_km": map[string]interface{}{
					"type":        "integer",
					"description": "เลขไมล์ปัจจุบัน (กิโลเมตร)",
				},
			},
			"required": []string{"plate", "type"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.CreateVehicleRequest{
			Plate:       getString(params, "plate"),
			Brand:       getString(params, "brand"),
			Model:       getString(params, "model"),
			Type:        getString(params, "type"),
			Year:        getInt(params, "year", 0),
			Color:       getString(params, "color"),
			ChassisNo:   getString(params, "chassis_no"),
			EngineNo:    getString(params, "engine_no"),
			FuelType:    getString(params, "fuel_type"),
			MaxWeightKg: getInt(params, "max_weight_kg", 0),
			Ownership:   getString(params, "ownership"),
			MileageKm:   getInt(params, "mileage_km", 0),
		}
		if req.Plate == "" || req.Type == "" {
			return nil, fmt.Errorf("กรุณาระบุ plate และ type")
		}
		vehicle, err := vehicleSvc.Create(ctx, shopID, "mcp_agent", req)
		if err != nil {
			return nil, fmt.Errorf("สร้างรถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"vehicle": vehicle,
			"message": fmt.Sprintf("ลงทะเบียนรถ %s สำเร็จ", req.Plate),
		}, nil
	})

	// ── 4. update_vehicle ─────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "update_vehicle",
		Description: "อัปเดตข้อมูลรถขนส่ง",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
				"brand": map[string]interface{}{
					"type":        "string",
					"description": "ยี่ห้อรถ",
				},
				"model": map[string]interface{}{
					"type":        "string",
					"description": "รุ่นรถ",
				},
				"color": map[string]interface{}{
					"type":        "string",
					"description": "สีรถ",
				},
				"fuel_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทเชื้อเพลิง",
				},
				"max_weight_kg": map[string]interface{}{
					"type":        "integer",
					"description": "น้ำหนักบรรทุกสูงสุด (กก.)",
				},
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: active, maintenance, inactive",
				},
				"mileage_km": map[string]interface{}{
					"type":        "integer",
					"description": "เลขไมล์ปัจจุบัน (กม.)",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		req := service.UpdateVehicleRequest{
			Brand:       getString(params, "brand"),
			Model:       getString(params, "model"),
			Color:       getString(params, "color"),
			FuelType:    getString(params, "fuel_type"),
			MaxWeightKg: getInt(params, "max_weight_kg", 0),
			Status:      getString(params, "status"),
			MileageKm:   getInt(params, "mileage_km", 0),
		}
		if err := vehicleSvc.Update(ctx, shopID, "mcp_agent", id, req); err != nil {
			return nil, fmt.Errorf("อัปเดตรถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"message": "อัปเดตข้อมูลรถสำเร็จ",
		}, nil
	})

	// ── 5. get_vehicle_health ─────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_vehicle_health",
		Description: "ดูสถานะสุขภาพรถ: green (ดี), yellow (เฝ้าระวัง), red (ต้องดูแล)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		health, err := vehicleSvc.GetHealth(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงสถานะสุขภาพรถล้มเหลว: %w", err)
		}
		return health, nil
	})

	// ── 6. get_vehicle_location ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_vehicle_location",
		Description: "ดูตำแหน่ง GPS ปัจจุบันของรถ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		// ดึงตำแหน่งจาก vehicle row (current_lat, current_lng)
		vehicle, err := vehicleSvc.GetByID(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงตำแหน่งรถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"vehicle_id": id,
			"plate":      vehicle.Plate,
			"driver_id":  vehicle.CurrentDriverID,
			"status":     vehicle.Status,
			"updated_at": vehicle.UpdatedAt,
			"note":       "ตำแหน่ง GPS real-time ดูผ่าน WebSocket /ws/gps หรือ fleet_vehicle_locations table",
		}, nil
	})

	// ── 7. get_vehicle_cost ───────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_vehicle_cost",
		Description: "ดูต้นทุนรวมต่อคัน (ค่าน้ำมัน ค่าซ่อม ค่าทางด่วน) แยกตามเดือน",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
				"month": map[string]interface{}{
					"type":        "integer",
					"description": "เดือน (1-12)",
				},
				"year": map[string]interface{}{
					"type":        "integer",
					"description": "ปี (ค.ศ.)",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		month := getInt(params, "month", 0)
		year := getInt(params, "year", 0)
		// ใช้ maintenance service สำหรับต้นทุนซ่อม — ดู get_maintenance_cost tool
		return map[string]interface{}{
			"vehicle_id": id,
			"month":      month,
			"year":       year,
			"note":       "ใช้ tool get_maintenance_cost สำหรับต้นทุนซ่อม และ get_cost_report สำหรับ P&L รวม",
		}, nil
	})

	// ── 8. get_vehicle_history ────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_vehicle_history",
		Description: "ดูประวัติทั้งหมดของรถ (จาก MongoDB event logs) เช่น การซ่อม การมอบหมายคนขับ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		history, err := vehicleSvc.GetHistory(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงประวัติรถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"vehicle_id": id,
			"history":    history,
			"count":      len(history),
		}, nil
	})
}
