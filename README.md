# Terminal Projector

A completely automated, OS-agnostic terminal multiplexer for pure aesthetic dopamine built in Python.
Renders localized weather, system stats, and animated ASCII art right in your terminal buffer —
cycling infinitely like a living wallpaper.

## Requirements

- Python 3.10+
- Rust / Cargo (auto-installed)
- A GPU-accelerated terminal — [Ghostty](https://ghostty.org) is strongly recommended

## Installation

Run the unified script — it auto-detects your OS and routes to the correct installer:

```bash
chmod +x install.sh
./install.sh
```

Or run the platform-specific installer directly:

| Platform     | Command                                                                |
|:------------ |:---------------------------------------------------------------------- |
| **macOS**    | `./install_mac.sh`                                                     |
| **Linux**    | `./install_linux.sh`                                                   |
| **Windows**  | `powershell -ExecutionPolicy Bypass -File install_windows.ps1`         |

### What each installer does

#### macOS (`install_mac.sh`)
- Verifies macOS 12+
- Installs Xcode CLI Tools if missing
- Installs / updates **Homebrew**
- Installs **Rust** via `rustup` if missing
- Installs all binaries via Homebrew: `fastfetch`, `btop`, `cbonsai`, `cmatrix`, `lolcat`
- Compiles **weathr** via Cargo
- Detects terminal emulator; offers to install **Ghostty** if not present with per-terminal fallback advice

#### Ubuntu / Debian (`install_linux.sh`)
- Detects distro and verifies Debian/Ubuntu lineage
- Installs build dependencies via `apt`
- Installs **Rust** via `rustup` if missing
- Installs `fastfetch` from PPA or GitHub release
- Installs `btop` from apt or GitHub binary
- Builds `cbonsai` from source if not in apt
- Installs `cmatrix`, `lolcat` via apt / gem / pip fallback chain
- Detects terminal; offers to install **Ghostty** via .deb if not present
- Optionally installs a **systemd user service** for auto-launch at login

#### Windows (`install_windows.ps1`)
- Detects/installs package manager: **winget → scoop → choco** (in priority order)
- Installs **Python 3.12** and **Rust** via `rustup-init.exe`
- Installs `fastfetch`, `btop`, `lolcat`, `cmatrix`, `cbonsai` via available package manager
- Detects terminal: **Ghostty**, Windows Terminal, ConEmu, PowerShell host
- Offers to install **Ghostty** via winget or MSI release
- Creates a `projector.bat` shim for easy launching

## Usage

```bash
./projector.py
# or
python3 projector.py
# Windows:
python projector.py
```

## Configuration

The config is auto-generated on first run at:
- **macOS/Linux:** `~/.config/projector/config.json`
- **Windows:** `%APPDATA%\projector\config.json`

Edit it to add/remove scenes, adjust durations, or swap commands. Changes take effect on next launch.

### Default Scene Rotation

| Scene                  | Duration | Type   |
|:-----------------------|:--------:|:------:|
| `weathr`               | 30s      | daemon |
| `fastfetch \| lolcat`  | 10s      | run    |
| `btop`                 | 30s      | daemon |
| `cbonsai --live`       | 20s      | run    |
| `cmatrix -s`           | 30s      | daemon |

## Terminal Recommendation

**Ghostty** is the ideal host. It offers:
- Native GPU compositing
- Precise ANSI / true-colour support
- Click-through and transparency options for wallpaper pinning

Install from [ghostty.org](https://ghostty.org) or let the installer do it for you.
