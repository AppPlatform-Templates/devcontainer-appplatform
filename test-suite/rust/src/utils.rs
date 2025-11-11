use std::env;
use std::net::{TcpStream, ToSocketAddrs};
use std::time::{Duration, Instant};

#[derive(Debug, Clone, PartialEq)]
pub enum Status {
    Pass,
    Fail,
    Skip,
}

impl Status {
    #[allow(dead_code)]
    pub fn as_str(&self) -> &str {
        match self {
            Status::Pass => "PASS",
            Status::Fail => "FAIL",
            Status::Skip => "SKIP",
        }
    }
}

#[derive(Debug)]
pub struct ServiceResult {
    pub service: String,
    pub client: String,
    pub status: Status,
    pub detail: String,
    pub duration_ms: u128,
}

pub fn env_bool(name: &str, default: bool) -> bool {
    match env::var(name) {
        Ok(val) => {
            let lower = val.to_lowercase();
            matches!(lower.as_str(), "1" | "true" | "yes" | "on")
        }
        Err(_) => default,
    }
}

pub fn wait_for_port(host: &str, port: u16, timeout: Duration) -> bool {
    let deadline = Instant::now() + timeout;

    while Instant::now() < deadline {
        // to_socket_addrs() handles DNS resolution automatically
        match (host, port).to_socket_addrs() {
            Ok(mut addrs) => {
                if let Some(addr) = addrs.next() {
                    if TcpStream::connect_timeout(&addr, Duration::from_millis(500)).is_ok() {
                        return true;
                    }
                }
            }
            Err(_) => {
                // If DNS resolution fails, continue trying
            }
        }
        std::thread::sleep(Duration::from_millis(200));
    }
    false
}

pub fn skip_result(service: &str, client: &str, reason: &str) -> ServiceResult {
    ServiceResult {
        service: service.to_string(),
        client: client.to_string(),
        status: Status::Skip,
        detail: reason.to_string(),
        duration_ms: 0,
    }
}

pub fn fail_result(service: &str, client: &str, reason: &str) -> ServiceResult {
    ServiceResult {
        service: service.to_string(),
        client: client.to_string(),
        status: Status::Fail,
        detail: reason.to_string(),
        duration_ms: 0,
    }
}

pub fn run_check<F>(service: &str, client: &str, func: F) -> ServiceResult
where
    F: FnOnce() -> Result<String, Box<dyn std::error::Error>>,
{
    let start = Instant::now();
    match func() {
        Ok(detail) => ServiceResult {
            service: service.to_string(),
            client: client.to_string(),
            status: Status::Pass,
            detail,
            duration_ms: start.elapsed().as_millis(),
        },
        Err(e) => ServiceResult {
            service: service.to_string(),
            client: client.to_string(),
            status: Status::Fail,
            detail: e.to_string(),
            duration_ms: start.elapsed().as_millis(),
        },
    }
}

pub fn verify_service_gate(
    service: &str,
    client: &str,
    env_flag: &str,
    default_enabled: bool,
    host: &str,
    port: u16,
) -> Option<ServiceResult> {
    if !env_bool(env_flag, default_enabled) {
        return Some(skip_result(
            service,
            client,
            &format!("{}=false -> service intentionally disabled", env_flag),
        ));
    }

    if port > 0 && !wait_for_port(host, port, Duration::from_secs(2)) {
        return Some(fail_result(
            service,
            client,
            &format!("{}:{} is not reachable", host, port),
        ));
    }

    None
}

pub fn get_env(key: &str, default: &str) -> String {
    env::var(key).unwrap_or_else(|_| default.to_string())
}

pub fn get_env_u16(key: &str, default: u16) -> u16 {
    env::var(key)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}
