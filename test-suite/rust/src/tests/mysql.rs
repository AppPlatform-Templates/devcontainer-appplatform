use crate::utils::*;
use mysql::prelude::*;
use mysql::*;
use uuid::Uuid;

const SERVICE: &str = "MySQL";
const CLIENT_NAME: &str = "rust-mysql";

pub fn test_mysql() -> ServiceResult {
    let host = get_env("MYSQL_HOST", "mysql");
    let port = get_env_u16("MYSQL_PORT", 3306);
    let user = get_env("MYSQL_USER", "mysql");
    let password = get_env("MYSQL_PASSWORD", "mysql");
    let database = get_env("MYSQL_DATABASE", "devcontainer_db");

    if let Some(gate) = verify_service_gate(SERVICE, CLIENT_NAME, "ENABLE_MYSQL", false, &host, port) {
        return gate;
    }

    run_check(SERVICE, CLIENT_NAME, || {
        let url = format!(
            "mysql://{}:{}@{}:{}/{}",
            user, password, host, port, database
        );

        let pool = Pool::new(url.as_str())?;
        let mut conn = pool.get_conn()?;

        // Create table
        conn.query_drop(
            "CREATE TABLE IF NOT EXISTS health_check_events (
                id CHAR(36) PRIMARY KEY,
                source VARCHAR(255) NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )",
        )?;

        // Insert test data
        let event_id = Uuid::new_v4().to_string();
        conn.exec_drop(
            "INSERT INTO health_check_events (id, source) VALUES (?, ?)",
            (&event_id, CLIENT_NAME),
        )?;

        // Verify data
        let count: Option<i64> = conn.exec_first(
            "SELECT COUNT(*) FROM health_check_events WHERE id = ?",
            (&event_id,),
        )?;

        Ok(format!(
            "Inserted row {} (rows_found={})",
            event_id,
            count.unwrap_or(0)
        ))
    })
}
