package tests

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/opensearch-project/opensearch-go/v4"
	"github.com/opensearch-project/opensearch-go/v4/opensearchapi"
)

const (
	opensearchService = "OpenSearch"
	opensearchClient  = "go-opensearch"
)

// TestOpenSearch tests OpenSearch connectivity
func TestOpenSearch(utils TestUtils) ServiceResult {
	host := utils.GetEnv("OPENSEARCH_HOST", "opensearch")
	port := utils.GetEnvInt("OPENSEARCH_PORT", 9200)

	if gate := utils.VerifyServiceGate(opensearchService, opensearchClient, "ENABLE_OPENSEARCH", false, host, port); gate != nil {
		return *gate
	}

	return utils.RunCheck(opensearchService, opensearchClient, func() (string, error) {
		ctx := context.Background()

		client, err := opensearchapi.NewClient(opensearchapi.Config{
			Client: opensearch.Config{
				Addresses: []string{fmt.Sprintf("http://%s:%d", host, port)},
			},
		})
		if err != nil {
			return "", err
		}

		// Create index
		indexName := fmt.Sprintf("health-check-%s", uuid.New().String())

		createReq := opensearchapi.IndicesCreateReq{
			Index: indexName,
		}
		_, err = client.Indices.Create(ctx, createReq)
		if err != nil {
			return "", err
		}

		// Index a document
		docID := uuid.New().String()
		document := strings.NewReader(fmt.Sprintf(`{"source": "%s", "id": "%s"}`, opensearchClient, docID))

		indexReq := opensearchapi.IndexReq{
			Index:      indexName,
			DocumentID: docID,
			Body:       document,
		}
		_, err = client.Index(ctx, indexReq)
		if err != nil {
			return "", err
		}

		return fmt.Sprintf("Indexed document %s in index %s", docID, indexName), nil
	})
}
