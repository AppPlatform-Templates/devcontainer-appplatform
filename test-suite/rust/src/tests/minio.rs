use crate::utils::*;
use s3::bucket::Bucket;
use s3::creds::Credentials;
use s3::region::Region;
use uuid::Uuid;

const SERVICE: &str = "MinIO";
const CLIENT_NAME: &str = "rust-s3";

pub fn test_minio() -> ServiceResult {
    let host = get_env("MINIO_HOST", "minio");
    let port = get_env_u16("MINIO_PORT", 9000);
    let access_key = get_env("MINIO_ACCESS_KEY", "minio");
    let secret_key = get_env("MINIO_SECRET_KEY", "minio12345");

    if let Some(gate) = verify_service_gate(SERVICE, CLIENT_NAME, "ENABLE_MINIO", true, &host, port) {
        return gate;
    }

    run_check(SERVICE, CLIENT_NAME, || {
        let endpoint = format!("http://{}:{}", host, port);
        let region = Region::Custom {
            region: "us-east-1".to_string(),
            endpoint,
        };

        let credentials = Credentials::new(
            Some(&access_key),
            Some(&secret_key),
            None,
            None,
            None,
        )?;

        // Use Tokio runtime for reqwest-based clients
        let runtime = tokio::runtime::Runtime::new()?;
        runtime.block_on(async {
            // Create bucket
            let bucket_name = format!("health-check-{}", Uuid::new_v4());
            let create_response = Bucket::create_with_path_style(
                &bucket_name,
                region.clone(),
                credentials.clone(),
                s3::BucketConfiguration::default(),
            )
            .await
            .map_err(|e| format!("Failed to create bucket: {:?}", e))?;

            let bucket = *create_response.bucket;

            // Upload object
            let object_name = format!("test-{}.txt", Uuid::new_v4());
            let content = CLIENT_NAME.as_bytes();

            let response = bucket.put_object(&object_name, content)
                .await
                .map_err(|e| format!("Failed to upload object: {:?}", e))?;

            if response.status_code() != 200 {
                return Err(format!("Upload failed with status: {}", response.status_code()).into());
            }

            Ok(format!(
                "Uploaded object {} to bucket {}",
                object_name, bucket_name
            ))
        })
    })
}
