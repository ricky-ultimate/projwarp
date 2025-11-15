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

# Installation Guide

## Windows Installation

### Method 1: Quick Install (One Command)

Open Terminal and run:

```powershell
irm https://raw.githubusercontent.com/ricky-ultimate/projwarp/master/quick-install.ps1 | iex
```

**Note:** If you get an error about execution policy, run Terminal as Administrator first, or use Method 2.

---

### Method 2: Manual Installation (Recommended for First-Time Users)

#### Step 1: Download
Go to [GitHub Releases](https://github.com/ricky-ultimate/projwarp/releases/latest) and download:
- `projwarp-vX.X.X-x86_64-pc-windows-msvc.zip`

#### Step 2: Extract
Right-click the ZIP file → **Extract All** → Choose a location (e.g., `Downloads\projwarp`)

#### Step 3: Install
Open Terminal in the extracted folder (Shift + Right-click → "Open Terminal window here") and run:

```powershell
# Unblock the script (important!)
Unblock-File -Path .\install.ps1

# Run the installer
.\install.ps1
```

**If you get an execution policy error:**
```powershell
# Option A: Run with bypass
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Option B: Allow scripts for your user (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

#### Step 4: Restart Terminal
Close and reopen Terminal to load the new configuration.

---

### Method 3: Chocolatey (Package Manager)

```powershell
choco install projwarp
```

---

## macOS/Linux Installation

### Using Pre-built Binary

1. Download the appropriate release:
   - **macOS (Intel):** `projwarp-vX.X.X-x86_64-apple-darwin.tar.gz`
   - **macOS (Apple Silicon):** `projwarp-vX.X.X-aarch64-apple-darwin.tar.gz`
   - **Linux:** `projwarp-vX.X.X-x86_64-unknown-linux-gnu.tar.gz`

2. Extract and install:
   ```bash
   tar -xzf projwarp-*.tar.gz
   cd projwarp-*/
   chmod +x projwarp
   sudo mv projwarp /usr/local/bin/
   ```

3. Add shell function to your profile (`~/.bashrc` or `~/.zshrc`):
   ```bash
   # projwarp - Project navigation tool
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

4. Reload your shell:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

---

## Installation from Source (Developers)

If you have Rust installed:

```bash
# Install from crates.io
cargo install projwarp

# Or build from source
git clone https://github.com/ricky-ultimate/projwarp.git
cd projwarp
cargo build --release

# On Windows
.\target\release\projwarp.exe install

# On macOS/Linux
./target/release/projwarp install
```

---

## Verification

After installation, verify everything works:

```powershell
# Check binary is accessible
projwarp --version

# Check shell function
proj

# Should show usage information
```

---

## Uninstallation

### Windows
```powershell
# If installed via Chocolatey
choco uninstall projwarp

# If installed manually
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall

# Or run the uninstaller from anywhere
projwarp uninstall
```

### macOS/Linux
```bash
sudo rm /usr/local/bin/projwarp
# Manually remove the proj() function from ~/.bashrc or ~/.zshrc
```

---

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
