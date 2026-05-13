use super::Block;
use crate::errors::BlockError;
use std::fs;
use std::time::Duration;

pub struct Cpu {
    format: String,
    interval: Duration,
    color: u32,
    prev_idle: u64,
    prev_total: u64,
}

impl Cpu {
    pub fn new(format: &str, interval_secs: u64, color: u32) -> Self {
        Self {
            format: format.to_string(),
            interval: Duration::from_secs(interval_secs),
            color,
            prev_idle: 0,
            prev_total: 0,
        }
    }

    fn get_cpu_usage(&mut self) -> Result<f32, BlockError> {
        let stat = fs::read_to_string("/proc/stat")?;
        
        // Primeira linha contém: cpu  user nice system idle iowait irq softirq...
        let cpu_line = stat
            .lines()
            .find(|line| line.starts_with("cpu "))
            .ok_or_else(|| BlockError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "CPU line not found in /proc/stat"
            )))?;

        let values: Vec<u64> = cpu_line
            .split_whitespace()
            .skip(1) // Skip "cpu"
            .filter_map(|s: &str| s.parse::<u64>().ok())
            .collect();

        if values.len() < 4 {
            return Err(BlockError::Io(std::io::Error::new(
                std::io::ErrorKind::InvalidData,
                "Invalid CPU values in /proc/stat"
            )));
        }

        // Calcular tempos totais
        let idle = values[3]; // idle time
        let iowait = values.get(4).unwrap_or(&0); // iowait time
        let total: u64 = values.iter().sum();

        let idle_total = idle + iowait;

        // Calcular diferenças desde a última leitura
        let idle_delta = idle_total.saturating_sub(self.prev_idle);
        let total_delta = total.saturating_sub(self.prev_total);

        // Guardar valores atuais para próxima iteração
        self.prev_idle = idle_total;
        self.prev_total = total;

        // Calcular percentagem de uso
        let usage = if total_delta > 0 {
            let active_delta = total_delta.saturating_sub(idle_delta);
            (active_delta as f32 / total_delta as f32) * 100.0
        } else {
            0.0
        };

        Ok(usage)
    }
}

impl Block for Cpu {
    fn content(&mut self) -> Result<String, BlockError> {
        let usage = self.get_cpu_usage()?;

        let result = self
            .format
            .replace("{}", &format!("{:.0}", usage))
            .replace("{percent}", &format!("{:.1}", usage))
            .replace("{usage}", &format!("{:.0}", usage));

        Ok(result)
    }

    fn interval(&self) -> Duration {
        self.interval
    }

    fn color(&self) -> u32 {
        self.color
    }
}
