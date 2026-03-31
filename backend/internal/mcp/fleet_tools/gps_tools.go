package fleet_tools

import (
	"context"
	"fmt"

	"sml-fleet/internal/service"
)

// RegisterGPSTools ลงทะเบียน GPS tools (3 tools)
func RegisterGPSTools(registry *ToolRegistry, gpsSvc *service.GPSService) {

	// ── 1. get_all_vehicle_locations ─────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_all_vehicle_locations",
		Description: "ดึงตำแหน่ง GPS ปัจจุบันของรถทุกคันในกองรถ",
		InputSchema: map[string]interface{}{
			"type":       "object",
			"properties": map[string]interface{}{},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		locations, err := gpsSvc.GetVehicleLocations(ctx, shopID)
		if err != nil {
			return nil, fmt.Errorf("ดึงตำแหน่งรถล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"locations": locations,
			"count":     len(locations),
		}, nil
	})

	// ── 2. report_gps_location ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "report_gps_location",
		Description: "บันทึกตำแหน่ง GPS ของรถ (ใช้โดย driver app หรือ IoT device)",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"vehicle_id": map[string]interface{}{
					"type":        "string",
					"description": "Vehicle ID",
				},
				"driver_id": map[string]interface{}{
					"type":        "string",
					"description": "Driver ID",
				},
				"trip_id": map[string]interface{}{
					"type":        "string",
					"description": "Trip ID (ถ้ามีเที่ยววิ่ง)",
				},
				"lat": map[string]interface{}{
					"type":        "number",
					"description": "Latitude",
				},
				"lng": map[string]interface{}{
					"type":        "number",
					"description": "Longitude",
				},
				"speed_kmh": map[string]interface{}{
					"type":        "number",
					"description": "ความเร็ว (กม./ชม.)",
				},
			},
			"required": []string{"vehicle_id", "lat", "lng"},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		req := service.RecordLocationRequest{
			VehicleID: getString(params, "vehicle_id"),
			DriverID:  getString(params, "driver_id"),
			TripID:    getString(params, "trip_id"),
			Lat:       getFloat(params, "lat", 0),
			Lng:       getFloat(params, "lng", 0),
			SpeedKmh:  getFloat(params, "speed_kmh", 0),
		}
		if req.VehicleID == "" {
			return nil, fmt.Errorf("กรุณาระบุ vehicle_id")
		}
		if err := gpsSvc.RecordLocation(ctx, shopID, req); err != nil {
			return nil, fmt.Errorf("บันทึก GPS ล้มเหลว: %w", err)
		}
		return map[string]interface{}{
			"success": true,
			"message": "บันทึกตำแหน่งสำเร็จ",
		}, nil
	})

	// ── 3. get_moving_vehicles ───────────────────────────────────────────────
	registry.Register(ToolDefinition{
		Name:        "get_moving_vehicles",
		Description: "ดึงเฉพาะรถที่กำลังเคลื่อนที่ (เปลี่ยนตำแหน่ง) ใน interval ที่กำหนด ใช้สำหรับ monitoring อัตโนมัติ",
		InputSchema: map[string]interface{}{
			"type": "object",
			"properties": map[string]interface{}{
				"min_distance_m": map[string]interface{}{
					"type":        "number",
					"description": "ระยะทางขั้นต่ำที่ถือว่าเคลื่อนที่ (เมตร) ค่าเริ่มต้น: 50",
				},
				"max_age_minutes": map[string]interface{}{
					"type":        "integer",
					"description": "ดูข้อมูลย้อนหลังกี่นาที ค่าเริ่มต้น: 2",
				},
			},
		},
	}, func(ctx context.Context, shopID string, params map[string]interface{}) (interface{}, error) {
		minDist := getFloat(params, "min_distance_m", 50)
		maxAge := getInt(params, "max_age_minutes", 2)

		vehicles, err := gpsSvc.GetMovingVehicles(ctx, shopID, minDist, maxAge)
		if err != nil {
			return nil, fmt.Errorf("ดึงรายการรถเคลื่อนที่ล้มเหลว: %w", err)
		}

		if len(vehicles) == 0 {
			return map[string]interface{}{
				"moving_vehicles": []interface{}{},
				"count":          0,
				"message":        "ไม่พบรถที่กำลังเคลื่อนที่ในขณะนี้",
			}, nil
		}

		return map[string]interface{}{
			"moving_vehicles": vehicles,
			"count":          len(vehicles),
			"min_distance_m": minDist,
		}, nil
	})
}
