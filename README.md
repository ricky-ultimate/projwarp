# projwarp

A blazingly fast CLI tool to jump between your projects instantly. No more `cd`-ing through endless directories!

## Features

- **Lightning Fast**: Jump to any project with fuzzy matching
- **Simple**: Minimal commands, maximum productivity
- **Smart**: Auto-generates aliases from folder names
- **VS Code Integration**: Open projects directly in your editor
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Installation

### From Source

```bash
git clone https://github.com/ricky-ultimate/projwarp.git
cd projwarp
cargo build --release
```

Add the binary to your PATH:
- **Windows**: Copy `target/release/projwarp.exe` to a folder in your PATH
- **Unix**: Copy `target/release/projwarp` to `/usr/local/bin/` or `~/.local/bin/`

### PowerShell Setup (Windows)

Add this function to your PowerShell profile (`$PROFILE`):

```powershell
function proj {
    param(
        [Parameter(Position = 0)]
        [string]$name,
        [Parameter(Position = 1)]
        [string]$secondArg,
        [Parameter(Position = 2)]
        [string]$thirdArg,
        [switch]$code,
        [string]$alias
    )

    $previousOutputEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    try {
        if (-not $name) {
            Write-Host "Usage:" -ForegroundColor Cyan
            Write-Host "  proj add [-alias <n>]         Add current directory"
            Write-Host "  proj remove <alias>           Remove a project alias"
            Write-Host "  proj rename <old> <new>       Rename a project alias"
            Write-Host "  proj list                     List all projects"
            Write-Host "  proj <n> [-code]              Jump to project or open in VS Code"
            return
        }

        if ($name -eq "add") {
            if ($alias) {
                & projwarp add --alias $alias
            } else {
                & projwarp add
            }
            return
        }

        if ($name -eq "remove" -or $name -eq "rm") {
            if ($secondArg) {
                & projwarp remove $secondArg
            } elseif ($alias) {
                & projwarp remove $alias
            } else {
                Write-Host "Usage: proj remove <alias>" -ForegroundColor Yellow
            }
            return
        }

        if ($name -eq "rename" -or $name -eq "mv") {
            if ($thirdArg) {
                & projwarp rename $secondArg $thirdArg
            } elseif ($secondArg -and $alias) {
                & projwarp rename $secondArg $alias
            } else {
                Write-Host "Usage: proj rename <old> <new>" -ForegroundColor Yellow
            }
            return
        }

        if ($name -eq "list") {
            & projwarp list
            return
        }

        if ($code) {
            $output = & projwarp go $name 2>&1 | Out-String
            $output = $output.Trim()

            if ($output -and $output -notmatch "No match found") {
                if (Test-Path $output) {
                    & code $output
                    Write-Host "Opening '$output' in VS Code..." -ForegroundColor Green
                } else {
                    Write-Host "Path exists in config but not on disk: $output" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Project '$name' not found." -ForegroundColor Red
            }
        } else {
            $output = & projwarp go $name 2>&1 | Out-String
            $output = $output.Trim()

            if ($output -and $output -notmatch "No match found") {
                if (Test-Path $output) {
                    Set-Location $output
                    Write-Host "Jumped to: $output" -ForegroundColor Green
                } else {
                    Write-Host "Path exists in config but not on disk: $output" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Project '$name' not found." -ForegroundColor Red
            }
        }
    } finally {
        [Console]::OutputEncoding = $previousOutputEncoding
    }
}
```

Reload your profile:
```powershell
. $PROFILE
```

### Bash/Zsh Setup (Unix)

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

## 🔍 Fuzzy Matching

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

## 🛠️ Building from Source

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
