mod tests;
mod utils;

use tests::*;
use utils::{ServiceResult, Status};

const COLOR_RESET: &str = "\x1b[0m";
const COLOR_GREEN: &str = "\x1b[32m";
const COLOR_RED: &str = "\x1b[31m";
const COLOR_YELLOW: &str = "\x1b[33m";

fn print_result(result: &ServiceResult) {
    let (color, symbol) = match result.status {
        Status::Pass => (COLOR_GREEN, "✓"),
        Status::Fail => (COLOR_RED, "✗"),
        Status::Skip => (COLOR_YELLOW, "⊘"),
    };

    println!(
        "{}[{}] {:15} via {:20} ({:4} ms) -> {}{}",
        color,
        symbol,
        result.service,
        result.client,
        result.duration_ms,
        result.detail,
        COLOR_RESET
    );
}

fn main() {
    println!("==========================================");
    println!("Rust Service Connectivity Tests");
    println!("==========================================");
    println!();

    // Run all tests
    let results = vec![
        postgres::test_postgres(),
        mysql::test_mysql(),
        valkey::test_valkey(),
        kafka::test_kafka(),
        opensearch::test_opensearch(),
        minio::test_minio(),
    ];

    // Print results
    for result in &results {
        print_result(result);
    }

    // Summary
    let passed = results.iter().filter(|r| r.status == Status::Pass).count();
    let failed = results.iter().filter(|r| r.status == Status::Fail).count();
    let skipped = results.iter().filter(|r| r.status == Status::Skip).count();

    println!();
    println!("==========================================");
    println!("Summary: {} passed, {} failed, {} skipped", passed, failed, skipped);
    println!("==========================================");

    if failed > 0 {
        std::process::exit(1);
    }
}
