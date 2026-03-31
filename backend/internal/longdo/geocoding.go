package longdo

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

// GeocodeResult is a single result from the Longdo geocoding API.
type GeocodeResult struct {
	Lat     float64 `json:"lat"`
	Lng     float64 `json:"lon"`
	Name    string  `json:"name"`
	Address string  `json:"address"`
}

// longdoAddressResponse maps the raw Longdo API response envelope.
type longdoAddressResponse struct {
	Data []struct {
		Lat     float64 `json:"lat"`
		Lon     float64 `json:"lon"`
		Name    string  `json:"name"`
		Address string  `json:"address"`
	} `json:"data"`
}

// Geocode converts a Thai address string into a list of geographic coordinates.
// Endpoint: GET /msp/services/address?keyword={address}&key={apiKey}
func (c *Client) Geocode(ctx context.Context, address string) ([]GeocodeResult, error) {
	endpoint := fmt.Sprintf("%s/msp/services/address", c.baseURL)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("longdo geocode: build request: %w", err)
	}

	q := url.Values{}
	q.Set("keyword", address)
	q.Set("key", c.apiKey)
	req.URL.RawQuery = q.Encode()

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("longdo geocode: http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("longdo geocode: unexpected status %d", resp.StatusCode)
	}

	var raw longdoAddressResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, fmt.Errorf("longdo geocode: decode: %w", err)
	}

	results := make([]GeocodeResult, 0, len(raw.Data))
	for _, d := range raw.Data {
		results = append(results, GeocodeResult{
			Lat:     d.Lat,
			Lng:     d.Lon,
			Name:    d.Name,
			Address: d.Address,
		})
	}
	return results, nil
}

// ReverseGeocode converts a lat/lng pair into a human-readable address.
// Endpoint: GET /msp/services/address?lat={lat}&lon={lng}&key={apiKey}
func (c *Client) ReverseGeocode(ctx context.Context, lat, lng float64) (*GeocodeResult, error) {
	endpoint := fmt.Sprintf("%s/msp/services/address", c.baseURL)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("longdo reverse geocode: build request: %w", err)
	}

	q := url.Values{}
	q.Set("lat", fmt.Sprintf("%f", lat))
	q.Set("lon", fmt.Sprintf("%f", lng))
	q.Set("key", c.apiKey)
	req.URL.RawQuery = q.Encode()

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("longdo reverse geocode: http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("longdo reverse geocode: unexpected status %d", resp.StatusCode)
	}

	var raw longdoAddressResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, fmt.Errorf("longdo reverse geocode: decode: %w", err)
	}

	if len(raw.Data) == 0 {
		return nil, fmt.Errorf("longdo reverse geocode: no results for (%.6f, %.6f)", lat, lng)
	}

	d := raw.Data[0]
	return &GeocodeResult{
		Lat:     d.Lat,
		Lng:     d.Lon,
		Name:    d.Name,
		Address: d.Address,
	}, nil
}
