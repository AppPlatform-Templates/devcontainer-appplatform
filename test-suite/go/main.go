package main

import (
	"devcontainer-tests/tests"
	"fmt"
	"os"
)

// UtilsImpl implements the TestUtils interface
type UtilsImpl struct{}

func (u UtilsImpl) GetEnv(key, defaultValue string) string {
	return getEnv(key, defaultValue)
}

func (u UtilsImpl) GetEnvInt(key string, defaultValue int) int {
	return getEnvInt(key, defaultValue)
}

func (u UtilsImpl) VerifyServiceGate(service, client, envFlag string, defaultEnabled bool, host string, port int) *tests.ServiceResult {
	result := verifyServiceGate(service, client, envFlag, defaultEnabled, host, port)
	if result == nil {
		return nil
	}
	return &tests.ServiceResult{
		Service:    result.Service,
		Client:     result.Client,
		Status:     tests.Status(result.Status),
		Detail:     result.Detail,
		DurationMs: result.DurationMs,
	}
}

func (u UtilsImpl) RunCheck(service, client string, fn func() (string, error)) tests.ServiceResult {
	result := runCheck(service, client, fn)
	return tests.ServiceResult{
		Service:    result.Service,
		Client:     result.Client,
		Status:     tests.Status(result.Status),
		Detail:     result.Detail,
		DurationMs: result.DurationMs,
	}
}

// Color codes
const (
	colorReset  = "\033[0m"
	colorGreen  = "\033[32m"
	colorRed    = "\033[31m"
	colorYellow = "\033[33m"
)

func printResult(result tests.ServiceResult) {
	var color string
	var symbol string

	switch result.Status {
	case tests.StatusPass:
		color = colorGreen
		symbol = "✓"
	case tests.StatusFail:
		color = colorRed
		symbol = "✗"
	case tests.StatusSkip:
		color = colorYellow
		symbol = "⊘"
	}

	fmt.Printf("%s[%s] %-15s via %-20s (%4d ms) -> %s%s\n",
		color, symbol, result.Service, result.Client, result.DurationMs, result.Detail, colorReset)
}

func main() {
	utils := UtilsImpl{}

	fmt.Println("==========================================")
	fmt.Println("Go Service Connectivity Tests")
	fmt.Println("==========================================")
	fmt.Println()

	// Run all tests
	results := []tests.ServiceResult{
		tests.TestPostgres(utils),
		tests.TestMySQL(utils),
		tests.TestValkey(utils),
		tests.TestKafka(utils),
		tests.TestOpenSearch(utils),
		tests.TestMinIO(utils),
	}

	// Print results
	for _, result := range results {
		printResult(result)
	}

	// Summary
	passed := 0
	failed := 0
	skipped := 0

	for _, result := range results {
		switch result.Status {
		case tests.StatusPass:
			passed++
		case tests.StatusFail:
			failed++
		case tests.StatusSkip:
			skipped++
		}
	}

	fmt.Println()
	fmt.Println("==========================================")
	fmt.Printf("Summary: %d passed, %d failed, %d skipped\n", passed, failed, skipped)
	fmt.Println("==========================================")

	if failed > 0 {
		os.Exit(1)
	}
}
