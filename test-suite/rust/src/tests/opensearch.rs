use crate::utils::*;
use opensearch::indices::IndicesCreateParts;
use opensearch::IndexParts;
use opensearch::{http::transport::Transport, OpenSearch};
use serde_json::json;
use uuid::Uuid;

const SERVICE: &str = "OpenSearch";
const CLIENT_NAME: &str = "rust-opensearch";

pub fn test_opensearch() -> ServiceResult {
    let host = get_env("OPENSEARCH_HOST", "opensearch");
    let port = get_env_u16("OPENSEARCH_PORT", 9200);

    if let Some(gate) = verify_service_gate(SERVICE, CLIENT_NAME, "ENABLE_OPENSEARCH", false, &host, port) {
        return gate;
    }

    run_check(SERVICE, CLIENT_NAME, || {
        let url = format!("http://{}:{}", host, port);

        // Use Tokio runtime for reqwest-based clients
        let runtime = tokio::runtime::Runtime::new()?;
        runtime.block_on(async {
            let transport = Transport::single_node(&url)?;
            let client = OpenSearch::new(transport);

            // Create index
            let index_name = format!("health-check-{}", Uuid::new_v4());
            let create_response = client
                .indices()
                .create(IndicesCreateParts::Index(&index_name))
                .send()
                .await?;

            if !create_response.status_code().is_success() {
                let body = create_response.text().await?;
                return Err(format!("Failed to create index: {}", body).into());
            }

            // Index a document
            let doc_id = Uuid::new_v4().to_string();
            let document = json!({
                "source": CLIENT_NAME,
                "id": doc_id
            });

            let index_response = client
                .index(IndexParts::IndexId(&index_name, &doc_id))
                .body(document)
                .send()
                .await?;

            if !index_response.status_code().is_success() {
                let body = index_response.text().await?;
                return Err(format!("Failed to index document: {}", body).into());
            }

            Ok(format!(
                "Indexed document {} in index {}",
                doc_id, index_name
            ))
        })
    })
}
