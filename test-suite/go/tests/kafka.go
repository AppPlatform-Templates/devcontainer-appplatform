package tests

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/segmentio/kafka-go"
)

const (
	kafkaService = "Kafka"
	kafkaClient  = "go-kafka"
)

// TestKafka tests Kafka connectivity
func TestKafka(utils TestUtils) ServiceResult {
	host := utils.GetEnv("KAFKA_HOST", "kafka")
	port := utils.GetEnvInt("KAFKA_PORT", 29092)
	brokers := []string{fmt.Sprintf("%s:%d", host, port)}

	if gate := utils.VerifyServiceGate(kafkaService, kafkaClient, "ENABLE_KAFKA", false, host, port); gate != nil {
		return *gate
	}

	return utils.RunCheck(kafkaService, kafkaClient, func() (string, error) {
		ctx := context.Background()
		topic := fmt.Sprintf("health-check-%s", uuid.New().String())

		// Create topic
		conn, err := kafka.Dial("tcp", brokers[0])
		if err != nil {
			return "", err
		}

		controller, err := conn.Controller()
		if err != nil {
			conn.Close()
			return "", err
		}

		controllerConn, err := kafka.Dial("tcp", fmt.Sprintf("%s:%d", controller.Host, controller.Port))
		if err != nil {
			conn.Close()
			return "", err
		}
		defer controllerConn.Close()

		topicConfigs := []kafka.TopicConfig{
			{
				Topic:             topic,
				NumPartitions:     1,
				ReplicationFactor: 1,
			},
		}

		err = controllerConn.CreateTopics(topicConfigs...)
		if err != nil {
			conn.Close()
			return "", err
		}
		conn.Close()

		// Give Kafka time to create the topic
		time.Sleep(500 * time.Millisecond)

		// Write message
		writer := kafka.NewWriter(kafka.WriterConfig{
			Brokers: brokers,
			Topic:   topic,
		})
		defer writer.Close()

		message := kafka.Message{
			Key:   []byte("test-key"),
			Value: []byte(kafkaClient),
		}

		err = writer.WriteMessages(ctx, message)
		if err != nil {
			return "", err
		}

		return fmt.Sprintf("Produced message to topic %s", topic), nil
	})
}
