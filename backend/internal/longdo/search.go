package longdo

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

// SearchResult is a single place returned by the Longdo search API.
type SearchResult struct {
	Name    string  `json:"name"`
	Address string  `json:"address"`
	Lat     float64 `json:"lat"`
	Lng     float64 `json:"lon"`
	Type    string  `json:"type"`
}

// longdoSearchResponse maps the raw Longdo search API envelope.
type longdoSearchResponse struct {
	Data []struct {
		Name    string  `json:"name"`
		Address string  `json:"address"`
		Lat     float64 `json:"lat"`
		Lon     float64 `json:"lon"`
		Type    string  `json:"type"`
	} `json:"data"`
}

// SearchPlace searches for places near a coordinate by keyword.
//
// Endpoint: GET /msp/services/search?keyword={keyword}&lat={lat}&lon={lng}&span={radius}&key={apiKey}
// radius is in metres.
func (c *Client) SearchPlace(ctx context.Context, keyword string, lat, lng float64, radius int) ([]SearchResult, error) {
	endpoint := fmt.Sprintf("%s/msp/services/search", c.baseURL)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("longdo search: build request: %w", err)
	}

	q := url.Values{}
	q.Set("keyword", keyword)
	q.Set("lat", fmt.Sprintf("%f", lat))
	q.Set("lon", fmt.Sprintf("%f", lng))
	q.Set("span", fmt.Sprintf("%d", radius))
	q.Set("key", c.apiKey)
	req.URL.RawQuery = q.Encode()

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("longdo search: http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("longdo search: unexpected status %d", resp.StatusCode)
	}

	var raw longdoSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, fmt.Errorf("longdo search: decode: %w", err)
	}

	results := make([]SearchResult, 0, len(raw.Data))
	for _, d := range raw.Data {
		results = append(results, SearchResult{
			Name:    d.Name,
			Address: d.Address,
			Lat:     d.Lat,
			Lng:     d.Lon,
			Type:    d.Type,
		})
	}
	return results, nil
}
