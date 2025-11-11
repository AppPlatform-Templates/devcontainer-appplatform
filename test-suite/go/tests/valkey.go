package tests

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

const (
	valkeyService = "Valkey"
	valkeyClient  = "go-redis"
)

// TestValkey tests Valkey connectivity
func TestValkey(utils TestUtils) ServiceResult {
	host := utils.GetEnv("VALKEY_HOST", utils.GetEnv("REDIS_HOST", "valkey"))
	port := utils.GetEnvInt("VALKEY_PORT", utils.GetEnvInt("REDIS_PORT", 6379))

	if gate := utils.VerifyServiceGate(valkeyService, valkeyClient, "ENABLE_VALKEY", false, host, port); gate != nil {
		return *gate
	}

	return utils.RunCheck(valkeyService, valkeyClient, func() (string, error) {
		ctx := context.Background()
		client := redis.NewClient(&redis.Options{
			Addr: fmt.Sprintf("%s:%d", host, port),
		})
		defer client.Close()

		// Test connection
		payload := uuid.New().String()
		key := fmt.Sprintf("health:%s", payload)

		// Set value with expiration
		err := client.Set(ctx, key, payload, 0).Err()
		if err != nil {
			return "", err
		}

		// Get value
		value, err := client.Get(ctx, key).Result()
		if err != nil {
			return "", err
		}

		// Delete key
		client.Del(ctx, key)

		if value != payload {
			return "", fmt.Errorf("unexpected payload: got %s, want %s", value, payload)
		}

		return fmt.Sprintf("SET/GET on %s succeeded", key), nil
	})
}
