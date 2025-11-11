use crate::utils::*;
use postgres::{Client, NoTls};
use uuid::Uuid;

const SERVICE: &str = "PostgreSQL";
const CLIENT_NAME: &str = "rust-postgres";

pub fn test_postgres() -> ServiceResult {
    let host = get_env("POSTGRES_HOST", "postgres");
    let port = get_env_u16("POSTGRES_PORT", 5432);
    let user = get_env("POSTGRES_USER", "postgres");
    let password = get_env("POSTGRES_PASSWORD", "postgres");
    let database = get_env("POSTGRES_DB", "devcontainer_db");

    if let Some(gate) = verify_service_gate(SERVICE, CLIENT_NAME, "ENABLE_POSTGRES", true, &host, port) {
        return gate;
    }

    run_check(SERVICE, CLIENT_NAME, || {
        let conn_str = format!(
            "host={} port={} user={} password={} dbname={}",
            host, port, user, password, database
        );

        let mut client = Client::connect(&conn_str, NoTls)?;

        // Create table
        client.execute(
            "CREATE TABLE IF NOT EXISTS health_check_events (
                id UUID PRIMARY KEY,
                source TEXT NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )",
            &[],
        )?;

        // Insert test data
        let event_id = Uuid::new_v4();
        client.execute(
            "INSERT INTO health_check_events (id, source) VALUES ($1, $2)",
            &[&event_id, &CLIENT_NAME],
        )?;

        // Verify data
        let row = client.query_one(
            "SELECT COUNT(*) FROM health_check_events WHERE id = $1",
            &[&event_id],
        )?;
        let count: i64 = row.get(0);

        Ok(format!("Inserted row {} (rows_found={})", event_id, count))
    })
}
