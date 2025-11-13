mod actions;
mod cli;
mod config;
mod fuzzy;
mod installer;

use cli::Cli;
use clap::Parser;
use actions::handle_action;


fn main() {
    let args = Cli::parse();
    if let Err(e) = handle_action(args) {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}
