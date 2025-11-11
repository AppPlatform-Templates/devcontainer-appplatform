package tests

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

// TestUtils provides utility functions for tests
type TestUtils interface {
	GetEnv(key, defaultValue string) string
	GetEnvInt(key string, defaultValue int) int
	VerifyServiceGate(service, client, envFlag string, defaultEnabled bool, host string, port int) *ServiceResult
	RunCheck(service, client string, fn func() (string, error)) ServiceResult
}
