use clap::{Parser, Subcommand};

#[derive(Parser, Debug)]
#[command(name = "projwarp")]
#[command(author = "リッキー")]
#[command(version = "0.1")]
#[command(about = "Jump to projects quickly", long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    /// Add the current directory as a project
    Add {
        #[arg(short, long)]
        alias: Option<String>,
    },

    /// List all known projects
    List,

    /// Jump to a project directory (prints path to stdout)
    Go {
        name: String,
        /// Open in VS Code instead of cd
        #[arg(long)]
        code: bool,
    },

    /// Remove a project alias
    Remove { alias: String },
}
