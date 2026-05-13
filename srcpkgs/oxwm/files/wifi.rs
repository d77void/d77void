use super::Block;
use crate::errors::BlockError;
use std::fs;
use std::process::Command;
use std::time::Duration;

pub struct Wifi {
    format: String,
    interval: Duration,
    color: u32,
    interface: Option<String>,
}

fn detect_wifi_interface() -> Option<String> {
    // Método 1: Procurar em /sys/class/net por interfaces com diretório wireless
    if let Ok(entries) = fs::read_dir("/sys/class/net") {
        for entry in entries.flatten() {
            if let Some(name) = entry.file_name().to_str() {
                let wireless_path = entry.path().join("wireless");
                if wireless_path.exists() {
                    return Some(name.to_string());
                }
            }
        }
    }
    
    // Método 2: Usar iw dev para encontrar interfaces
    if let Ok(output) = Command::new("sh")
        .arg("-c")
        .arg("iw dev | grep Interface | awk '{print $2}' | head -n1")
        .output()
    {
        if output.status.success() {
            if let Ok(iface) = String::from_utf8(output.stdout) {
                let iface = iface.trim();
                if !iface.is_empty() {
                    return Some(iface.to_string());
                }
            }
        }
    }
    
    // Método 3: Ler /proc/net/wireless
    if let Ok(content) = fs::read_to_string("/proc/net/wireless") {
        for line in content.lines().skip(2) {
            if !line.trim().is_empty() {
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 2 {
                    let iface = parts[0].trim();
                    if !iface.is_empty() {
                        return Some(iface.to_string());
                    }
                }
            }
        }
    }
    
    None
}

impl Wifi {
    pub fn new(format: &str, interval_secs: u64, color: u32, interface: Option<String>) -> Self {
        Self {
            format: format.to_string(),
            interval: Duration::from_secs(interval_secs),
            color,
            interface,
        }
    }

    fn get_interface(&self) -> String {
        self.interface
            .clone()
            .or_else(detect_wifi_interface)
            .unwrap_or_else(|| "wlan0".to_string())
    }

    fn get_ssid(&self) -> Result<String, BlockError> {
        let iface = self.get_interface();
        
        // Método 1: iwgetid (mais comum)
        if let Ok(output) = Command::new("iwgetid")
            .arg(&iface)
            .arg("-r")
            .output()
        {
            if output.status.success() {
                if let Ok(ssid) = String::from_utf8(output.stdout) {
                    let ssid = ssid.trim().to_string();
                    if !ssid.is_empty() {
                        return Ok(ssid);
                    }
                }
            }
        }

        // Método 2: iw dev
        if let Ok(output) = Command::new("sh")
            .arg("-c")
            .arg(format!("iw dev {} link | grep SSID | awk '{{print $2}}'", iface))
            .output()
        {
            if output.status.success() {
                if let Ok(ssid) = String::from_utf8(output.stdout) {
                    let ssid = ssid.trim().to_string();
                    if !ssid.is_empty() {
                        return Ok(ssid);
                    }
                }
            }
        }

        // Método 3: nmcli (NetworkManager)
        if let Ok(output) = Command::new("sh")
            .arg("-c")
            .arg("nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2")
            .output()
        {
            if output.status.success() {
                if let Ok(ssid) = String::from_utf8(output.stdout) {
                    let ssid = ssid.trim().to_string();
                    if !ssid.is_empty() {
                        return Ok(ssid);
                    }
                }
            }
        }

        Err(BlockError::CommandFailed("Not connected".to_string()))
    }

    fn get_signal_quality(&self) -> Result<i32, BlockError> {
        let iface = self.get_interface();
        let wireless = fs::read_to_string("/proc/net/wireless")?;
        
        for line in wireless.lines().skip(2) {
            if line.contains(&iface) {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 3 {
                    let quality_str = parts[2].trim_end_matches('.');
                    let quality: f32 = quality_str.parse()
                        .map_err(|_| BlockError::InvalidData("Invalid quality value".to_string()))?;
                    
                    // Converter para percentagem (0-70 -> 0-100)
                    let percentage = ((quality / 70.0) * 100.0).round() as i32;
                    let percentage = percentage.max(0).min(100);
                    return Ok(percentage);
                }
            }
        }
        
        Err(BlockError::InvalidData("Interface not found".to_string()))
    }
}

impl Block for Wifi {
    fn content(&mut self) -> Result<String, BlockError> {
        match self.get_ssid() {
            Ok(ssid) => {
                let quality = self.get_signal_quality().unwrap_or(0);

                let result = self
                    .format
                    .replace("{ssid}", &ssid)
                    .replace("{quality}", &quality.to_string())
                    .replace("{}", &format!("{} {}%", ssid, quality));

                Ok(result)
            }
            Err(_) => {
                let result = self
                    .format
                    .replace("{ssid}", "Disconnected")
                    .replace("{quality}", "0")
                    .replace("{}", "Disconnected");
                
                Ok(result)
            }
        }
    }

    fn interval(&self) -> Duration {
        self.interval
    }

    fn color(&self) -> u32 {
        self.color
    }
}
