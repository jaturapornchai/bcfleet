package fleet_tools

import (
	"context"
	"fmt"
	"time"

	"sml-fleet/internal/models"
	"sml-fleet/internal/service"
)

// RegisterExpenseTools ลงทะเบียน expense tools (3 tools)
func RegisterExpenseTools(registry *ToolRegistry, expenseSvc *service.ExpenseService) {

	// ── 1. record_expense ─────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "record_expense",
		Description: "บันทึกค่าใช้จ่ายรถขนส่ง เช่น ค่าน้ำมัน ค่าทางด่วน ค่าซ่อม",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID ที่บันทึกค่าใช้จ่าย",
				},
				"trip_id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID (ถ้าผูกกับเที่ยววิ่ง)",
				},
				"type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทค่าใช้จ่าย: fuel, toll, parking, repair, fine, other",
				},
				"description": map[string]interface{}{
					"type":        "string",
					"description": "คำอธิบาย เช่น เติมดีเซล ปตท. สาขาเชียงใหม่",
				},
				"amount": map[string]interface{}{
					"type":        "number",
					"description": "จำนวนเงิน (บาท)",
				},
				"fuel_liters": map[string]interface{}{
					"type":        "number",
					"description": "ปริมาณน้ำมัน (ลิตร) — สำหรับ type = fuel",
				},
				"fuel_price_per_liter": map[string]interface{}{
					"type":        "number",
					"description": "ราคาน้ำมันต่อลิตร (บาท) — สำหรับ type = fuel",
				},
				"odometer_km": map[string]interface{}{
					"type":        "integer",
					"description": "เลขไมล์ ณ เวลาเติมน้ำมัน — สำหรับ type = fuel",
				},
				"receipt_url": map[string]interface{}{
					"type":        "string",
					"description": "URL ใบเสร็จ (จาก R2)",
				},
			},
			"required": []string{"vehicle_id", "type", "amount"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.CreateExpenseRequest{
			VehicleID:   getString(params, "vehicle_id"),
			DriverID:    getString(params, "driver_id"),
			TripID:      getString(params, "trip_id"),
			Type:        getString(params, "type"),
			Description: getString(params, "description"),
			Amount:      getFloat(params, "amount", 0),
			ReceiptURL:  getString(params, "receipt_url"),
		}
		if req.VehicleID == "" || req.Type == "" || req.Amount == 0 {
			return nil, fmt.Errorf("กรุณาระบุ vehicle_id, type, amount")
		}

		// เพิ่ม fuel detail ถ้าเป็นค่าน้ำมัน
		if req.Type == "fuel" {
			liters := getFloat(params, "fuel_liters", 0)
			pricePerLiter := getFloat(params, "fuel_price_per_liter", 0)
			odometerKm := getInt(params, "odometer_km", 0)
			if liters > 0 {
				req.FuelDetail = &models.FuelDetail{
					Liters:        liters,
					PricePerLiter: pricePerLiter,
					OdometerKm:    odometerKm,
				}
			}
		}

		expense, err := expenseSvc.Create(ctx, shopID, "mcp_agent", req)
		if err != nil {
			return nil, fmt.Errorf("บันทึกค่าใช้จ่ายล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"expense": expense,
			"message": fmt.Sprintf("บันทึกค่าใช้จ่าย %.2f บาท สำเร็จ", req.Amount),
		}, nil
	})

	// ── 2. get_fuel_report ────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_fuel_report",
		Description: "รายงานการใช้น้ำมัน: ปริมาณ ค่าใช้จ่าย อัตราสิ้นเปลือง (กม./ลิตร)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID (เว้นว่างเพื่อดูทุกคัน)",
				},
				"date_from": map[string]interface{}{
					"type":        "string",
					"description": "วันเริ่มต้น (YYYY-MM-DD)",
				},
				"date_to": map[string]interface{}{
					"type":        "string",
					"description": "วันสิ้นสุด (YYYY-MM-DD)",
				},
			},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		vehicleID := getString(params, "vehicle_id")

		from := time.Now().AddDate(0, -1, 0) // default: 1 เดือนที่แล้ว
		to := time.Now()

		if dateFrom := getString(params, "date_from"); dateFrom != "" {
			if t, err := time.Parse("2006-01-02", dateFrom); err == nil {
				from = t
			}
		}
		if dateTo := getString(params, "date_to"); dateTo != "" {
			if t, err := time.Parse("2006-01-02", dateTo); err == nil {
				to = t
			}
		}

		report, err := expenseSvc.GetFuelReport(ctx, shopID, vehicleID, from, to)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายงานน้ำมันล้มเหลว: %w", err)
		}
		return report, nil
	})

	// ── 3. get_cost_report ────────────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_cost_report",
		Description: "รายงาน P&L ต้นทุน-รายได้ต่อคัน แยกตามเดือน",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
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
			"required": []string{"vehicle_id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		vehicleID := getString(params, "vehicle_id")
		month := getInt(params, "month", int(time.Now().Month()))
		year := getInt(params, "year", time.Now().Year())

		if vehicleID == "" {
			return nil, fmt.Errorf("กรุณาระบุ vehicle_id")
		}
		report, err := expenseSvc.GetPLPerVehicle(ctx, shopID, vehicleID, month, year)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายงานต้นทุนล้มเหลว: %w", err)
		}
		return report, nil
	})
}
