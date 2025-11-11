package main

import (
	"fmt"
	"net"
	"os"
	"strings"
	"time"
)

// Status represents test result status
type Status string

const (
	StatusPass Status = "PASS"
	StatusFail Status = "FAIL"
	StatusSkip Status = "SKIP"
)

// ServiceResult holds the result of a service connectivity test
type ServiceResult struct {
	Service    string
	Client     string
	Status     Status
	Detail     string
	DurationMs int64
}

// envBool reads a boolean from environment with a default value
func envBool(name string, defaultVal bool) bool {
	raw := os.Getenv(name)
	if raw == "" {
		return defaultVal
	}
	lower := strings.ToLower(raw)
	return lower == "1" || lower == "true" || lower == "yes" || lower == "on"
}

// waitForPort attempts to connect to a TCP port within the timeout
func waitForPort(host string, port int, timeout time.Duration) bool {
	address := fmt.Sprintf("%s:%d", host, port)
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		conn, err := net.DialTimeout("tcp", address, 500*time.Millisecond)
		if err == nil {
			conn.Close()
			return true
		}
		time.Sleep(200 * time.Millisecond)
	}
	return false
}

// skipResult creates a SKIP result
func skipResult(service, client, reason string) ServiceResult {
	return ServiceResult{
		Service:    service,
		Client:     client,
		Status:     StatusSkip,
		Detail:     reason,
		DurationMs: 0,
	}
}

// failResult creates a FAIL result
func failResult(service, client, reason string) ServiceResult {
	return ServiceResult{
		Service:    service,
		Client:     client,
		Status:     StatusFail,
		Detail:     reason,
		DurationMs: 0,
	}
}

// runCheck executes a test function and captures timing and errors
func runCheck(service, client string, fn func() (string, error)) ServiceResult {
	start := time.Now()
	detail, err := fn()
	duration := time.Since(start).Milliseconds()

	if err != nil {
		return ServiceResult{
			Service:    service,
			Client:     client,
			Status:     StatusFail,
			Detail:     fmt.Sprintf("%s", err),
			DurationMs: duration,
		}
	}

	return ServiceResult{
		Service:    service,
		Client:     client,
		Status:     StatusPass,
		Detail:     detail,
		DurationMs: duration,
	}
}

// verifyServiceGate checks if service is enabled and reachable
// Returns nil if the test should proceed, otherwise returns a skip/fail result
func verifyServiceGate(service, client, envFlag string, defaultEnabled bool, host string, port int) *ServiceResult {
	if !envBool(envFlag, defaultEnabled) {
		result := skipResult(service, client, fmt.Sprintf("%s=false -> service intentionally disabled", envFlag))
		return &result
	}

	if port > 0 && !waitForPort(host, port, 2*time.Second) {
		result := failResult(service, client, fmt.Sprintf("%s:%d is not reachable", host, port))
		return &result
	}

	return nil
}

// getEnv retrieves an environment variable with a default value
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// getEnvInt retrieves an integer environment variable with a default value
func getEnvInt(key string, defaultValue int) int {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	var intValue int
	fmt.Sscanf(value, "%d", &intValue)
	return intValue
}
