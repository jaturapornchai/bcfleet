package line

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

const (
	lineAPIRichMenu = "https://api.line.me/v2/bot/richmenu"
)

// RichMenuSize ขนาด Rich Menu
type RichMenuSize struct {
	Width  int `json:"width"`
	Height int `json:"height"`
}

// RichMenuArea พื้นที่ clickable
type RichMenuArea struct {
	Bounds RichMenuBounds `json:"bounds"`
	Action RichMenuAction `json:"action"`
}

// RichMenuBounds พิกัดพื้นที่
type RichMenuBounds struct {
	X      int `json:"x"`
	Y      int `json:"y"`
	Width  int `json:"width"`
	Height int `json:"height"`
}

// RichMenuAction action เมื่อกด
type RichMenuAction struct {
	Type    string `json:"type"`
	Data    string `json:"data,omitempty"`
	Text    string `json:"text,omitempty"`
	Label   string `json:"label"`
	URI     string `json:"uri,omitempty"`
}

// RichMenuRequest โครงสร้างสำหรับสร้าง Rich Menu
type RichMenuRequest struct {
	Size        RichMenuSize   `json:"size"`
	Selected    bool           `json:"selected"`
	Name        string         `json:"name"`
	ChatBarText string         `json:"chatBarText"`
	Areas       []RichMenuArea `json:"areas"`
}

// RichMenuResponse response จาก LINE API
type RichMenuResponse struct {
	RichMenuID string `json:"richMenuId"`
}

// richMenuClient client สำหรับจัดการ Rich Menu
type richMenuClient struct {
	channelToken string
	httpClient   *http.Client
}

// CreateDefaultRichMenu สร้าง Rich Menu มาตรฐาน 3x2 สำหรับ BC Fleet
//
// Layout (3x2 grid, 2500x1686 px):
//
//	[ ดูรถว่าง    ] [ จองเที่ยวรถ ] [ ติดตามงาน ]
//	[ แจ้งซ่อม   ] [ ดูต้นทุน   ] [ พูดกับ AI  ]
func CreateDefaultRichMenu(client *MessagingClient) error {
	rc := &richMenuClient{
		channelToken: client.channelToken,
		httpClient:   &http.Client{Timeout: 15 * time.Second},
	}

	// ขนาด 2500x1686 (มาตรฐาน LINE Rich Menu)
	cellW := 833  // 2500 / 3
	cellH := 843  // 1686 / 2

	menu := RichMenuRequest{
		Size:        RichMenuSize{Width: 2500, Height: 1686},
		Selected:    true,
		Name:        "BC Fleet Main Menu",
		ChatBarText: "เมนูหลัก",
		Areas: []RichMenuArea{
			// Row 1
			{
				Bounds: RichMenuBounds{X: 0, Y: 0, Width: cellW, Height: cellH},
				Action: RichMenuAction{
					Type:  "postback",
					Label: "ดูรถว่าง",
					Data:  "action=check_vehicles",
				},
			},
			{
				Bounds: RichMenuBounds{X: cellW, Y: 0, Width: cellW, Height: cellH},
				Action: RichMenuAction{
					Type:  "postback",
					Label: "จองเที่ยวรถ",
					Data:  "action=book_trip",
				},
			},
			{
				Bounds: RichMenuBounds{X: cellW * 2, Y: 0, Width: cellW, Height: cellH},
				Action: RichMenuAction{
					Type:  "postback",
					Label: "ติดตามงาน",
					Data:  "action=track_trip",
				},
			},
			// Row 2
			{
				Bounds: RichMenuBounds{X: 0, Y: cellH, Width: cellW, Height: cellH},
				Action: RichMenuAction{
					Type:  "postback",
					Label: "แจ้งซ่อม",
					Data:  "action=report_repair",
				},
			},
			{
				Bounds: RichMenuBounds{X: cellW, Y: cellH, Width: cellW, Height: cellH},
				Action: RichMenuAction{
					Type:  "postback",
					Label: "ดูต้นทุน",
					Data:  "action=view_costs",
				},
			},
			{
				Bounds: RichMenuBounds{X: cellW * 2, Y: cellH, Width: cellW, Height: cellH},
				Action: RichMenuAction{
					Type:  "postback",
					Label: "พูดกับ AI",
					Data:  "action=chat_ai",
				},
			},
		},
	}

	// 1. สร้าง Rich Menu
	menuID, err := rc.createRichMenu(menu)
	if err != nil {
		return fmt.Errorf("create rich menu: %w", err)
	}
	log.Printf("[LINE] rich menu created: %s", menuID)

	// 2. Set as default Rich Menu สำหรับทุก user
	if err := rc.setDefaultRichMenu(menuID); err != nil {
		return fmt.Errorf("set default rich menu: %w", err)
	}
	log.Printf("[LINE] default rich menu set: %s", menuID)

	return nil
}

// createRichMenu สร้าง Rich Menu ผ่าน LINE API
func (rc *richMenuClient) createRichMenu(menu RichMenuRequest) (string, error) {
	data, err := json.Marshal(menu)
	if err != nil {
		return "", fmt.Errorf("marshal: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, lineAPIRichMenu, bytes.NewBuffer(data))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+rc.channelToken)

	resp, err := rc.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("LINE API status %d", resp.StatusCode)
	}

	var result RichMenuResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("decode: %w", err)
	}

	return result.RichMenuID, nil
}

// setDefaultRichMenu กำหนด Rich Menu default สำหรับทุก user
func (rc *richMenuClient) setDefaultRichMenu(menuID string) error {
	url := fmt.Sprintf("https://api.line.me/v2/bot/user/all/richmenu/%s", menuID)

	req, err := http.NewRequest(http.MethodPost, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+rc.channelToken)

	resp, err := rc.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("LINE API status %d", resp.StatusCode)
	}

	return nil
}

// DeleteRichMenu ลบ Rich Menu
func DeleteRichMenu(client *MessagingClient, menuID string) error {
	rc := &richMenuClient{
		channelToken: client.channelToken,
		httpClient:   &http.Client{Timeout: 10 * time.Second},
	}

	url := fmt.Sprintf("%s/%s", lineAPIRichMenu, menuID)
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+rc.channelToken)

	resp, err := rc.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("LINE API status %d", resp.StatusCode)
	}

	return nil
}
