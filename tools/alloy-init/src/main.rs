use std::env;
use std::process::{self, Command};

fn main() {
    let mut args = env::args().skip(1);
    let program = args.next().unwrap_or_else(|| "/bin/sh".to_string());
    let status = match Command::new(&program).args(args).status() {
        Ok(status) => status,
        Err(err) => {
            eprintln!("alloy-init: failed to exec {program}: {err}");
            process::exit(1);
        }
    };

    process::exit(status.code().unwrap_or(1));
}
