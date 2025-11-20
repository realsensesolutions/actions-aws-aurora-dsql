package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/actions-aws-aurora-dsql/backend/database"
	"github.com/actions-aws-aurora-dsql/backend/models"
	"github.com/gin-gonic/gin"
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status   string `json:"status" example:"healthy"`
	Database string `json:"database" example:"connected"`
	Version  string `json:"version" example:"1.0.0"`
}

// HealthCheck godoc
// @Summary Health check
// @Description Check if the API and database are healthy
// @Tags health
// @Accept json
// @Produce json
// @Success 200 {object} models.Response{data=HealthResponse}
// @Failure 503 {object} models.ErrorResponse
// @Router /health [get]
func HealthCheck(c *gin.Context) {
	// Check database connection
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	dbStatus := "connected"
	if err := database.DB.PingContext(ctx); err != nil {
		dbStatus = "disconnected"
		c.JSON(http.StatusServiceUnavailable, models.ErrorResponse{
			Success: false,
			Message: "Service unhealthy",
			Error:   "Database connection failed: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Service is healthy",
		Data: HealthResponse{
			Status:   "healthy",
			Database: dbStatus,
			Version:  "1.0.0",
		},
	})
}

