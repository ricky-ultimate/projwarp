use anyhow::{Context, Result};
use colored::*;
use std::env;
use std::fs;
use std::path::PathBuf;

const PROJ_FUNCTION: &str = r#"
# projwarp - Project navigation tool
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
"#;

pub fn install() -> Result<()> {
    println!("{}", "🚀 Installing projwarp...".cyan());

    // Get the current executable path
    let exe_path = env::current_exe().context("Failed to get executable path")?;

    #[cfg(target_os = "windows")]
    {
        install_windows(&exe_path)?;
    }

    #[cfg(not(target_os = "windows"))]
    {
        install_unix(&exe_path)?;
    }

    println!("\n{}", "Installation complete!".green().bold());
    println!("\n{}", "To start using projwarp:".cyan());
    println!("  1. Restart your terminal");
    println!("  2. Navigate to a project directory");
    println!("  3. Run: proj add");
    println!("  4. From anywhere: proj <project-name>");
    println!("\nRun 'proj' for help");

    Ok(())
}

#[cfg(target_os = "windows")]
fn install_windows(exe_path: &PathBuf) -> Result<()> {
    use std::process::Command;

    // Install directory
    let local_app_data = env::var("LOCALAPPDATA").context("LOCALAPPDATA not found")?;
    let install_dir = PathBuf::from(local_app_data).join("projwarp");
    let target_path = install_dir.join("projwarp.exe");

    // Create directory
    fs::create_dir_all(&install_dir).context("Failed to create install directory")?;
    println!("{} Created installation directory", "✓".green());

    // Copy binary
    fs::copy(exe_path, &target_path).context("Failed to copy binary")?;
    println!(
        "{} Installed binary to: {}",
        "✓".green(),
        target_path.display()
    );

    // Add to PATH (requires admin or user PATH modification)
    let ps_script = format!(
        r#"
        $installDir = '{}'
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -notlike "*$installDir*") {{
            [Environment]::SetEnvironmentVariable('Path', "$userPath;$installDir", 'User')
            Write-Host 'Added to PATH'
        }} else {{
            Write-Host 'Already in PATH'
        }}
        "#,
        install_dir.display()
    );

    Command::new("powershell")
        .args(["-NoProfile", "-Command", &ps_script])
        .status()
        .context("Failed to update PATH")?;

    // Setup PowerShell profile
    setup_powershell_profile()?;

    Ok(())
}

#[cfg(not(target_os = "windows"))]
fn install_unix(exe_path: &PathBuf) -> Result<()> {
    let home = env::var("HOME").context("HOME not found")?;
    let install_dir = PathBuf::from(&home).join(".local").join("bin");
    let target_path = install_dir.join("projwarp");

    // Create directory
    fs::create_dir_all(&install_dir).context("Failed to create install directory")?;
    println!("{} Created installation directory", "✓".green());

    // Copy binary
    fs::copy(exe_path, &target_path).context("Failed to copy binary")?;

    // Make executable
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(&target_path)?.permissions();
        perms.set_mode(0o755);
        fs::set_permissions(&target_path, perms)?;
    }

    println!(
        "{} Installed binary to: {}",
        "✓".green(),
        target_path.display()
    );

    // Setup shell profile
    setup_unix_profile(&home)?;

    Ok(())
}

#[cfg(target_os = "windows")]
fn setup_powershell_profile() -> Result<()> {
    use std::process::Command;

    let profile_script = format!(
        r#"
        $profilePath = $PROFILE
        if (-not (Test-Path $profilePath)) {{
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
            Write-Host 'Created PowerShell profile'
        }}

        $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        if ($content -like '*function proj*') {{
            Write-Host 'proj function already exists in profile'
        }} else {{
            Add-Content $profilePath @'
{}
'@
            Write-Host 'Added proj function to profile'
        }}
        "#,
        PROJ_FUNCTION
    );

    Command::new("powershell")
        .args(["-NoProfile", "-Command", &profile_script])
        .status()
        .context("Failed to setup PowerShell profile")?;

    Ok(())
}

#[cfg(not(target_os = "windows"))]
fn setup_unix_profile(home: &str) -> Result<()> {
    let bashrc = PathBuf::from(home).join(".bashrc");
    let zshrc = PathBuf::from(home).join(".zshrc");

    let function_content = r#"
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
"#;

    // Try .bashrc first
    if bashrc.exists() {
        let content = fs::read_to_string(&bashrc)?;
        if !content.contains("function proj") {
            fs::write(&bashrc, format!("{}\n{}", content, function_content))?;
            println!("{} Added to .bashrc", "✓".green());
        }
    }

    // Then try .zshrc
    if zshrc.exists() {
        let content = fs::read_to_string(&zshrc)?;
        if !content.contains("proj()") {
            fs::write(&zshrc, format!("{}\n{}", content, function_content))?;
            println!("{} Added to .zshrc", "✓".green());
        }
    }

    Ok(())
}

pub fn uninstall() -> Result<()> {
    println!("{}", "Uninstalling projwarp...".cyan());

    #[cfg(target_os = "windows")]
    {
        uninstall_windows()?;
    }

    #[cfg(not(target_os = "windows"))]
    {
        uninstall_unix()?;
    }

    println!("\n{}", "Uninstallation complete!".green());
    println!("Please restart your terminal for changes to take effect");

    Ok(())
}

#[cfg(target_os = "windows")]
fn uninstall_windows() -> Result<()> {
    let local_app_data = env::var("LOCALAPPDATA").context("LOCALAPPDATA not found")?;
    let install_dir = PathBuf::from(local_app_data).join("projwarp");

    // Remove binary
    if install_dir.exists() {
        fs::remove_dir_all(&install_dir)?;
        println!("{} Removed installation directory", "✓".green());
    }

    println!("Note: Please manually remove projwarp from your PowerShell profile if desired");

    Ok(())
}

#[cfg(not(target_os = "windows"))]
fn uninstall_unix() -> Result<()> {
    let home = env::var("HOME").context("HOME not found")?;
    let binary_path = PathBuf::from(&home)
        .join(".local")
        .join("bin")
        .join("projwarp");

    if binary_path.exists() {
        fs::remove_file(&binary_path)?;
        println!("{} Removed binary", "✓".green());
    }

    println!("Note: Please manually remove proj function from your shell profile if desired");

    Ok(())
}
