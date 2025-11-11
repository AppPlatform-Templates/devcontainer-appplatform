package tests

import (
	"bytes"
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

const (
	minioService = "MinIO"
	minioClient  = "go-minio"
)

// TestMinIO tests MinIO connectivity
func TestMinIO(utils TestUtils) ServiceResult {
	host := utils.GetEnv("MINIO_HOST", "minio")
	port := utils.GetEnvInt("MINIO_PORT", 9000)
	accessKey := utils.GetEnv("MINIO_ACCESS_KEY", "minio")
	secretKey := utils.GetEnv("MINIO_SECRET_KEY", "minio12345")

	if gate := utils.VerifyServiceGate(minioService, minioClient, "ENABLE_MINIO", true, host, port); gate != nil {
		return *gate
	}

	return utils.RunCheck(minioService, minioClient, func() (string, error) {
		ctx := context.Background()

		client, err := minio.New(fmt.Sprintf("%s:%d", host, port), &minio.Options{
			Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
			Secure: false,
		})
		if err != nil {
			return "", err
		}

		// Create bucket
		bucketName := fmt.Sprintf("health-check-%s", uuid.New().String())
		err = client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{})
		if err != nil {
			return "", err
		}

		// Upload object
		objectName := fmt.Sprintf("test-%s.txt", uuid.New().String())
		content := []byte(minioClient)
		reader := bytes.NewReader(content)

		_, err = client.PutObject(ctx, bucketName, objectName, reader, int64(len(content)), minio.PutObjectOptions{
			ContentType: "text/plain",
		})
		if err != nil {
			return "", err
		}

		return fmt.Sprintf("Uploaded object %s to bucket %s", objectName, bucketName), nil
	})
}
