package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/actions-aws-aurora-dsql/backend/config"
	"github.com/actions-aws-aurora-dsql/backend/database"
	"github.com/actions-aws-aurora-dsql/backend/handlers"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	_ "github.com/actions-aws-aurora-dsql/backend/docs"
)

// @title Aurora DSQL Test API
// @version 1.0
// @description A simple CRUD API to test Aurora DSQL database operations
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.email support@example.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /api/v1

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Set Gin mode based on log level
	if cfg.App.LogLevel == "debug" {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	// Connect to database
	if err := database.Connect(cfg); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	// Setup router
	router := setupRouter()

	// Graceful shutdown
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint

		log.Println("Shutting down server...")
		database.Close()
		os.Exit(0)
	}()

	// Start server
	addr := ":" + cfg.Server.Port
	log.Printf("🚀 Server starting on http://localhost%s", addr)
	log.Printf("📚 Swagger documentation available at http://localhost%s/swagger/index.html", addr)

	if err := router.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func setupRouter() *gin.Engine {
	router := gin.Default()

	// CORS middleware (simple version for testing)
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Swagger documentation
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Health check endpoint
	router.GET("/health", handlers.HealthCheck)

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Items CRUD endpoints
		items := v1.Group("/items")
		{
			items.GET("", handlers.GetItems)
			items.GET("/:id", handlers.GetItem)
			items.POST("", handlers.CreateItem)
			items.PUT("/:id", handlers.UpdateItem)
			items.DELETE("/:id", handlers.DeleteItem)
		}
	}

	return router
}

