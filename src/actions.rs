use crate::{cli::Command, config::Config, fuzzy::find_match};
use anyhow::Result;
use colored::*;
use std::env;
use std::io::{self, Write};

pub fn handle_action(args: crate::cli::Cli) -> Result<()> {
    let mut cfg = Config::load();

    match args.command {
        Command::Add { alias } => {
            let dir = env::current_dir()?.to_string_lossy().to_string();
            let alias = alias.unwrap_or_else(|| {
                dir.split(['/', '\\'])
                    .last()
                    .unwrap_or("unknown")
                    .chars()
                    .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
                    .collect::<String>()
            });

            cfg.projects.insert(alias.clone(), dir);
            cfg.save();
            println!("Added project alias: {}", alias.green());
        }

        Command::List => {
            for (alias, path) in &cfg.projects {
                println!("{} → {}", alias.yellow(), path);
            }
        }

        Command::Go { name, code } => {
            if let Some(path) = find_match(&cfg, &name) {
                if code {
                    let status = std::process::Command::new("code").arg(&path).status()?;

                    if !status.success() {
                        eprintln!(
                            "Failed to open VS Code. Make sure 'code' command is in your PATH."
                        );
                    }
                } else {
                    let stdout = io::stdout();
                    let mut handle = stdout.lock();
                    writeln!(handle, "{}", path)?;
                    handle.flush()?;
                }
            } else {
                eprintln!("No match found for '{}'", name.red());
            }
        }
    }

    Ok(())
}
