use super::Block;
use crate::errors::BlockError;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

pub struct Battery {
    format_charging: String,
    format_discharging: String,
    format_full: String,
    interval: Duration,
    color: u32,
    battery_path: String,
}

fn detect_battery_name() -> Option<String> {
    let base = Path::new("/sys/class/power_supply");
    let entries = fs::read_dir(base).ok()?;

    for entry in entries.flatten() {
        let path: PathBuf = entry.path();

        let type_path = path.join("type");
        let present_path = path.join("present");

        let is_battery = fs::read_to_string(&type_path)
            .map(|s| s.trim() == "Battery")
            .unwrap_or(false);

        let is_present = fs::read_to_string(&present_path)
            .map(|s| s.trim() == "1")
            .unwrap_or(true);

        let is_device_scope = fs::read_to_string(path.join("scope"))
            .map(|s| s.trim().eq_ignore_ascii_case("device"))
            .unwrap_or(false);

        if !is_battery || !is_present || is_device_scope {
            continue;
        }

        if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
            return Some(name.to_string());
        }
    }
    None
}

impl Battery {
    pub fn new(
        format_charging: &str,
        format_discharging: &str,
        format_full: &str,
        interval_secs: u64,
        color: u32,
        battery_name: Option<String>,
    ) -> Self {
        let name = battery_name
            .or_else(detect_battery_name)
            .unwrap_or_else(|| "BAT0".to_string());

        Self {
            format_charging: format_charging.to_string(),
            format_discharging: format_discharging.to_string(),
            format_full: format_full.to_string(),
            interval: Duration::from_secs(interval_secs),
            color,
            battery_path: format!("/sys/class/power_supply/{}", name),
        }
    }

    fn read_file(&self, filename: &str) -> Result<String, BlockError> {
        let path = format!("{}/{}", self.battery_path, filename);
        Ok(fs::read_to_string(path)?.trim().to_string())
    }

    fn get_capacity(&self) -> Result<u32, BlockError> {
        Ok(self.read_file("capacity")?.parse()?)
    }

    fn get_status(&self) -> Result<String, BlockError> {
        self.read_file("status")
    }
}

impl Block for Battery {
    fn content(&mut self) -> Result<String, BlockError> {
        let capacity = self.get_capacity()?;
        let status = self.get_status()?;

        let format = match status.as_str() {
            "Charging" => &self.format_charging,
            "Full" => &self.format_full,
            _ => &self.format_discharging,
        };

        Ok(format.replace("{}", &capacity.to_string()))
    }

    fn interval(&self) -> Duration {
        self.interval
    }

    fn color(&self) -> u32 {
        self.color
    }
}
