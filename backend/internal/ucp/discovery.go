package ucp

import (
	"net/http"
	"time"

	"sml-fleet/internal/service"

	"github.com/gin-gonic/gin"
)

// DiscoveryHandler จัดการ service catalog และ availability
type DiscoveryHandler struct {
	vehicleSvc *service.VehicleService
	partnerSvc *service.PartnerService
}

// NewDiscoveryHandler สร้าง DiscoveryHandler
func NewDiscoveryHandler(vehicleSvc *service.VehicleService, partnerSvc *service.PartnerService) *DiscoveryHandler {
	return &DiscoveryHandler{
		vehicleSvc: vehicleSvc,
		partnerSvc: partnerSvc,
	}
}

// ---- Request/Response Types ----

// CatalogRequest คำขอดู service catalog
type CatalogRequest struct {
	ShopID string `json:"shop_id" binding:"required"`
	Zone   string `json:"zone"`
}

// CatalogItem รายการบริการ
type CatalogItem struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Type        string            `json:"type"`
	MaxWeightKg int               `json:"max_weight_kg"`
	Description string            `json:"description"`
	Pricing     CatalogPricing    `json:"pricing"`
	Zones       []string          `json:"zones"`
	Available   bool              `json:"available"`
}

// CatalogPricing โครงสร้างราคา
type CatalogPricing struct {
	Model       string             `json:"model"` // "per_trip", "per_km", "per_day"
	BaseRate    float64            `json:"base_rate"`
	PerKmRate   float64            `json:"per_km_rate,omitempty"`
	ZonePricing map[string]float64 `json:"zone_pricing,omitempty"`
	Currency    string             `json:"currency"`
}

// AvailabilityRequest คำขอตรวจสอบรถว่าง
type AvailabilityRequest struct {
	ShopID      string    `json:"shop_id" binding:"required"`
	VehicleType string    `json:"vehicle_type"`
	Zone        string    `json:"zone"`
	Date        time.Time `json:"date" binding:"required"`
	MaxWeightKg int       `json:"max_weight_kg"`
}

// AvailableVehicle รถที่ว่าง
type AvailableVehicle struct {
	ID          string  `json:"id"`
	Plate       string  `json:"plate"`
	Type        string  `json:"type"`
	Brand       string  `json:"brand"`
	MaxWeightKg int     `json:"max_weight_kg"`
	DriverName  string  `json:"driver_name"`
	IsPartner   bool    `json:"is_partner"`
	EstPrice    float64 `json:"est_price"`
}

// CoverageRequest คำขอดูพื้นที่ให้บริการ
type CoverageRequest struct {
	ShopID string `json:"shop_id" binding:"required"`
}

// ---- Handlers ----

// GetCatalog ดูประเภทรถและราคา
func (h *DiscoveryHandler) GetCatalog(c *gin.Context) {
	var req CatalogRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// ดึงข้อมูลรถจาก VehicleService
	vehicles, _, err := h.vehicleSvc.List(c.Request.Context(), req.ShopID, "active", "", 1, 200)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลรถได้"})
		return
	}

	// จัดกลุ่มตาม type
	catalogMap := make(map[string]*CatalogItem)
	for _, v := range vehicles {
		if _, exists := catalogMap[v.Type]; !exists {
			catalogMap[v.Type] = &CatalogItem{
				ID:        "vehicle_type_" + v.Type,
				Name:      "รถ" + v.Type,
				Type:      v.Type,
				Available: true,
				Pricing: CatalogPricing{
					Model:    "per_trip",
					BaseRate: getBaseRateByType(v.Type),
					Currency: "THB",
				},
				Zones:       []string{"เชียงใหม่", "ลำพูน", "ลำปาง", "เชียงราย"},
				Description: buildVehicleDescription(v.Type),
			}
		}
	}

	// แปลงเป็น slice
	catalog := make([]CatalogItem, 0, len(catalogMap))
	for _, item := range catalogMap {
		catalog = append(catalog, *item)
	}

	c.JSON(http.StatusOK, gin.H{
		"shop_id": req.ShopID,
		"catalog": catalog,
		"total":   len(catalog),
	})
}

// CheckAvailability ตรวจสอบรถว่างตามเงื่อนไข
func (h *DiscoveryHandler) CheckAvailability(c *gin.Context) {
	var req AvailabilityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// List vehicles: (ctx, shopID, status, vehicleType, page, limit)
	vehicles, _, err := h.vehicleSvc.List(c.Request.Context(), req.ShopID, "active", req.VehicleType, 1, 200)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถตรวจสอบรถว่างได้"})
		return
	}

	// ตรวจสอบรถว่างสำหรับวันที่ระบุ — VehicleRow fields: ID, ShopID, Plate, Brand*, Model*, Type, Status, CurrentDriverID*, MileageKm*, HealthStatus
	available := make([]AvailableVehicle, 0)
	for _, v := range vehicles {
		av := AvailableVehicle{
			ID:       v.ID,
			Plate:    v.Plate,
			Type:     v.Type,
			EstPrice: getBaseRateByType(v.Type),
		}
		if v.Brand != nil {
			av.Brand = *v.Brand
		}
		if v.CurrentDriverID != nil {
			av.DriverName = *v.CurrentDriverID // จะ JOIN กับ driver ใน production
		}
		available = append(available, av)
	}

	// ดึงรถร่วมที่ว่างด้วย (ถ้ามี)
	if req.Zone != "" {
		partnerReq := service.FindAvailablePartnersRequest{
			VehicleType: req.VehicleType,
			Zone:        req.Zone,
			Date:        req.Date,
			MaxWeightKg: req.MaxWeightKg,
		}
		// FindAvailable: (ctx, shopID, req) → ([]PartnerRow, error)
		partners, err := h.partnerSvc.FindAvailable(c.Request.Context(), req.ShopID, partnerReq)
		if err == nil {
			for _, p := range partners {
				av := AvailableVehicle{
					ID:        p.ID,
					IsPartner: true,
					EstPrice:  getBaseRateByType(safeStr(p.VehicleType)),
				}
				if p.Plate != nil {
					av.Plate = *p.Plate
				}
				if p.VehicleType != nil {
					av.Type = *p.VehicleType
				}
				if p.MaxWeightKg != nil {
					av.MaxWeightKg = *p.MaxWeightKg
				}
				if p.OwnerName != nil {
					av.DriverName = *p.OwnerName
				}
				if p.BaseRate != nil {
					av.EstPrice = *p.BaseRate
				}
				available = append(available, av)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"shop_id":      req.ShopID,
		"date":         req.Date.Format("2006-01-02"),
		"vehicle_type": req.VehicleType,
		"zone":         req.Zone,
		"available":    available,
		"total":        len(available),
	})
}

// GetCoverage ดูพื้นที่ให้บริการ
func (h *DiscoveryHandler) GetCoverage(c *gin.Context) {
	var req CoverageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// พื้นที่บริการหลักของ SML Fleet (Northern Thailand)
	coverage := []map[string]interface{}{
		{
			"zone":        "เชียงใหม่",
			"description": "ครอบคลุมทั้งจังหวัดเชียงใหม่",
			"base_surcharge": 0,
		},
		{
			"zone":           "ลำพูน",
			"description":    "เมืองลำพูน + นิคมอุตสาหกรรมภาคเหนือ",
			"base_surcharge": 500,
		},
		{
			"zone":           "ลำปาง",
			"description":    "จังหวัดลำปาง",
			"base_surcharge": 1500,
		},
		{
			"zone":           "เชียงราย",
			"description":    "จังหวัดเชียงราย",
			"base_surcharge": 2000,
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"shop_id":        req.ShopID,
		"coverage_zones": coverage,
		"currency":       "THB",
		"note":           "ค่าบริการอาจเปลี่ยนแปลงตามระยะทางและน้ำหนักสินค้า",
	})
}

// ---- Helpers ----

func safeStr(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func getBaseRateByType(vehicleType string) float64 {
	rates := map[string]float64{
		"กระบะ":   800,
		"4ล้อ":    1500,
		"6ล้อ":    2500,
		"10ล้อ":   4000,
		"หัวลาก":  6000,
	}
	if rate, ok := rates[vehicleType]; ok {
		return rate
	}
	return 2000
}

func buildVehicleDescription(vehicleType string) string {
	desc := map[string]string{
		"กระบะ":   "รับน้ำหนัก 500-750 กก. เหมาะสำหรับสินค้าเล็กน้อย",
		"4ล้อ":    "รับน้ำหนัก 1-2 ตัน เหมาะสำหรับสินค้าในเมือง",
		"6ล้อ":    "รับน้ำหนัก 4-6 ตัน เหมาะสำหรับสินค้าปริมาณกลาง",
		"10ล้อ":   "รับน้ำหนัก 10-15 ตัน เหมาะสำหรับสินค้าหนัก",
		"หัวลาก":  "รับน้ำหนักได้มากกว่า 20 ตัน สำหรับขนส่งขนาดใหญ่",
	}
	if d, ok := desc[vehicleType]; ok {
		return d
	}
	return "บริการขนส่งทั่วไป"
}
