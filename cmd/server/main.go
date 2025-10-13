package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/robert-owens/snowflake-hypermedia-app/internal/database"
	"github.com/robert-owens/snowflake-hypermedia-app/internal/handlers"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Create Echo instance
	e := echo.New()

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())
	e.Use(middleware.Gzip())

	// Add request timeout
	e.Use(middleware.TimeoutWithConfig(middleware.TimeoutConfig{
		Timeout: 30 * time.Second,
	}))

	// Connect to Snowflake
	db, err := database.NewSnowflakeConnection()
	if err != nil {
		log.Fatal("Failed to connect to Snowflake:", err)
	}
	defer db.Close()

	// Setup handlers
	h := handlers.NewHandler(db)

	// Routes
	e.GET("/", h.IndexHandler)
	e.GET("/api/refresh", h.RefreshDataHandler)
	e.POST("/api/data", h.AddDataHandler)
	e.PUT("/api/data/:id", h.UpdateDataHandler)
	e.PATCH("/api/data/:id/toggle", h.ToggleDataHandler)
	e.DELETE("/api/data/:id", h.DeleteDataHandler)
	// Static files
	e.Static("/static", "static")

	// Health check endpoint (important for Snowpark)
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(200, map[string]string{"status": "healthy"})
	})

	// Get port from environment or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s", port)
		if err := e.Start(":" + port); err != nil {
			log.Printf("Server shutdown: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(ctx); err != nil {
		log.Fatal(err)
	}

	log.Println("Server stopped gracefully")
}
