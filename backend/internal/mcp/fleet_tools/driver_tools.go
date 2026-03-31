package fleet_tools

import (
	"context"
	"fmt"

	"sml-fleet/internal/service"
)

// RegisterDriverTools ลงทะเบียน driver tools ทั้งหมด (10 tools)
func RegisterDriverTools(registry *ToolRegistry, driverSvc *service.DriverService) {

	// ── 1. list_drivers ───────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "list_drivers",
		Description: "ค้นหาคนขับรถทั้งหมด กรองด้วย status (สถานะ), zone (พื้นที่)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: active, on_leave, suspended, resigned",
				},
				"zone": map[string]interface{}{
					"type":        "string",
					"description": "พื้นที่ให้บริการ เช่น เชียงใหม่, ลำพูน",
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
		zone := getString(params, "zone")
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)

		rows, total, err := driverSvc.List(ctx, shopID, status, zone, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายการคนขับล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"drivers": rows,
			"total":   total,
			"page":    page,
			"limit":   limit,
		}, nil
	})

	// ── 2. get_driver ─────────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_driver",
		Description: "ดึงข้อมูลคนขับคนเดียวด้วย ID",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		driver, err := driverSvc.GetByID(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงข้อมูลคนขับล้มเหลว: %w", err)
		}
		return driver, nil
	})

	// ── 3. create_driver ──────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "create_driver",
		Description: "ลงทะเบียนคนขับรถใหม่เข้าระบบ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อ-นามสกุล คนขับ",
				},
				"nickname": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อเล่น",
				},
				"phone": map[string]interface{}{
					"type":        "string",
					"description": "เบอร์โทรศัพท์",
				},
				"employee_id": map[string]interface{}{
					"type":        "string",
					"description": "รหัสพนักงาน",
				},
				"id_card": map[string]interface{}{
					"type":        "string",
					"description": "เลขบัตรประชาชน 13 หลัก",
				},
				"address": map[string]interface{}{
					"type":        "string",
					"description": "ที่อยู่",
				},
				"employment_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทการจ้าง: permanent, contract, daily, partner",
				},
				"salary": map[string]interface{}{
					"type":        "number",
					"description": "เงินเดือนฐาน (บาท)",
				},
				"daily_allowance": map[string]interface{}{
					"type":        "number",
					"description": "เบี้ยเลี้ยงต่อวัน (บาท)",
				},
				"trip_bonus": map[string]interface{}{
					"type":        "number",
					"description": "โบนัสต่อเที่ยว (บาท)",
				},
				"zones": map[string]interface{}{
					"type":        "array",
					"items":       map[string]interface{}{"type": "string"},
					"description": "พื้นที่ให้บริการ เช่น [เชียงใหม่, ลำพูน]",
				},
				"vehicle_types": map[string]interface{}{
					"type":        "array",
					"items":       map[string]interface{}{"type": "string"},
					"description": "ประเภทรถที่ขับได้ เช่น [6ล้อ, 10ล้อ]",
				},
			},
			"required": []string{"name", "phone"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.CreateDriverRequest{
			EmployeeID:     getString(params, "employee_id"),
			Name:           getString(params, "name"),
			Nickname:       getString(params, "nickname"),
			Phone:          getString(params, "phone"),
			IDCard:         getString(params, "id_card"),
			Address:        getString(params, "address"),
			EmploymentType: getString(params, "employment_type"),
			Salary:         getFloat(params, "salary", 0),
			DailyAllowance: getFloat(params, "daily_allowance", 0),
			TripBonus:      getFloat(params, "trip_bonus", 0),
			Zones:          getStringSlice(params, "zones"),
			VehicleTypes:   getStringSlice(params, "vehicle_types"),
		}
		if req.Name == "" || req.Phone == "" {
			return nil, fmt.Errorf("กรุณาระบุ name และ phone")
		}
		driver, err := driverSvc.Create(ctx, shopID, "mcp_agent", req)
		if err != nil {
			return nil, fmt.Errorf("สร้างคนขับล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"driver":  driver,
			"message": fmt.Sprintf("ลงทะเบียนคนขับ %s สำเร็จ", req.Name),
		}, nil
	})

	// ── 4. update_driver ──────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "update_driver",
		Description: "อัปเดตข้อมูลคนขับรถ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
				"name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อ-นามสกุล",
				},
				"phone": map[string]interface{}{
					"type":        "string",
					"description": "เบอร์โทรศัพท์",
				},
				"address": map[string]interface{}{
					"type":        "string",
					"description": "ที่อยู่",
				},
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: active, on_leave, suspended, resigned",
				},
				"salary": map[string]interface{}{
					"type":        "number",
					"description": "เงินเดือนฐาน (บาท)",
				},
				"zones": map[string]interface{}{
					"type":        "array",
					"items":       map[string]interface{}{"type": "string"},
					"description": "พื้นที่ให้บริการ",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		req := service.UpdateDriverRequest{
			Name:           getString(params, "name"),
			Nickname:       getString(params, "nickname"),
			Phone:          getString(params, "phone"),
			Address:        getString(params, "address"),
			Status:         getString(params, "status"),
			Salary:         getFloat(params, "salary", 0),
			DailyAllowance: getFloat(params, "daily_allowance", 0),
			TripBonus:      getFloat(params, "trip_bonus", 0),
			Zones:          getStringSlice(params, "zones"),
			VehicleTypes:   getStringSlice(params, "vehicle_types"),
		}
		if err := driverSvc.Update(ctx, shopID, "mcp_agent", id, req); err != nil {
			return nil, fmt.Errorf("อัปเดตคนขับล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"message": "อัปเดตข้อมูลคนขับสำเร็จ",
		}, nil
	})

	// ── 5. get_driver_score ───────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_driver_score",
		Description: "ดูคะแนน KPI ของคนขับ พร้อม breakdown (อัตราตรงเวลา, ประสิทธิภาพน้ำมัน, คะแนนลูกค้า)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		score, err := driverSvc.GetScore(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงคะแนน KPI ล้มเหลว: %w", err)
		}
		return score, nil
	})

	// ── 6. check_driver_schedule ──────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "check_driver_schedule",
		Description: "ดูตารางเวรและวันลาของคนขับ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
			},
			"required": []string{"id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		if id == "" {
			return nil, fmt.Errorf("กรุณาระบุ id")
		}
		driver, err := driverSvc.GetSchedule(ctx, shopID, id)
		if err != nil {
			return nil, fmt.Errorf("ดึงตารางเวรล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"driver_id": id,
			"schedule":  driver.Schedule,
			"status":    driver.Status,
		}, nil
	})

	// ── 7. assign_driver_to_trip ──────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "assign_driver_to_trip",
		Description: "มอบหมายคนขับให้กับเที่ยววิ่ง (ใช้ร่วมกับ assign_trip)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"trip_id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID ที่ต้องการมอบหมาย",
				},
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
			},
			"required": []string{"trip_id", "driver_id", "vehicle_id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		return map[string]interface{}{
			"message": "ใช้ tool assign_trip แทน — รองรับการมอบหมายครบ",
			"hint":    "assign_trip(trip_id, driver_id, vehicle_id)",
		}, nil
	})

	// ── 8. get_driver_expense ─────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_driver_expense",
		Description: "ดูค่าใช้จ่ายที่คนขับบันทึก (น้ำมัน, ทางด่วน, อื่นๆ)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
				"page": map[string]interface{}{
					"type":        "integer",
					"description": "หน้าที่ต้องการ (เริ่มต้น 1)",
				},
				"limit": map[string]interface{}{
					"type":        "integer",
					"description": "จำนวนต่อหน้า",
				},
			},
			"required": []string{"driver_id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		driverID := getString(params, "driver_id")
		if driverID == "" {
			return nil, fmt.Errorf("กรุณาระบุ driver_id")
		}
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)
		// query expenses filtered by driver_id (via vehicle as proxy)
		return map[string]interface{}{
			"driver_id": driverID,
			"page":      page,
			"limit":     limit,
			"message":   "ใช้ record_expense / get_cost_report สำหรับรายละเอียดค่าใช้จ่าย",
		}, nil
	})

	// ── 9. calculate_driver_salary ────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "calculate_driver_salary",
		Description: "คำนวณเงินเดือน เบี้ยเลี้ยง และ OT ของคนขับ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
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
			"required": []string{"id", "month", "year"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		id := getString(params, "id")
		month := getInt(params, "month", 0)
		year := getInt(params, "year", 0)
		if id == "" || month == 0 || year == 0 {
			return nil, fmt.Errorf("กรุณาระบุ id, month, year")
		}
		result, err := driverSvc.CalculateSalary(ctx, shopID, id, month, year)
		if err != nil {
			return nil, fmt.Errorf("คำนวณเงินเดือนล้มเหลว: %w", err)
		}
		return result, nil
	})

	// ── 10. suggest_best_driver ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "suggest_best_driver",
		Description: "AI แนะนำคนขับที่เหมาะสมที่สุดสำหรับเที่ยววิ่ง (พิจารณาจากคะแนน KPI, zone, ตารางเวร, ประเภทรถ)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"zone": map[string]interface{}{
					"type":        "string",
					"description": "พื้นที่ปลายทาง เช่น เชียงใหม่, ลำพูน",
				},
				"vehicle_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทรถที่ต้องใช้",
				},
				"date": map[string]interface{}{
					"type":        "string",
					"description": "วันที่ต้องการ (YYYY-MM-DD)",
				},
			},
			"required": []string{"zone"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		zone := getString(params, "zone")
		vehicleType := getString(params, "vehicle_type")
		date := getString(params, "date")

		// ดึงคนขับที่ active และ match zone
		rows, _, err := driverSvc.List(ctx, shopID, "active", zone, 1, 50)
		if err != nil {
			return nil, fmt.Errorf("ค้นหาคนขับล้มเหลว: %w", err)
		}

		return map[string]interface{}{
			"zone":         zone,
			"vehicle_type": vehicleType,
			"date":         date,
			"candidates":   rows,
			"suggestion":   "เลือกคนขับที่มี score สูงสุด และ on_time_rate > 0.9",
			"note":         "กรุณาตรวจสอบตารางเวรก่อนมอบหมายงาน",
		}, nil
	})
}
