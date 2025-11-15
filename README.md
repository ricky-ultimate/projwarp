# projwarp

[![Crates.io](https://img.shields.io/crates/v/projwarp.svg)](https://crates.io/crates/projwarp)
[![Chocolatey](https://img.shields.io/chocolatey/v/projwarp.svg)](https://community.chocolatey.org/packages/projwarp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A blazingly fast CLI tool to jump between your projects instantly. No more `cd`-ing through endless directories!

## Features

- **Lightning Fast**: Jump to any project with fuzzy matching
- **Simple**: Minimal commands, maximum productivity
- **Smart**: Auto-generates aliases from folder names
- **VS Code Integration**: Open projects directly in your editor
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Installation

### Quick Install

Choose your preferred package manager:

```bash
# Cargo (Cross-platform)
cargo install projwarp

# Chocolatey (Windows)
choco install projwarp

```

### Build from Source

```bash
git clone https://github.com/ricky-ultimate/projwarp.git
cd projwarp
cargo build --release

# Run built-in installer
./target/release/projwarp install
```

The installer automatically:
- Installs the binary
- Adds to PATH
- Configures shell integration
- Sets up UTF-8 encoding

---

### Manual Installation

**Windows:**
```powershell
# After building with cargo
.\install.ps1
```

**Unix:**
```bash
# Copy to local bin
cp target/release/projwarp ~/.local/bin/
chmod +x ~/.local/bin/projwarp
```

Add this to your `.bashrc` or `.zshrc`:

```bash
proj() {
    if [ "$1" = "add" ]; then
        projwarp add "${@:2}"
    elif [ "$1" = "list" ]; then
        projwarp list
    elif [ "$1" = "remove" ] || [ "$1" = "rm" ]; then
        projwarp remove "$2"
    elif [ "$1" = "rename" ] || [ "$1" = "mv" ]; then
        projwarp rename "$2" "$3"
    elif [ "$2" = "--code" ]; then
        projwarp go "$1" --code
    else
        local output=$(projwarp go "$1" 2>&1)
        if [ $? -eq 0 ]; then
            cd "$output"
            echo "Jumped to: $output"
        else
            echo "$output"
        fi
    fi
}
```

## Uninstallation

To uninstall projwarp:

```bash
# Using built-in uninstaller
projwarp uninstall

# Or using PowerShell script (Windows)
.\install.ps1 -Uninstall
```

This will remove the binary, PATH entries, and optionally the configuration file.

## Usage

### Adding Projects

```bash
# Add current directory (auto-generates alias from folder name)
proj add

# Add with custom alias
proj add -alias myproject
```

### Listing Projects

```bash
proj list
# Output:
# myproject → /home/user/projects/myproject
# website → /home/user/sites/website
```

### Jumping to Projects

```bash
# Jump to a project (fuzzy matching!)
proj myproj        # Matches "myproject"
proj web           # Matches "website"
proj proj          # Matches "projwarp"

# Open in VS Code
proj myproject -code
```

### Managing Projects

```bash
# Remove a project
proj remove myproject
proj rm myproject           # Short alias

# Rename a project
proj rename oldname newname
proj mv oldname newname     # Short alias
```

## Fuzzy Matching

projwarp uses fuzzy matching, so you don't need to type the exact alias:

```bash
proj pw      # Matches "projwarp"
proj myweb   # Matches "my-website"
proj rust    # Matches "rust-learning"
```

## Configuration

Projects are stored in `~/.projwarp.json`:

```json
{
  "projects": {
    "projwarp": "D:\\リッキー\\Projects\\Rust\\projwarp",
    "website": "/home/user/sites/my-website"
  }
}
```

You can manually edit this file if needed.

## Building from Source

Requirements:
- Rust 1.70+ (edition 2021)

```bash
cargo build --release
```

The binary will be in `target/release/projwarp` (or `projwarp.exe` on Windows).

## Commands Reference

| Command | Alias | Description |
|---------|-------|-------------|
| `proj add [-alias <n>]` | - | Add current directory as a project |
| `proj list` | - | List all registered projects |
| `proj <name>` | - | Jump to a project directory |
| `proj <name> -code` | - | Open project in VS Code |
| `proj remove <alias>` | `proj rm` | Remove a project alias |
| `proj rename <old> <new>` | `proj mv` | Rename a project alias |

## Examples

```bash
# Workflow example
cd ~/projects/my-awesome-app
proj add -alias awesome          # Register the project

cd ~
proj awesome                     # Jump back instantly!

proj awesome -code               # Open in VS Code

proj rename awesome myapp        # Rename it
proj remove myapp                # Remove when done
```

## Inspiration

Inspired by tools like `z`, `autojump`, and `fasd`, but built with Rust for maximum speed and simplicity.

---

**Made with ❤️ by リッキー**
