use crate::utils::*;
use redis::Commands;
use uuid::Uuid;

const SERVICE: &str = "Valkey";
const CLIENT_NAME: &str = "rust-redis";

pub fn test_valkey() -> ServiceResult {
    let host = get_env("VALKEY_HOST", &get_env("REDIS_HOST", "valkey"));
    let port = get_env_u16("VALKEY_PORT", get_env_u16("REDIS_PORT", 6379));

    if let Some(gate) = verify_service_gate(SERVICE, CLIENT_NAME, "ENABLE_VALKEY", false, &host, port) {
        return gate;
    }

    run_check(SERVICE, CLIENT_NAME, || {
        let redis_url = format!("redis://{}:{}", host, port);
        let client = redis::Client::open(redis_url)?;
        let mut con = client.get_connection()?;

        // Test connection
        let payload = Uuid::new_v4().to_string();
        let key = format!("health:{}", payload);

        // Set value
        con.set::<_, _, ()>(&key, &payload)?;

        // Get value
        let value: String = con.get(&key)?;

        // Delete key
        con.del::<_, ()>(&key)?;

        if value != payload {
            return Err(format!("unexpected payload: got {}, want {}", value, payload).into());
        }

        Ok(format!("SET/GET on {} succeeded", key))
    })
}
