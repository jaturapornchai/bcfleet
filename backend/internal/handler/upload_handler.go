package handler

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"bc-fleet/internal/r2"

	"github.com/gin-gonic/gin"
)

const (
	maxImageSize    = 10 << 20 // 10 MB
	maxDocumentSize = 50 << 20 // 50 MB
)

// RegisterUploadRoutes mounts R2 upload endpoints onto the given router group.
//
//	POST /upload/image    — รับ multipart "file" → R2 → return URL
//	POST /upload/document — รับ multipart "file" → R2 → return URL
func RegisterUploadRoutes(rg *gin.RouterGroup, r2Config r2.Config) {
	client := r2.NewClient(r2Config)
	h := &uploadHandler{client: client}

	rg.POST("/upload/image", h.UploadImage)
	rg.POST("/upload/document", h.UploadDocument)
}

type uploadHandler struct {
	client *r2.Client
}

// UploadImage godoc
// POST /upload/image
// Form-data field: "file" (image/jpeg, image/png, image/webp, image/gif)
// Optional form field: "folder" (default: "images")
func (h *uploadHandler) UploadImage(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxImageSize)

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ไม่พบไฟล์ 'file' ใน form-data"})
		return
	}
	defer file.Close()

	// Validate content type
	ct := header.Header.Get("Content-Type")
	if !isImageContentType(ct) {
		// Fall back to extension check
		ext := strings.ToLower(filepath.Ext(header.Filename))
		if !isImageExtension(ext) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "รองรับเฉพาะไฟล์รูปภาพ (JPEG, PNG, GIF, WebP)"})
			return
		}
	}

	folder := c.DefaultPostForm("folder", "images")
	folder = sanitizeFolder(folder)

	ctx := c.Request.Context()
	publicURL, err := h.client.UploadImage(ctx, folder, file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("อัปโหลดล้มเหลว: %s", err.Error())})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url":         publicURL,
		"folder":      folder,
		"filename":    header.Filename,
		"size":        header.Size,
		"uploaded_at": time.Now().UTC().Format(time.RFC3339),
	})
}

// UploadDocument godoc
// POST /upload/document
// Form-data field: "file" (PDF, XLSX, DOCX, etc.)
// Optional form field: "folder" (default: "documents")
func (h *uploadHandler) UploadDocument(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxDocumentSize)

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ไม่พบไฟล์ 'file' ใน form-data"})
		return
	}
	defer file.Close()

	// Basic extension guard — allow common document types
	ext := strings.ToLower(filepath.Ext(header.Filename))
	if !isDocumentExtension(ext) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "รองรับเฉพาะไฟล์ PDF, XLSX, DOCX, PNG, JPEG"})
		return
	}

	folder := c.DefaultPostForm("folder", "documents")
	folder = sanitizeFolder(folder)

	ctx := c.Request.Context()
	publicURL, err := h.client.UploadDocument(ctx, folder, file, header.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("อัปโหลดล้มเหลว: %s", err.Error())})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url":         publicURL,
		"folder":      folder,
		"filename":    header.Filename,
		"size":        header.Size,
		"uploaded_at": time.Now().UTC().Format(time.RFC3339),
	})
}

// --- helpers ---

func isImageContentType(ct string) bool {
	ct = strings.ToLower(ct)
	return strings.HasPrefix(ct, "image/jpeg") ||
		strings.HasPrefix(ct, "image/png") ||
		strings.HasPrefix(ct, "image/gif") ||
		strings.HasPrefix(ct, "image/webp")
}

func isImageExtension(ext string) bool {
	switch ext {
	case ".jpg", ".jpeg", ".png", ".gif", ".webp":
		return true
	}
	return false
}

func isDocumentExtension(ext string) bool {
	switch ext {
	case ".pdf", ".xlsx", ".xls", ".docx", ".doc", ".png", ".jpg", ".jpeg":
		return true
	}
	return false
}

// sanitizeFolder strips leading/trailing slashes and dots to prevent path traversal.
func sanitizeFolder(folder string) string {
	folder = filepath.Clean(folder)
	folder = strings.Trim(folder, "/.")
	if folder == "" {
		return "uploads"
	}
	return folder
}
