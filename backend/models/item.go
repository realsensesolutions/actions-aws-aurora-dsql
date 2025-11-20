package models

import "time"

// Item represents a simple test item in the database
type Item struct {
	ID          int       `json:"id" example:"1"`
	Title       string    `json:"title" binding:"required" example:"Test Item"`
	Description string    `json:"description" example:"This is a test item"`
	Completed   bool      `json:"completed" example:"false"`
	CreatedAt   time.Time `json:"created_at" example:"2024-01-01T00:00:00Z"`
	UpdatedAt   time.Time `json:"updated_at" example:"2024-01-01T00:00:00Z"`
}

// CreateItemRequest represents the request body for creating an item
type CreateItemRequest struct {
	Title       string `json:"title" binding:"required" example:"Test Item"`
	Description string `json:"description" example:"This is a test item"`
	Completed   bool   `json:"completed" example:"false"`
}

// UpdateItemRequest represents the request body for updating an item
type UpdateItemRequest struct {
	Title       *string `json:"title,omitempty" example:"Updated Item"`
	Description *string `json:"description,omitempty" example:"Updated description"`
	Completed   *bool   `json:"completed,omitempty" example:"true"`
}

// Response represents a generic API response
type Response struct {
	Success bool        `json:"success" example:"true"`
	Message string      `json:"message" example:"Operation successful"`
	Data    interface{} `json:"data,omitempty"`
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Success bool   `json:"success" example:"false"`
	Message string `json:"message" example:"Error message"`
	Error   string `json:"error,omitempty" example:"Detailed error information"`
}

