package osrm

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

// Client เรียก OSRM Demo Server (router.project-osrm.org)
// production: เปลี่ยนเป็น self-hosted Valhalla/OSRM ได้
type Client struct {
	baseURL    string
	httpClient *http.Client
}

// NewClient สร้าง OSRM client
func NewClient(baseURL string) *Client {
	if baseURL == "" {
		baseURL = "https://router.project-osrm.org"
	}
	return &Client{
		baseURL: strings.TrimRight(baseURL, "/"),
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// RouteResult ผลลัพธ์เส้นทาง
type RouteResult struct {
	DistanceKm      float64         `json:"distance_km"`
	DurationMinutes float64         `json:"duration_minutes"`
	Geometry        string          `json:"geometry"`  // encoded polyline (Google format)
	Steps           []RouteStep     `json:"steps,omitempty"`
	Waypoints       []Waypoint      `json:"waypoints"`
}

// RouteStep ขั้นตอนนำทาง
type RouteStep struct {
	Instruction string  `json:"instruction"`
	DistanceKm  float64 `json:"distance_km"`
	Duration    float64 `json:"duration_seconds"`
	Name        string  `json:"name"`
	Maneuver    string  `json:"maneuver"`
}

// Waypoint จุดบนเส้นทาง
type Waypoint struct {
	Name string  `json:"name"`
	Lat  float64 `json:"lat"`
	Lng  float64 `json:"lng"`
}

// LatLng พิกัด
type LatLng struct {
	Lat float64
	Lng float64
}

// osrmResponse JSON response จาก OSRM API
type osrmResponse struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	Routes    []struct {
		Distance float64 `json:"distance"` // meters
		Duration float64 `json:"duration"` // seconds
		Geometry string  `json:"geometry"` // encoded polyline
		Legs     []struct {
			Steps []struct {
				Distance float64 `json:"distance"`
				Duration float64 `json:"duration"`
				Name     string  `json:"name"`
				Maneuver struct {
					Type     string `json:"type"`
					Modifier string `json:"modifier"`
				} `json:"maneuver"`
			} `json:"steps"`
		} `json:"legs"`
	} `json:"routes"`
	Waypoints []struct {
		Name     string    `json:"name"`
		Location []float64 `json:"location"` // [lng, lat]
	} `json:"waypoints"`
}

// Route คำนวณเส้นทาง from → to พร้อม waypoints (ถ้ามี)
func (c *Client) Route(ctx context.Context, from, to LatLng, waypoints []LatLng) (*RouteResult, error) {
	// สร้าง coordinates string: lng,lat;lng,lat;...
	coords := []string{
		fmt.Sprintf("%.6f,%.6f", from.Lng, from.Lat),
	}
	for _, wp := range waypoints {
		coords = append(coords, fmt.Sprintf("%.6f,%.6f", wp.Lng, wp.Lat))
	}
	coords = append(coords, fmt.Sprintf("%.6f,%.6f", to.Lng, to.Lat))

	url := fmt.Sprintf("%s/route/v1/driving/%s?overview=full&geometries=polyline&steps=true",
		c.baseURL, strings.Join(coords, ";"))

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, fmt.Errorf("osrm: build request: %w", err)
	}
	req.Header.Set("User-Agent", "SMLFleet/1.0")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("osrm: http: %w", err)
	}
	defer resp.Body.Close()

	var raw osrmResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, fmt.Errorf("osrm: decode: %w", err)
	}

	if raw.Code != "Ok" {
		return nil, fmt.Errorf("osrm: %s — %s", raw.Code, raw.Message)
	}

	if len(raw.Routes) == 0 {
		return nil, fmt.Errorf("osrm: no routes found")
	}

	route := raw.Routes[0]

	// Build steps
	var steps []RouteStep
	for _, leg := range route.Legs {
		for _, s := range leg.Steps {
			maneuver := s.Maneuver.Type
			if s.Maneuver.Modifier != "" {
				maneuver += " " + s.Maneuver.Modifier
			}
			steps = append(steps, RouteStep{
				Instruction: fmt.Sprintf("%s on %s", maneuver, s.Name),
				DistanceKm:  s.Distance / 1000.0,
				Duration:    s.Duration,
				Name:        s.Name,
				Maneuver:    maneuver,
			})
		}
	}

	// Build waypoints
	var wps []Waypoint
	for _, wp := range raw.Waypoints {
		lat, lng := 0.0, 0.0
		if len(wp.Location) >= 2 {
			lng, lat = wp.Location[0], wp.Location[1]
		}
		wps = append(wps, Waypoint{Name: wp.Name, Lat: lat, Lng: lng})
	}

	return &RouteResult{
		DistanceKm:      route.Distance / 1000.0,
		DurationMinutes: route.Duration / 60.0,
		Geometry:        route.Geometry,
		Steps:           steps,
		Waypoints:       wps,
	}, nil
}
