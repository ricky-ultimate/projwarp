use crate::{cli::Command, config::Config, fuzzy::find_match, installer};
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
            if cfg.projects.is_empty() {
                println!("{}", "No projects registered yet!".yellow());
                println!("Run 'proj add' in a project directory to get started");
            } else {
                for (alias, path) in &cfg.projects {
                    println!("{} → {}", alias.yellow(), path);
                }
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

        Command::Remove { alias } => {
            if cfg.projects.remove(&alias).is_some() {
                cfg.save();
                println!("Removed alias '{}'", alias.green());
            } else {
                println!("Alias '{}' not found", alias.red());
            }
        }

        Command::Rename { old, new } => {
            if let Some(path) = cfg.projects.remove(&old) {
                cfg.projects.insert(new.clone(), path);
                cfg.save();
                println!("Renamed '{}' → '{}'", old.yellow(), new.green());
            } else {
                println!("Alias '{}' not found", old.red());
            }
        }

        Command::Install => {
            installer::install()?;
        }

        Command::Uninstall => {
            installer::uninstall()?;
        }
    }

    Ok(())
}
