package fleet_tools

import (
	"context"
	"fmt"

	"bc-fleet/internal/models"
	"bc-fleet/internal/service"
)

// RegisterTripTools ลงทะเบียน trip tools ทั้งหมด (8 tools)
func RegisterTripTools(registry *ToolRegistry, tripSvc *service.TripService) {

	// ── 1. list_trips ─────────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "list_trips",
		Description: "ค้นหาเที่ยววิ่งทั้งหมด กรองด้วย status, driver_id, vehicle_id",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: draft, pending, accepted, started, arrived, delivering, completed, cancelled",
				},
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID (กรองตามคนขับ)",
				},
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID (กรองตามรถ)",
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
		driverID := getString(params, "driver_id")
		vehicleID := getString(params, "vehicle_id")
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)

		rows, total, err := tripSvc.List(ctx, shopID, status, driverID, vehicleID, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายการเที่ยววิ่งล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"trips": rows,
			"total": total,
			"page":  page,
			"limit": limit,
		}, nil
	})

	// ── 2. create_trip ────────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "create_trip",
		Description: "สร้างเที่ยววิ่งใหม่ ระบุต้นทาง ปลายทาง สินค้า และกำหนดเวลา",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID (ไม่บังคับ)",
				},
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID (ไม่บังคับ)",
				},
				"origin_name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อต้นทาง เช่น คลังสินค้า ABC",
				},
				"origin_address": map[string]interface{}{
					"type":        "string",
					"description": "ที่อยู่ต้นทาง",
				},
				"origin_lat": map[string]interface{}{
					"type":        "number",
					"description": "Latitude ต้นทาง",
				},
				"origin_lng": map[string]interface{}{
					"type":        "number",
					"description": "Longitude ต้นทาง",
				},
				"destination_name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อปลายทาง",
				},
				"destination_address": map[string]interface{}{
					"type":        "string",
					"description": "ที่อยู่ปลายทาง",
				},
				"destination_lat": map[string]interface{}{
					"type":        "number",
					"description": "Latitude ปลายทาง",
				},
				"destination_lng": map[string]interface{}{
					"type":        "number",
					"description": "Longitude ปลายทาง",
				},
				"cargo_description": map[string]interface{}{
					"type":        "string",
					"description": "คำอธิบายสินค้า เช่น ปูนซีเมนต์ 200 ถุง",
				},
				"cargo_weight_kg": map[string]interface{}{
					"type":        "integer",
					"description": "น้ำหนักสินค้า (กิโลกรัม)",
				},
				"planned_start": map[string]interface{}{
					"type":        "string",
					"description": "เวลาเริ่มแผน (ISO 8601: 2024-12-15T06:00:00Z)",
				},
				"planned_end": map[string]interface{}{
					"type":        "string",
					"description": "เวลาสิ้นสุดแผน (ISO 8601)",
				},
				"revenue": map[string]interface{}{
					"type":        "number",
					"description": "ค่าขนส่งที่เรียกเก็บ (บาท)",
				},
			},
			"required": []string{"origin_name", "destination_name"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		origin := models.TripLocation{
			Name:    getString(params, "origin_name"),
			Address: getString(params, "origin_address"),
			Lat:     getFloat(params, "origin_lat", 0),
			Lng:     getFloat(params, "origin_lng", 0),
		}
		destination := models.Destination{
			Seq:     1,
			Name:    getString(params, "destination_name"),
			Address: getString(params, "destination_address"),
			Lat:     getFloat(params, "destination_lat", 0),
			Lng:     getFloat(params, "destination_lng", 0),
			Status:  "pending",
		}
		req := service.CreateTripRequest{
			VehicleID:    getString(params, "vehicle_id"),
			DriverID:     getString(params, "driver_id"),
			Origin:       origin,
			Destinations: []models.Destination{destination},
			Revenue:      getFloat(params, "revenue", 0),
		}
		if req.Origin.Name == "" {
			return nil, fmt.Errorf("กรุณาระบุ origin_name")
		}
		// Parse cargo
		if desc := getString(params, "cargo_description"); desc != "" {
			req.Cargo = &models.CargoInfo{
				Description: desc,
				WeightKg:    getInt(params, "cargo_weight_kg", 0),
			}
		}

		trip, err := tripSvc.Create(ctx, shopID, "mcp_agent", req)
		if err != nil {
			return nil, fmt.Errorf("สร้างเที่ยววิ่งล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"trip":    trip,
			"message": fmt.Sprintf("สร้างเที่ยววิ่ง %s สำเร็จ", trip.TripNo),
		}, nil
	})

	// ── 3. update_trip_status ─────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "update_trip_status",
		Description: "เปลี่ยนสถานะเที่ยววิ่ง เช่น pending → accepted → started → delivering → completed",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID",
				},
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะใหม่: pending, accepted, started, arrived, delivering, completed, cancelled",
				},
			},
			"required": []string{"id", "status"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		status := getString(params, "status")
		if id == "" || status == "" {
			return nil, fmt.Errorf("กรุณาระบุ id และ status")
		}
		req := service.UpdateTripStatusRequest{Status: status}
		if err := tripSvc.UpdateStatus(ctx, shopID, "mcp_agent", id, req); err != nil {
			return nil, fmt.Errorf("เปลี่ยนสถานะล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"trip_id": id,
			"status":  status,
			"message": fmt.Sprintf("อัปเดตสถานะเป็น %s สำเร็จ", status),
		}, nil
	})

	// ── 4. assign_trip ────────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "assign_trip",
		Description: "มอบหมายรถและคนขับให้กับเที่ยววิ่ง",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID",
				},
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID ที่ต้องการมอบหมาย",
				},
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID ที่ต้องการมอบหมาย",
				},
				"is_partner": map[string]interface{}{
					"type":        "boolean",
					"description": "true ถ้าเป็นรถร่วม",
				},
				"partner_id": map[string]interface{}{
					"type":        "string",
					"description": "Partner ID (ถ้าเป็นรถร่วม)",
				},
			},
			"required": []string{"id", "vehicle_id", "driver_id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		req := service.AssignTripRequest{
			VehicleID: getString(params, "vehicle_id"),
			DriverID:  getString(params, "driver_id"),
			IsPartner: getBool(params, "is_partner"),
			PartnerID: getString(params, "partner_id"),
		}
		if req.VehicleID == "" || req.DriverID == "" {
			return nil, fmt.Errorf("กรุณาระบุ vehicle_id และ driver_id")
		}
		if err := tripSvc.Assign(ctx, shopID, "mcp_agent", id, req); err != nil {
			return nil, fmt.Errorf("มอบหมายงานล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success":    true,
			"trip_id":    id,
			"vehicle_id": req.VehicleID,
			"driver_id":  req.DriverID,
			"message":    "มอบหมายรถและคนขับสำเร็จ",
		}, nil
	})

	// ── 5. calculate_route_cost ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "calculate_route_cost",
		Description: "คำนวณค่าขนส่งและระยะทางจากต้นทางไปปลายทาง (ใช้ Longdo Map API)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"from": map[string]interface{}{
					"type":        "string",
					"description": "ต้นทาง เช่น เชียงใหม่",
				},
				"to": map[string]interface{}{
					"type":        "string",
					"description": "ปลายทาง เช่น ลำพูน",
				},
				"vehicle_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทรถ (กระทบต้นทุนน้ำมัน)",
				},
				"cargo_weight_kg": map[string]interface{}{
					"type":        "integer",
					"description": "น้ำหนักสินค้า (กก.)",
				},
			},
			"required": []string{"from", "to"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		from := getString(params, "from")
		to := getString(params, "to")
		vehicleType := getString(params, "vehicle_type")
		cargoKg := getInt(params, "cargo_weight_kg", 0)

		if from == "" || to == "" {
			return nil, fmt.Errorf("กรุณาระบุ from และ to")
		}

		// estimation อย่างง่าย (จะถูก replace ด้วย Longdo Map API จริง)
		return map[string]interface{}{
			"from":           from,
			"to":             to,
			"vehicle_type":   vehicleType,
			"cargo_weight_kg": cargoKg,
			"estimated_km":   45,
			"estimated_fuel_l": 9.0,
			"fuel_cost_thb":  225,
			"toll_cost_thb":  60,
			"total_cost_thb": 285,
			"note":           "ค่าประมาณการ — ระบบจะเชื่อม Longdo Map API สำหรับเส้นทางจริง",
		}, nil
	})

	// ── 6. track_shipment ─────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "track_shipment",
		Description: "ติดตามตำแหน่ง GPS ของเที่ยววิ่งแบบ real-time",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		trail, err := tripSvc.GetTracking(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงข้อมูล GPS ล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"trip_id": id,
			"trail":   trail,
			"count":   len(trail),
		}, nil
	})

	// ── 7. get_trip_pod ───────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_trip_pod",
		Description: "ดูหลักฐานการส่งมอบ (Proof of Delivery) รูปถ่าย ลายเซ็น ผู้รับ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		pod, err := tripSvc.GetPOD(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึง POD ล้มเหลว: %w", err)
		}
		return pod, nil
	})

	// ── 8. get_trip_cost_breakdown ────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_trip_cost_breakdown",
		Description: "ดูรายละเอียดต้นทุนต่อเที่ยว (น้ำมัน ทางด่วน เบี้ยเลี้ยง กำไร)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		cost, err := tripSvc.GetCostBreakdown(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงต้นทุนเที่ยวล้มเหลว: %w", err)
		}
		return cost, nil
	})
}
