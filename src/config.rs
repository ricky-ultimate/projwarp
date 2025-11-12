use serde::{Serialize, Deserialize};
use std::{collections::HashMap, fs, path::PathBuf};
use dirs::home_dir;

#[derive(Serialize, Deserialize, Default)]
pub struct Config {
    pub projects: HashMap<String, String>,
}

impl Config {
    pub fn path() -> PathBuf {
        home_dir().unwrap().join(".projwarp.json")
    }

    pub fn load() -> Self {
        let path = Self::path();
        if path.exists() {
            let data = fs::read_to_string(&path).unwrap_or_default();
            serde_json::from_str(&data).unwrap_or_default()
        } else {
            Self::default()
        }
    }

    pub fn save(&self) {
        let data = serde_json::to_string_pretty(self).unwrap();
        fs::write(Self::path(), data).unwrap();
    }
}
