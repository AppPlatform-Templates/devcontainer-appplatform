package tests

import (
	"database/sql"
	"fmt"

	"github.com/go-sql-driver/mysql"
	"github.com/google/uuid"
)

const (
	mysqlService = "MySQL"
	mysqlClient  = "go-mysql"
)

// TestMySQL tests MySQL connectivity
func TestMySQL(utils TestUtils) ServiceResult {
	host := utils.GetEnv("MYSQL_HOST", "mysql")
	port := utils.GetEnvInt("MYSQL_PORT", 3306)
	user := utils.GetEnv("MYSQL_USER", "mysql")
	password := utils.GetEnv("MYSQL_PASSWORD", "mysql")
	database := utils.GetEnv("MYSQL_DATABASE", "devcontainer_db")

	if gate := utils.VerifyServiceGate(mysqlService, mysqlClient, "ENABLE_MYSQL", false, host, port); gate != nil {
		return *gate
	}

	return utils.RunCheck(mysqlService, mysqlClient, func() (string, error) {
		config := mysql.NewConfig()
		config.User = user
		config.Passwd = password
		config.Net = "tcp"
		config.Addr = fmt.Sprintf("%s:%d", host, port)
		config.DBName = database
		config.ParseTime = true

		db, err := sql.Open("mysql", config.FormatDSN())
		if err != nil {
			return "", err
		}
		defer db.Close()

		// Create table
		_, err = db.Exec(`
			CREATE TABLE IF NOT EXISTS health_check_events (
				id CHAR(36) PRIMARY KEY,
				source VARCHAR(255) NOT NULL,
				created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
			)
		`)
		if err != nil {
			return "", err
		}

		// Insert test data
		eventID := uuid.New().String()
		_, err = db.Exec("INSERT INTO health_check_events (id, source) VALUES (?, ?)",
			eventID, mysqlClient)
		if err != nil {
			return "", err
		}

		// Verify data
		var count int
		err = db.QueryRow("SELECT COUNT(*) FROM health_check_events WHERE id = ?", eventID).Scan(&count)
		if err != nil {
			return "", err
		}

		return fmt.Sprintf("Inserted row %s (rows_found=%d)", eventID, count), nil
	})
}
