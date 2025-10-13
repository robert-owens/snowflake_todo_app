package database

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/robert-owens/snowflake-hypermedia-app/internal/models"
	sf "github.com/snowflakedb/gosnowflake"
)

type SnowflakeDB struct {
	DB *sql.DB
}

func NewSnowflakeConnection() (*SnowflakeDB, error) {
	// Get connection parameters from environment
	account := os.Getenv("SNOWFLAKE_ACCOUNT")
	user := os.Getenv("SNOWFLAKE_USER")
	sessionToken := os.Getenv("SNOWFLAKE_SESSION_TOKEN")
	authenticator := os.Getenv("SNOWFLAKE_AUTHENTICATOR")
	accessToken := os.Getenv("SNOWFLAKE_ACCESS_TOKEN") // PAT token (Snowpark)
	token := os.Getenv("SNOWFLAKE_TOKEN")              // PAT token (Docker Compose)
	database := os.Getenv("SNOWFLAKE_DATABASE")
	schema := os.Getenv("SNOWFLAKE_SCHEMA")
	warehouse := os.Getenv("SNOWFLAKE_WAREHOUSE")

	// Use either token variable
	if token != "" && accessToken == "" {
		accessToken = token
	}

	// Validate required base parameters
	if account == "" {
		return nil, fmt.Errorf("missing required Snowflake account")
	}

	// User is optional in Snowpark Container Services
	if user == "" {
		log.Println("No user specified - using service account authentication")
	}

	log.Printf("Attempting to connect to Snowflake account: %s, database: %s, schema: %s, user: %s", account, database, schema, user)

	// Check if we can resolve Snowflake hostname
	snowflakeHost := fmt.Sprintf("%s.snowflakecomputing.com", account)
	log.Printf("Snowflake hostname: %s", snowflakeHost)

	// Debug: Check what authentication method we're using
	if sessionToken != "" {
		log.Printf("Found session token (length: %d)", len(sessionToken))
	} else if authenticator == "externalbrowser" {
		log.Printf("Using external browser authentication")
	} else if accessToken != "" {
		log.Printf("Found access token (PAT) for authentication")
	} else {
		log.Printf("No session token, external browser auth, or access token found")
		tokenStatus := ""
		if len(accessToken) > 0 {
			tokenStatus = "***PRESENT***"
		}
		log.Printf("Available env vars: SNOWFLAKE_SESSION_TOKEN=%s, SNOWFLAKE_AUTHENTICATOR=%s, SNOWFLAKE_ACCESS_TOKEN=%s",
			os.Getenv("SNOWFLAKE_SESSION_TOKEN"), os.Getenv("SNOWFLAKE_AUTHENTICATOR"), tokenStatus)
	}
	var db *sql.DB
	var err error

	// Priority: Session Token > Access Token (PAT) > External Browser > Fallback
	if sessionToken != "" {
		// Session token authentication (Snowpark Container Services)
		log.Println("Using session token authentication (Snowpark Container)")
		dsn := fmt.Sprintf("%s@%s/%s/%s?warehouse=%s&authenticator=SNOWFLAKE_JWT&token=%s",
			user, account, database, schema, warehouse, sessionToken)
		db, err = sql.Open("snowflake", dsn)
	} else if accessToken != "" || authenticator == "oauth" {
		// Access token (PAT) authentication or explicit OAuth
		log.Println("Using OAuth/PAT authentication")

		// Try direct DSN format with token
		dsn := fmt.Sprintf("%s@%s/%s/%s?warehouse=%s&authenticator=oauth&token=%s",
			user, account, database, schema, warehouse, accessToken)
		log.Println("Using OAuth DSN with token")

		db, err = sql.Open("snowflake", dsn)
		if err != nil {
			// Fallback to Config approach
			log.Println("Direct DSN failed, trying Config approach")
			cfg := &sf.Config{
				Account:       account,
				User:          user,
				Database:      database,
				Schema:        schema,
				Warehouse:     warehouse,
				Authenticator: sf.AuthTypeOAuth,
				Token:         accessToken,
			}

			dsn, err = sf.DSN(cfg)
			if err != nil {
				return nil, fmt.Errorf("failed to create DSN: %w", err)
			}

			db, err = sql.Open("snowflake", dsn)
		}
	} else if authenticator == "externalbrowser" {
		// External browser authentication (SSO/SAML for local development)
		log.Println("Using external browser authentication (SSO)")
		cfg := &sf.Config{
			Account:       account,
			User:          user,
			Database:      database,
			Schema:        schema,
			Warehouse:     warehouse,
			Authenticator: sf.AuthTypeExternalBrowser,
		}

		dsn, err := sf.DSN(cfg)
		if err != nil {
			return nil, fmt.Errorf("failed to create DSN: %w", err)
		}

		db, err = sql.Open("snowflake", dsn)
	} else {
		return nil, fmt.Errorf("no valid authentication method found - need session token, access token (PAT), or external browser auth")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to open Snowflake connection: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(time.Hour)

	// Test connection with longer timeout for Snowpark
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	log.Println("Testing Snowflake connection...")
	if err := db.PingContext(ctx); err != nil {
		log.Printf("Connection ping failed: %v", err)
		return nil, fmt.Errorf("failed to ping Snowflake: %w", err)
	}

	log.Println("Successfully connected to Snowflake")

	return &SnowflakeDB{DB: db}, nil
}

func (s *SnowflakeDB) QueryData(ctx context.Context) ([]models.DataRow, error) {
	query := "SELECT ID, TASK, DONE FROM TEST_TODO_ITEMS ORDER BY ID LIMIT 100"

	rows, err := s.DB.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query data: %w", err)
	}
	defer rows.Close()

	var results []models.DataRow

	for rows.Next() {
		var row models.DataRow
		if err := rows.Scan(&row.ID, &row.Task, &row.Done); err != nil {
			return nil, fmt.Errorf("failed to scan row: %w", err)
		}
		results = append(results, row)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	return results, nil
}

func (s *SnowflakeDB) InsertData(ctx context.Context, task string, done bool) error {
	query := "INSERT INTO TEST_TODO_ITEMS (TASK, DONE) VALUES (?, ?)"

	_, err := s.DB.ExecContext(ctx, query, task, done)
	if err != nil {
		return fmt.Errorf("failed to insert data: %w", err)
	}

	return nil
}

func (s *SnowflakeDB) UpdateData(ctx context.Context, id, task string, done bool) error {
	query := "UPDATE TEST_TODO_ITEMS SET TASK = ?, DONE = ? WHERE ID = ?"

	result, err := s.DB.ExecContext(ctx, query, task, done, id)
	if err != nil {
		return fmt.Errorf("failed to update todo: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rows == 0 {
		return fmt.Errorf("no rows updated")
	}

	return nil
}

func (s *SnowflakeDB) ToggleData(ctx context.Context, id string) error {
	query := "UPDATE TEST_TODO_ITEMS SET DONE = NOT DONE WHERE ID = ?"

	result, err := s.DB.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to toggle todo: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rows == 0 {
		return fmt.Errorf("no rows updated")
	}

	return nil
}

func (s *SnowflakeDB) DeleteData(ctx context.Context, id string) error {
	query := "DELETE FROM TEST_TODO_ITEMS WHERE ID = ?"

	result, err := s.DB.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete data: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rows == 0 {
		return fmt.Errorf("no rows deleted")
	}

	return nil
}

func (s *SnowflakeDB) Close() error {
	return s.DB.Close()
}
