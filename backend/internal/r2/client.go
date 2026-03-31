package r2

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Config holds Cloudflare R2 credentials and bucket information.
type Config struct {
	AccountID string
	AccessKey string
	SecretKey string
	Bucket    string
	PublicURL string // e.g. https://files.smlfleet.com
}

// Client is the Cloudflare R2 storage client (S3-compatible).
type Client struct {
	config     Config
	httpClient *http.Client
}

// NewClient creates a new R2 client.
func NewClient(config Config) *Client {
	return &Client{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// Upload uploads arbitrary data to R2 and returns the public URL.
// folder: e.g. "pods", "documents", "drivers"
// filename: e.g. "receipt.jpg"
func (c *Client) Upload(ctx context.Context, folder, filename string, reader io.Reader, contentType string) (string, error) {
	key := fmt.Sprintf("%s/%s", strings.Trim(folder, "/"), filename)

	body, err := io.ReadAll(reader)
	if err != nil {
		return "", fmt.Errorf("r2 upload: read body: %w", err)
	}

	if err := c.putObject(ctx, key, body, contentType); err != nil {
		return "", err
	}

	publicURL := fmt.Sprintf("%s/%s", strings.TrimRight(c.config.PublicURL, "/"), key)
	return publicURL, nil
}

// UploadImage uploads an image to R2 under the given folder.
// A unique filename is generated automatically (UUID + original extension preserved via contentType).
func (c *Client) UploadImage(ctx context.Context, folder string, reader io.Reader) (string, error) {
	filename := uuid.New().String() + ".jpg"
	return c.Upload(ctx, folder, filename, reader, "image/jpeg")
}

// UploadDocument uploads a document (PDF, etc.) to R2 under the given folder.
func (c *Client) UploadDocument(ctx context.Context, folder string, reader io.Reader, filename string) (string, error) {
	ext := strings.ToLower(filepath.Ext(filename))
	contentType := mimeForExt(ext)
	safeFilename := uuid.New().String() + ext
	return c.Upload(ctx, folder, safeFilename, reader, contentType)
}

// Delete removes an object from R2 by its key (path relative to bucket root).
func (c *Client) Delete(ctx context.Context, key string) error {
	endpoint := c.objectURL(key)
	t := time.Now().UTC()

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, endpoint, nil)
	if err != nil {
		return fmt.Errorf("r2 delete: build request: %w", err)
	}

	c.signRequest(req, http.MethodDelete, key, nil, t)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("r2 delete: http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("r2 delete: unexpected status %d", resp.StatusCode)
	}
	return nil
}

// GeneratePresignedURL generates a pre-signed PUT URL for direct browser uploads.
func (c *Client) GeneratePresignedURL(ctx context.Context, key string, expiry time.Duration) (string, error) {
	t := time.Now().UTC()
	expirySeconds := int(expiry.Seconds())
	if expirySeconds <= 0 {
		expirySeconds = 3600
	}

	region := "auto"
	service := "s3"
	host := fmt.Sprintf("%s.r2.cloudflarestorage.com", c.config.AccountID)
	dateStamp := t.Format("20060102")
	amzDate := t.Format("20060102T150405Z")
	credentialScope := fmt.Sprintf("%s/%s/%s/aws4_request", dateStamp, region, service)
	credential := fmt.Sprintf("%s/%s", c.config.AccessKey, credentialScope)

	queryParams := fmt.Sprintf(
		"X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=%s&X-Amz-Date=%s&X-Amz-Expires=%d&X-Amz-SignedHeaders=host",
		urlEncode(credential), amzDate, expirySeconds,
	)

	canonicalRequest := strings.Join([]string{
		"PUT",
		"/" + key,
		queryParams,
		"host:" + host + "\n",
		"host",
		"UNSIGNED-PAYLOAD",
	}, "\n")

	stringToSign := strings.Join([]string{
		"AWS4-HMAC-SHA256",
		amzDate,
		credentialScope,
		hexSHA256([]byte(canonicalRequest)),
	}, "\n")

	signingKey := c.signingKey(dateStamp, region, service)
	signature := hex.EncodeToString(hmacSHA256(signingKey, []byte(stringToSign)))

	presignedURL := fmt.Sprintf(
		"https://%s/%s/%s?%s&X-Amz-Signature=%s",
		host, c.config.Bucket, key, queryParams, signature,
	)
	return presignedURL, nil
}

// --- internal helpers ---

func (c *Client) objectURL(key string) string {
	return fmt.Sprintf("https://%s.r2.cloudflarestorage.com/%s/%s",
		c.config.AccountID, c.config.Bucket, key)
}

func (c *Client) putObject(ctx context.Context, key string, body []byte, contentType string) error {
	endpoint := c.objectURL(key)
	t := time.Now().UTC()

	req, err := http.NewRequestWithContext(ctx, http.MethodPut, endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("r2 put: build request: %w", err)
	}
	req.Header.Set("Content-Type", contentType)

	c.signRequest(req, http.MethodPut, key, body, t)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("r2 put: http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		respBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("r2 put: unexpected status %d: %s", resp.StatusCode, string(respBody))
	}
	return nil
}

// signRequest adds AWS4-HMAC-SHA256 authorization headers to the request.
func (c *Client) signRequest(req *http.Request, method, key string, body []byte, t time.Time) {
	region := "auto"
	service := "s3"
	host := fmt.Sprintf("%s.r2.cloudflarestorage.com", c.config.AccountID)
	amzDate := t.Format("20060102T150405Z")
	dateStamp := t.Format("20060102")

	payloadHash := hexSHA256(body)

	req.Header.Set("x-amz-date", amzDate)
	req.Header.Set("x-amz-content-sha256", payloadHash)
	req.Header.Set("Host", host)

	signedHeaders := "content-type;host;x-amz-content-sha256;x-amz-date"
	if method == http.MethodDelete {
		signedHeaders = "host;x-amz-content-sha256;x-amz-date"
	}

	var canonicalHeaders string
	if method == http.MethodDelete {
		canonicalHeaders = fmt.Sprintf("host:%s\nx-amz-content-sha256:%s\nx-amz-date:%s\n",
			host, payloadHash, amzDate)
	} else {
		canonicalHeaders = fmt.Sprintf("content-type:%s\nhost:%s\nx-amz-content-sha256:%s\nx-amz-date:%s\n",
			req.Header.Get("Content-Type"), host, payloadHash, amzDate)
	}

	canonicalRequest := strings.Join([]string{
		method,
		"/" + key,
		"",
		canonicalHeaders,
		signedHeaders,
		payloadHash,
	}, "\n")

	credentialScope := fmt.Sprintf("%s/%s/%s/aws4_request", dateStamp, region, service)
	stringToSign := strings.Join([]string{
		"AWS4-HMAC-SHA256",
		amzDate,
		credentialScope,
		hexSHA256([]byte(canonicalRequest)),
	}, "\n")

	signingKey := c.signingKey(dateStamp, region, service)
	signature := hex.EncodeToString(hmacSHA256(signingKey, []byte(stringToSign)))

	authHeader := fmt.Sprintf(
		"AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s",
		c.config.AccessKey, credentialScope, signedHeaders, signature,
	)
	req.Header.Set("Authorization", authHeader)
}

func (c *Client) signingKey(dateStamp, region, service string) []byte {
	kDate := hmacSHA256([]byte("AWS4"+c.config.SecretKey), []byte(dateStamp))
	kRegion := hmacSHA256(kDate, []byte(region))
	kService := hmacSHA256(kRegion, []byte(service))
	kSigning := hmacSHA256(kService, []byte("aws4_request"))
	return kSigning
}

func hmacSHA256(key, data []byte) []byte {
	h := hmac.New(sha256.New, key)
	h.Write(data)
	return h.Sum(nil)
}

func hexSHA256(data []byte) string {
	h := sha256.Sum256(data)
	return hex.EncodeToString(h[:])
}

// urlEncode percent-encodes a string for use in query parameters (/ → %2F).
func urlEncode(s string) string {
	var buf strings.Builder
	for _, b := range []byte(s) {
		if isUnreserved(b) {
			buf.WriteByte(b)
		} else {
			fmt.Fprintf(&buf, "%%%02X", b)
		}
	}
	return buf.String()
}

func isUnreserved(b byte) bool {
	return (b >= 'A' && b <= 'Z') ||
		(b >= 'a' && b <= 'z') ||
		(b >= '0' && b <= '9') ||
		b == '-' || b == '_' || b == '.' || b == '~'
}

func mimeForExt(ext string) string {
	switch ext {
	case ".pdf":
		return "application/pdf"
	case ".png":
		return "image/png"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".gif":
		return "image/gif"
	case ".webp":
		return "image/webp"
	case ".xlsx":
		return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
	case ".docx":
		return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	default:
		return "application/octet-stream"
	}
}
