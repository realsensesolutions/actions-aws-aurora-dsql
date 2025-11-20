package handlers

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/actions-aws-aurora-dsql/backend/database"
	"github.com/actions-aws-aurora-dsql/backend/models"
	"github.com/gin-gonic/gin"
)

// GetItems godoc
// @Summary List all items
// @Description Get a list of all items in the database
// @Tags items
// @Accept json
// @Produce json
// @Success 200 {object} models.Response{data=[]models.Item}
// @Failure 500 {object} models.ErrorResponse
// @Router /items [get]
func GetItems(c *gin.Context) {
	rows, err := database.DB.Query(`
		SELECT id, title, description, completed, created_at, updated_at 
		FROM items 
		ORDER BY created_at DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to fetch items",
			Error:   err.Error(),
		})
		return
	}
	defer rows.Close()

	items := []models.Item{}
	for rows.Next() {
		var item models.Item
		if err := rows.Scan(&item.ID, &item.Title, &item.Description, &item.Completed, &item.CreatedAt, &item.UpdatedAt); err != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Success: false,
				Message: "Failed to scan item",
				Error:   err.Error(),
			})
			return
		}
		items = append(items, item)
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Items fetched successfully",
		Data:    items,
	})
}

// GetItem godoc
// @Summary Get an item by ID
// @Description Get a single item by its ID
// @Tags items
// @Accept json
// @Produce json
// @Param id path int true "Item ID"
// @Success 200 {object} models.Response{data=models.Item}
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /items/{id} [get]
func GetItem(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Message: "Invalid item ID",
			Error:   err.Error(),
		})
		return
	}

	var item models.Item
	err = database.DB.QueryRow(`
		SELECT id, title, description, completed, created_at, updated_at 
		FROM items 
		WHERE id = $1
	`, id).Scan(&item.ID, &item.Title, &item.Description, &item.Completed, &item.CreatedAt, &item.UpdatedAt)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Success: false,
			Message: "Item not found",
		})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to fetch item",
			Error:   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Item fetched successfully",
		Data:    item,
	})
}

// CreateItem godoc
// @Summary Create a new item
// @Description Create a new item in the database
// @Tags items
// @Accept json
// @Produce json
// @Param item body models.CreateItemRequest true "Item to create"
// @Success 201 {object} models.Response{data=models.Item}
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /items [post]
func CreateItem(c *gin.Context) {
	var req models.CreateItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Message: "Invalid request body",
			Error:   err.Error(),
		})
		return
	}

	var item models.Item
	err := database.DB.QueryRow(`
		INSERT INTO items (title, description, completed) 
		VALUES ($1, $2, $3) 
		RETURNING id, title, description, completed, created_at, updated_at
	`, req.Title, req.Description, req.Completed).Scan(
		&item.ID, &item.Title, &item.Description, &item.Completed, &item.CreatedAt, &item.UpdatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to create item",
			Error:   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, models.Response{
		Success: true,
		Message: "Item created successfully",
		Data:    item,
	})
}

// UpdateItem godoc
// @Summary Update an item
// @Description Update an existing item by ID
// @Tags items
// @Accept json
// @Produce json
// @Param id path int true "Item ID"
// @Param item body models.UpdateItemRequest true "Item fields to update"
// @Success 200 {object} models.Response{data=models.Item}
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /items/{id} [put]
func UpdateItem(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Message: "Invalid item ID",
			Error:   err.Error(),
		})
		return
	}

	var req models.UpdateItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Message: "Invalid request body",
			Error:   err.Error(),
		})
		return
	}

	// Check if item exists
	var exists bool
	err = database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM items WHERE id = $1)", id).Scan(&exists)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to check item existence",
			Error:   err.Error(),
		})
		return
	}
	if !exists {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Success: false,
			Message: "Item not found",
		})
		return
	}

	// Build dynamic update query
	query := "UPDATE items SET updated_at = CURRENT_TIMESTAMP"
	args := []interface{}{}
	argPos := 1

	if req.Title != nil {
		argPos++
		query += ", title = $" + strconv.Itoa(argPos)
		args = append(args, *req.Title)
	}
	if req.Description != nil {
		argPos++
		query += ", description = $" + strconv.Itoa(argPos)
		args = append(args, *req.Description)
	}
	if req.Completed != nil {
		argPos++
		query += ", completed = $" + strconv.Itoa(argPos)
		args = append(args, *req.Completed)
	}

	query += " WHERE id = $1 RETURNING id, title, description, completed, created_at, updated_at"
	args = append([]interface{}{id}, args...)

	var item models.Item
	err = database.DB.QueryRow(query, args...).Scan(
		&item.ID, &item.Title, &item.Description, &item.Completed, &item.CreatedAt, &item.UpdatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to update item",
			Error:   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Item updated successfully",
		Data:    item,
	})
}

// DeleteItem godoc
// @Summary Delete an item
// @Description Delete an item by ID
// @Tags items
// @Accept json
// @Produce json
// @Param id path int true "Item ID"
// @Success 200 {object} models.Response
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /items/{id} [delete]
func DeleteItem(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Message: "Invalid item ID",
			Error:   err.Error(),
		})
		return
	}

	result, err := database.DB.Exec("DELETE FROM items WHERE id = $1", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to delete item",
			Error:   err.Error(),
		})
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Message: "Failed to check deletion result",
			Error:   err.Error(),
		})
		return
	}

	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Success: false,
			Message: "Item not found",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Success: true,
		Message: "Item deleted successfully",
	})
}

