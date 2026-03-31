package service

import (
	"context"
	"fmt"
	"sort"

	pgquery "sml-fleet/internal/repository/postgres"
)

// MatchRequest คำขอค้นหารถร่วมที่เหมาะสม
type MatchRequest struct {
	Zone        string  `json:"zone"`         // zone ปลายทาง เช่น "ลำพูน"
	VehicleType string  `json:"vehicle_type"` // "6ล้อ", "10ล้อ"
	WeightKg    int     `json:"weight_kg"`    // น้ำหนักสินค้า กก.
	Date        string  `json:"date"`         // วันที่ต้องการ YYYY-MM-DD
}

// MatchResult ผลลัพธ์การจับคู่รถร่วม
type MatchResult struct {
	PartnerID   string   `json:"partner_id"`
	OwnerName   string   `json:"owner_name"`
	Plate       string   `json:"plate"`
	VehicleType string   `json:"vehicle_type"`
	BaseRate    float64  `json:"base_rate"`
	Rating      float64  `json:"rating"`
	Score       int      `json:"score"`    // 0-100
	Reasons     []string `json:"reasons"`  // เหตุผลที่เลือก
}

// MatchingService AI จับคู่รถร่วม
type MatchingService struct {
	partnerQuery *pgquery.PartnerQuery
}

// NewMatchingService สร้าง MatchingService ใหม่
func NewMatchingService(pq *pgquery.PartnerQuery) *MatchingService {
	return &MatchingService{partnerQuery: pq}
}

// FindBestMatch ค้นหารถร่วมที่เหมาะสมที่สุด
// Scoring: zone coverage (30pt) + vehicle type (25pt) + rating (20pt) + price (15pt) + availability (10pt)
func (s *MatchingService) FindBestMatch(ctx context.Context, shopID string, req MatchRequest) ([]MatchResult, error) {
	// ดึงรถร่วมที่ active ทั้งหมด
	partners, _, err := s.partnerQuery.List(ctx, shopID, "active", 1, 100)
	if err != nil {
		return nil, err
	}

	var results []MatchResult

	for _, p := range partners {
		score, reasons := s.scorePartner(p, req)
		if score == 0 {
			continue // ไม่เหมาะสมเลย
		}

		ownerName := ""
		if p.OwnerName != nil {
			ownerName = *p.OwnerName
		}
		plate := ""
		if p.Plate != nil {
			plate = *p.Plate
		}
		vType := ""
		if p.VehicleType != nil {
			vType = *p.VehicleType
		}
		baseRate := 0.0
		if p.BaseRate != nil {
			baseRate = *p.BaseRate
		}
		rating := 0.0
		if p.Rating != nil {
			rating = *p.Rating
		}

		results = append(results, MatchResult{
			PartnerID:   p.ID,
			OwnerName:   ownerName,
			Plate:       plate,
			VehicleType: vType,
			BaseRate:    baseRate,
			Rating:      rating,
			Score:       score,
			Reasons:     reasons,
		})
	}

	// เรียงตาม score สูงสุดก่อน
	sort.Slice(results, func(i, j int) bool {
		return results[i].Score > results[j].Score
	})

	// คืนแค่ top 5
	if len(results) > 5 {
		results = results[:5]
	}

	return results, nil
}

// scorePartner คำนวณคะแนนรถร่วม (0-100)
func (s *MatchingService) scorePartner(p pgquery.PartnerRow, req MatchRequest) (int, []string) {
	score := 0
	var reasons []string

	// ─── Zone Coverage (30 pt) ───────────────────────────────
	// ตรวจสอบจาก coverage_zones ที่เก็บใน PostgreSQL (ถ้า field มี)
	// สำหรับ MVP ใช้การ match vehicle type เป็นหลักก่อน
	// TODO: เพิ่ม coverage_zones column เมื่อ schema พร้อม
	zoneScore := 30 // ให้ full score ชั่วคราวถ้าไม่มีข้อมูล zone
	score += zoneScore
	if req.Zone != "" {
		reasons = append(reasons, "ครอบคลุม zone "+req.Zone)
	}

	// ─── Vehicle Type Match (25 pt) ──────────────────────────
	if p.VehicleType != nil && req.VehicleType != "" {
		if *p.VehicleType == req.VehicleType {
			score += 25
			reasons = append(reasons, "รถตรงประเภท "+req.VehicleType)
		} else {
			// ประเภทรถใกล้เคียง — ให้ครึ่งคะแนน
			if s.isCompatibleType(*p.VehicleType, req.VehicleType) {
				score += 12
				reasons = append(reasons, "รถใกล้เคียงประเภท "+req.VehicleType)
			} else {
				score -= 10 // ประเภทไม่ตรง ลดคะแนน
			}
		}
	} else {
		score += 15 // ไม่ระบุประเภท ให้กลางๆ
	}

	// ─── Weight Capacity Check ───────────────────────────────
	if p.MaxWeightKg != nil && req.WeightKg > 0 {
		if req.WeightKg > *p.MaxWeightKg {
			// รถรับน้ำหนักไม่ได้ — ตัดสิทธิ์
			return 0, nil
		}
	}

	// ─── Rating (20 pt) ──────────────────────────────────────
	if p.Rating != nil {
		rating := *p.Rating
		ratingScore := int(rating / 5.0 * 20)
		score += ratingScore
		if rating >= 4.5 {
			reasons = append(reasons, "คะแนนดีเยี่ยม ★"+formatRating(rating))
		} else if rating >= 4.0 {
			reasons = append(reasons, "คะแนนดี ★"+formatRating(rating))
		}
	} else {
		score += 10 // ไม่มี rating — ให้กลาง
	}

	// ─── Price Competitiveness (15 pt) ───────────────────────
	// TODO: เปรียบเทียบ base_rate กับ market rate เมื่อมีข้อมูลเพิ่มเติม
	if p.BaseRate != nil {
		priceScore := 15 // ให้ full score ชั่วคราว
		score += priceScore
		reasons = append(reasons, "ราคาเริ่มต้น "+formatPrice(*p.BaseRate)+" บาท")
	} else {
		score += 8
	}

	// ─── Availability (10 pt) ────────────────────────────────
	// TODO: ตรวจสอบ booking schedule เมื่อมี table พร้อม
	// สำหรับ MVP — ถ้า status = active ถือว่าว่าง
	score += 10
	reasons = append(reasons, "พร้อมรับงาน")

	// cap ไม่เกิน 100
	if score > 100 {
		score = 100
	}
	if score < 0 {
		score = 0
	}

	return score, reasons
}

// isCompatibleType ตรวจสอบว่ารถประเภทหนึ่งสามารถทดแทนอีกประเภทได้หรือไม่
func (s *MatchingService) isCompatibleType(available, required string) bool {
	// รถใหญ่กว่า สามารถทดแทนรถเล็กกว่าได้
	order := map[string]int{
		"กระบะ":  1,
		"4ล้อ":  2,
		"6ล้อ":  3,
		"10ล้อ": 4,
		"หัวลาก": 5,
	}
	avail, okA := order[available]
	req, okR := order[required]
	if !okA || !okR {
		return false
	}
	return avail >= req
}

// formatRating จัดรูปแบบ rating
func formatRating(r float64) string {
	return fmt.Sprintf("%.1f", r)
}

// formatPrice จัดรูปแบบราคา
func formatPrice(p float64) string {
	return fmt.Sprintf("%.0f", p)
}
