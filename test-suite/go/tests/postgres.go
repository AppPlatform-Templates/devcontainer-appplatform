package tests

import (
	"database/sql"
	"fmt"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
)

const (
	postgresService = "PostgreSQL"
	postgresClient  = "go-lib/pq"
)

// TestPostgres tests PostgreSQL connectivity
func TestPostgres(utils TestUtils) ServiceResult {
	host := utils.GetEnv("POSTGRES_HOST", "postgres")
	port := utils.GetEnvInt("POSTGRES_PORT", 5432)
	user := utils.GetEnv("POSTGRES_USER", "postgres")
	password := utils.GetEnv("POSTGRES_PASSWORD", "postgres")
	database := utils.GetEnv("POSTGRES_DB", "devcontainer_db")

	if gate := utils.VerifyServiceGate(postgresService, postgresClient, "ENABLE_POSTGRES", true, host, port); gate != nil {
		return *gate
	}

	return utils.RunCheck(postgresService, postgresClient, func() (string, error) {
		connStr := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
			host, port, user, password, database)

		db, err := sql.Open("postgres", connStr)
		if err != nil {
			return "", err
		}
		defer db.Close()

		// Create table
		_, err = db.Exec(`
			CREATE TABLE IF NOT EXISTS health_check_events (
				id UUID PRIMARY KEY,
				source TEXT NOT NULL,
				created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
			)
		`)
		if err != nil {
			return "", err
		}

		// Insert test data
		eventID := uuid.New()
		_, err = db.Exec("INSERT INTO health_check_events (id, source) VALUES ($1, $2)",
			eventID, postgresClient)
		if err != nil {
			return "", err
		}

		// Verify data
		var count int
		err = db.QueryRow("SELECT COUNT(*) FROM health_check_events WHERE id = $1", eventID).Scan(&count)
		if err != nil {
			return "", err
		}

		return fmt.Sprintf("Inserted row %s (rows_found=%d)", eventID, count), nil
	})
}
