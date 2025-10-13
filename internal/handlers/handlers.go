package handlers

import (
	"log"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/robert-owens/snowflake-hypermedia-app/internal/database"
	"github.com/robert-owens/snowflake-hypermedia-app/internal/models"
	"github.com/robert-owens/snowflake-hypermedia-app/templates"
)

type Handler struct {
	DB *database.SnowflakeDB
}

func NewHandler(db *database.SnowflakeDB) *Handler {
	return &Handler{DB: db}
}

// IndexHandler serves the main page
func (h *Handler) IndexHandler(c echo.Context) error {
	// Get initial data
	data, err := h.DB.QueryData(c.Request().Context())
	if err != nil {
		log.Printf("Error querying data: %v", err)
		data = []models.DataRow{} // Return empty slice on error
	}

	// Render the template
	return templates.Index(data).Render(c.Request().Context(), c.Response().Writer)
}

// RefreshDataHandler returns updated table data
func (h *Handler) RefreshDataHandler(c echo.Context) error {
	data, err := h.DB.QueryData(c.Request().Context())
	if err != nil {
		log.Printf("Error refreshing data: %v", err)
		return c.String(http.StatusInternalServerError, "Error fetching data")
	}

	// Return just the table component
	return templates.DataTable(data).Render(c.Request().Context(), c.Response().Writer)
}

// AddDataHandler handles form submission to add new todo
func (h *Handler) AddDataHandler(c echo.Context) error {
	task := c.FormValue("task")
	done := c.FormValue("done") == "true"

	if task == "" {
		return c.String(http.StatusBadRequest, "Task is required")
	}

	err := h.DB.InsertData(c.Request().Context(), task, done)
	if err != nil {
		log.Printf("Error inserting todo: %v", err)
		return c.String(http.StatusInternalServerError, "Error adding todo")
	}

	// Return updated table
	data, err := h.DB.QueryData(c.Request().Context())
	if err != nil {
		log.Printf("Error querying data after insert: %v", err)
		return c.String(http.StatusInternalServerError, "Error fetching data")
	}

	return templates.DataTable(data).Render(c.Request().Context(), c.Response().Writer)
}

// UpdateDataHandler handles updating todo task text
func (h *Handler) UpdateDataHandler(c echo.Context) error {
	id := c.Param("id")
	task := c.FormValue("task")
	done := c.FormValue("done") == "true"

	if task == "" {
		return c.String(http.StatusBadRequest, "Task is required")
	}

	err := h.DB.UpdateData(c.Request().Context(), id, task, done)
	if err != nil {
		log.Printf("Error updating todo: %v", err)
		return c.String(http.StatusInternalServerError, "Error updating todo")
	}

	// Return updated table
	data, err := h.DB.QueryData(c.Request().Context())
	if err != nil {
		log.Printf("Error querying data after update: %v", err)
		return c.String(http.StatusInternalServerError, "Error fetching data")
	}

	return templates.DataTable(data).Render(c.Request().Context(), c.Response().Writer)
}

// ToggleDataHandler handles toggling todo completion status
func (h *Handler) ToggleDataHandler(c echo.Context) error {
	id := c.Param("id")

	err := h.DB.ToggleData(c.Request().Context(), id)
	if err != nil {
		log.Printf("Error toggling todo: %v", err)
		return c.String(http.StatusInternalServerError, "Error toggling todo")
	}

	// Return updated table
	data, err := h.DB.QueryData(c.Request().Context())
	if err != nil {
		log.Printf("Error querying data after toggle: %v", err)
		return c.String(http.StatusInternalServerError, "Error fetching data")
	}

	return templates.DataTable(data).Render(c.Request().Context(), c.Response().Writer)
}

// DeleteDataHandler handles deletion of data
func (h *Handler) DeleteDataHandler(c echo.Context) error {
	id := c.Param("id")

	err := h.DB.DeleteData(c.Request().Context(), id)
	if err != nil {
		log.Printf("Error deleting data: %v", err)
		return c.String(http.StatusInternalServerError, "Error deleting data")
	}

	// Return empty response (row will be removed by HTMX)
	return c.NoContent(http.StatusOK)
}
