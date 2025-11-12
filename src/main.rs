mod cli;
mod config;
mod actions;
mod fuzzy;

use cli::Cli;
use clap::Parser;
use actions::handle_action;

fn main() {
    let args = Cli::parse();
    if let Err(e) = handle_action(args) {
        eprintln!("Error: {e}");
    }
}
