package longdo

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
)

// RouteResult holds the result of a route calculation.
type RouteResult struct {
	DistanceKm      float64     `json:"distance_km"`
	DurationMinutes int         `json:"duration_minutes"`
	Polyline        string      `json:"polyline"`
	Steps           []RouteStep `json:"steps"`
}

// RouteStep is a single navigation instruction along the route.
type RouteStep struct {
	Instruction string  `json:"instruction"`
	DistanceKm  float64 `json:"distance_km"`
	Duration    int     `json:"duration"`
}

// longdoRouteResponse maps the raw Longdo route API envelope.
type longdoRouteResponse struct {
	Guide []struct {
		Distance int    `json:"distance"` // metres
		Duration int    `json:"duration"` // seconds
		Turns    string `json:"turns"`
	} `json:"guide"`
	Interval []struct {
		Lat float64 `json:"lat"`
		Lon float64 `json:"lon"`
	} `json:"interval"`
	Distance int `json:"distance"` // total metres
	Duration int `json:"duration"` // total seconds
}

// CalculateRoute calculates a driving route between two points with optional
// intermediate waypoints.
//
// Endpoint: GET /map/services/route?flat={flat}&flon={flon}&tlat={tlat}&tlon={tlon}&mode=d&type=25&key={apiKey}
// Extra waypoints are appended as via={lat},{lon} pairs.
func (c *Client) CalculateRoute(ctx context.Context, from, to LatLng, waypoints []LatLng) (*RouteResult, error) {
	endpoint := fmt.Sprintf("%s/map/services/route", c.baseURL)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("longdo route: build request: %w", err)
	}

	q := url.Values{}
	q.Set("flat", fmt.Sprintf("%f", from.Lat))
	q.Set("flon", fmt.Sprintf("%f", from.Lng))
	q.Set("tlat", fmt.Sprintf("%f", to.Lat))
	q.Set("tlon", fmt.Sprintf("%f", to.Lng))
	q.Set("mode", "d")   // driving
	q.Set("type", "25")  // standard route type
	q.Set("key", c.apiKey)

	// Append waypoints as repeated via parameters
	for _, wp := range waypoints {
		q.Add("via", fmt.Sprintf("%f,%f", wp.Lat, wp.Lng))
	}
	req.URL.RawQuery = q.Encode()

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("longdo route: http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("longdo route: unexpected status %d", resp.StatusCode)
	}

	var raw longdoRouteResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, fmt.Errorf("longdo route: decode: %w", err)
	}

	// Build polyline from interval points (encoded as "lat,lon lat,lon …")
	polylineParts := make([]string, 0, len(raw.Interval))
	for _, pt := range raw.Interval {
		polylineParts = append(polylineParts, fmt.Sprintf("%.6f,%.6f", pt.Lat, pt.Lon))
	}

	// Build steps from guide segments
	steps := make([]RouteStep, 0, len(raw.Guide))
	for _, g := range raw.Guide {
		steps = append(steps, RouteStep{
			Instruction: g.Turns,
			DistanceKm:  metresToKm(g.Distance),
			Duration:    g.Duration / 60, // convert seconds → minutes
		})
	}

	return &RouteResult{
		DistanceKm:      metresToKm(raw.Distance),
		DurationMinutes: raw.Duration / 60,
		Polyline:        strings.Join(polylineParts, " "),
		Steps:           steps,
	}, nil
}

func metresToKm(metres int) float64 {
	return float64(metres) / 1000.0
}
