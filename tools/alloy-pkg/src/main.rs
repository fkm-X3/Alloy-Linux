use std::env;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;
use std::process::{self, Command};
use std::time::{SystemTime, UNIX_EPOCH};

fn usage() {
    eprintln!("Usage: alloy-pkg install <rootfs> <pkg-tar.gz>");
}

fn unix_timestamp() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or(0)
}

fn install_package(rootfs: &Path, pkg_tarball: &Path) -> Result<(), String> {
    if !rootfs.is_dir() {
        return Err(format!("rootfs path is not a directory: {}", rootfs.display()));
    }
    if !pkg_tarball.is_file() {
        return Err(format!(
            "package tarball not found: {}",
            pkg_tarball.display()
        ));
    }

    let status = Command::new("tar")
        .arg("-xzf")
        .arg(pkg_tarball)
        .arg("-C")
        .arg(rootfs)
        .status()
        .map_err(|err| format!("failed to invoke tar: {err}"))?;

    if !status.success() {
        return Err("tar extraction failed".to_string());
    }

    let db_dir = rootfs.join("var/lib/alloy-pkgs");
    fs::create_dir_all(&db_dir).map_err(|err| format!("failed to create package db dir: {err}"))?;
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(db_dir.join("installed.txt"))
        .map_err(|err| format!("failed to open installed db: {err}"))?;

    let pkg_name = pkg_tarball
        .file_name()
        .map(|name| name.to_string_lossy().to_string())
        .unwrap_or_else(|| pkg_tarball.display().to_string());
    writeln!(file, "{} | {}", pkg_name, unix_timestamp())
        .map_err(|err| format!("failed to write package db entry: {err}"))?;

    Ok(())
}

fn main() {
    let mut args = env::args().skip(1);
    let command = match args.next() {
        Some(command) => command,
        None => {
            usage();
            process::exit(2);
        }
    };

    if command != "install" {
        usage();
        process::exit(2);
    }

    let rootfs = match args.next() {
        Some(rootfs) => rootfs,
        None => {
            usage();
            process::exit(2);
        }
    };
    let package = match args.next() {
        Some(package) => package,
        None => {
            usage();
            process::exit(2);
        }
    };

    if let Err(err) = install_package(Path::new(&rootfs), Path::new(&package)) {
        eprintln!("alloy-pkg: {err}");
        process::exit(1);
    }
}
