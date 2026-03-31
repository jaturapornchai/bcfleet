package fleet_tools

import (
	"context"
	"fmt"

	"bc-fleet/internal/models"
	"bc-fleet/internal/service"
)

// RegisterPartnerTools ลงทะเบียน partner tools ทั้งหมด (6 tools)
func RegisterPartnerTools(registry *ToolRegistry, partnerSvc *service.PartnerService) {

	// ── 1. register_partner_vehicle ───────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "register_partner_vehicle",
		Description: "ลงทะเบียนรถร่วม (sub-contractor) เข้าระบบ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"owner_name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อเจ้าของรถร่วม",
				},
				"owner_company": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อบริษัท (ถ้ามี)",
				},
				"owner_phone": map[string]interface{}{
					"type":        "string",
					"description": "เบอร์โทรเจ้าของ",
				},
				"owner_tax_id": map[string]interface{}{
					"type":        "string",
					"description": "เลขที่ผู้เสียภาษี 13 หลัก",
				},
				"owner_bank": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อธนาคาร เช่น กสิกรไทย",
				},
				"owner_bank_account": map[string]interface{}{
					"type":        "string",
					"description": "เลขบัญชีธนาคาร",
				},
				"owner_bank_account_name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อบัญชีธนาคาร",
				},
				"vehicle_plate": map[string]interface{}{
					"type":        "string",
					"description": "เลขทะเบียนรถร่วม",
				},
				"vehicle_brand": map[string]interface{}{
					"type":        "string",
					"description": "ยี่ห้อรถ",
				},
				"vehicle_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทรถ: 4ล้อ, 6ล้อ, 10ล้อ, หัวลาก",
				},
				"vehicle_year": map[string]interface{}{
					"type":        "integer",
					"description": "ปีผลิต",
				},
				"max_weight_kg": map[string]interface{}{
					"type":        "integer",
					"description": "น้ำหนักบรรทุกสูงสุด (กก.)",
				},
				"driver_name": map[string]interface{}{
					"type":        "string",
					"description": "ชื่อคนขับรถร่วม",
				},
				"driver_phone": map[string]interface{}{
					"type":        "string",
					"description": "เบอร์โทรคนขับ",
				},
				"pricing_model": map[string]interface{}{
					"type":        "string",
					"description": "รูปแบบราคา: per_trip (ต่อเที่ยว), per_km (ต่อกม.), per_day (ต่อวัน)",
				},
				"base_rate": map[string]interface{}{
					"type":        "number",
					"description": "ราคาฐาน (บาท)",
				},
				"coverage_zones": map[string]interface{}{
					"type":        "array",
					"items":       map[string]interface{}{"type": "string"},
					"description": "พื้นที่ให้บริการ เช่น [เชียงใหม่, ลำพูน]",
				},
			},
			"required": []string{"owner_name", "owner_phone", "vehicle_plate", "vehicle_type"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		bankAcct := &models.BankAccount{
			Bank:        getString(params, "owner_bank"),
			AccountNo:   getString(params, "owner_bank_account"),
			AccountName: getString(params, "owner_bank_account_name"),
		}
		req := service.RegisterPartnerRequest{
			Owner: models.PartnerOwner{
				Name:        getString(params, "owner_name"),
				Company:     getString(params, "owner_company"),
				Phone:       getString(params, "owner_phone"),
				TaxID:       getString(params, "owner_tax_id"),
				BankAccount: bankAcct,
			},
			Vehicle: models.PartnerVehicleInfo{
				Plate:       getString(params, "vehicle_plate"),
				Brand:       getString(params, "vehicle_brand"),
				Type:        getString(params, "vehicle_type"),
				Year:        getInt(params, "vehicle_year", 0),
				MaxWeightKg: getInt(params, "max_weight_kg", 0),
			},
			Driver: models.PartnerDriverInfo{
				Name:  getString(params, "driver_name"),
				Phone: getString(params, "driver_phone"),
			},
			Pricing: models.PartnerPricing{
				Model:    getString(params, "pricing_model"),
				BaseRate: getFloat(params, "base_rate", 0),
			},
			CoverageZones: getStringSlice(params, "coverage_zones"),
		}
		if req.Owner.Name == "" || req.Vehicle.Plate == "" {
			return nil, fmt.Errorf("กรุณาระบุ owner_name และ vehicle_plate")
		}
		partner, err := partnerSvc.Register(ctx, shopID, "mcp_agent", req)
		if err != nil {
			return nil, fmt.Errorf("ลงทะเบียนรถร่วมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"partner": partner,
			"message": fmt.Sprintf("ลงทะเบียนรถร่วม %s สำเร็จ", req.Vehicle.Plate),
		}, nil
	})

	// ── 2. list_partner_vehicles ──────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "list_partner_vehicles",
		Description: "ดูรายการรถร่วมทั้งหมด กรองด้วย status",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"status": map[string]interface{}{
					"type":        "string",
					"description": "สถานะ: active, suspended, inactive",
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
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		status := getString(params, "status")
		page := getInt(params, "page", 1)
		limit := getInt(params, "limit", 20)

		rows, total, err := partnerSvc.List(ctx, shopID, status, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายการรถร่วมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"partners": rows,
			"total":    total,
			"page":     page,
			"limit":    limit,
		}, nil
	})

	// ── 3. find_available_partners ────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "find_available_partners",
		Description: "ค้นหารถร่วมที่ว่างตาม zone, ประเภทรถ และวันที่",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_type": map[string]interface{}{
					"type":        "string",
					"description": "ประเภทรถที่ต้องการ เช่น 6ล้อ, 10ล้อ",
				},
				"zone": map[string]interface{}{
					"type":        "string",
					"description": "พื้นที่ปลายทาง เช่น เชียงใหม่, ลำพูน",
				},
				"date": map[string]interface{}{
					"type":        "string",
					"description": "วันที่ต้องการรถ (YYYY-MM-DD)",
				},
				"max_weight_kg": map[string]interface{}{
					"type":        "integer",
					"description": "น้ำหนักสินค้า (กก.) เพื่อกรองตามน้ำหนักบรรทุก",
				},
			},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.FindAvailablePartnersRequest{
			VehicleType: getString(params, "vehicle_type"),
			Zone:        getString(params, "zone"),
			MaxWeightKg: getInt(params, "max_weight_kg", 0),
		}
		rows, err := partnerSvc.FindAvailable(ctx, shopID, req)
		if err != nil {
			return nil, fmt.Errorf("ค้นหารถร่วมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"available_partners": rows,
			"count":              len(rows),
			"zone":               req.Zone,
			"vehicle_type":       req.VehicleType,
		}, nil
	})

	// ── 4. create_partner_booking ─────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "create_partner_booking",
		Description: "จองรถร่วมและส่งงานให้รถร่วม",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"partner_id": map[string]interface{}{
					"type":        "string",
					"description": "Partner ID ที่ต้องการจอง",
				},
				"trip_id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID ที่ต้องการให้รถร่วมรับงาน",
				},
				"zone": map[string]interface{}{
					"type":        "string",
					"description": "พื้นที่ให้บริการ",
				},
				"notes": map[string]interface{}{
					"type":        "string",
					"description": "หมายเหตุเพิ่มเติม",
				},
			},
			"required": []string{"partner_id"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.BookPartnerRequest{
			PartnerID: getString(params, "partner_id"),
			TripID:    getString(params, "trip_id"),
			Zone:      getString(params, "zone"),
			Notes:     getString(params, "notes"),
		}
		if req.PartnerID == "" {
			return nil, fmt.Errorf("กรุณาระบุ partner_id")
		}
		if err := partnerSvc.Book(ctx, shopID, "mcp_agent", req); err != nil {
			return nil, fmt.Errorf("จองรถร่วมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success":    true,
			"partner_id": req.PartnerID,
			"trip_id":    req.TripID,
			"message":    "จองรถร่วมสำเร็จ",
		}, nil
	})

	// ── 5. get_partner_settlement ─────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_partner_settlement",
		Description: "ดูรายการจ่ายเงินรถร่วม (ค่าจ้าง + หัก ณ ที่จ่าย)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"page": map[string]interface{}{
					"type":        "integer",
					"description": "หน้าที่ต้องการ",
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

		rows, total, err := partnerSvc.GetSettlements(ctx, shopID, page, limit)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายการจ่ายเงินรถร่วมล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"settlements": rows,
			"total":       total,
			"page":        page,
			"limit":       limit,
		}, nil
	})

	// ── 6. calculate_partner_payment ──────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "calculate_partner_payment",
		Description: "คำนวณค่าจ้างรถร่วม พร้อมหัก ณ ที่จ่าย (ภ.ง.ด.3) และยอดสุทธิ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"partner_id": map[string]interface{}{
					"type":        "string",
					"description": "Partner ID",
				},
				"trip_ids": map[string]interface{}{
					"type":        "array",
					"items":       map[string]interface{}{"type": "string"},
					"description": "รายการ Trip ID ที่ต้องการคำนวณ",
				},
			},
			"required": []string{"partner_id", "trip_ids"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		partnerID := getString(params, "partner_id")
		tripIDs := getStringSlice(params, "trip_ids")
		if partnerID == "" || len(tripIDs) == 0 {
			return nil, fmt.Errorf("กรุณาระบุ partner_id และ trip_ids")
		}
		result, err := partnerSvc.CalculatePayment(ctx, shopID, partnerID, tripIDs)
		if err != nil {
			return nil, fmt.Errorf("คำนวณค่าจ้างรถร่วมล้มเหลว: %w", err)
		}
		return result, nil
	})
}
