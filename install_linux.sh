#!/usr/bin/env bash
# =============================================================================
#  Terminal Projector - Ubuntu / Debian Linux Installer
#  Handles: apt, snap fallbacks, Rust/Cargo
# =============================================================================

set -euo pipefail

# Force a standard terminal type to prevent "unknown terminal type" errors
# from installers/commands if the user is running from an exotic terminal
export TERM=xterm-256color

# ── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}[✔] ${1}${RESET}"; }
info() { echo -e "${CYAN}[*] ${1}${RESET}"; }
warn() { echo -e "${YELLOW}[!] ${1}${RESET}"; }
die()  { echo -e "${RED}[✘] FATAL: ${1}${RESET}" >&2; exit 1; }

# ── Header ───────────────────────────────────────────────────────────────────
clear 2>/dev/null || printf '\033[2J\033[H'
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
  ┌──────────────────────────────────────────────────┐
  │   Terminal Projector – Ubuntu / Debian Installer  │
  └──────────────────────────────────────────────────┘
EOF
echo -e "${RESET}"

# ── OS Gate ──────────────────────────────────────────────────────────────────
if [[ ! -f /etc/os-release ]]; then
  die "Could not detect OS. This script targets Ubuntu/Debian."
fi
# shellcheck source=/dev/null
source /etc/os-release
case "$ID" in
  ubuntu|debian|linuxmint|pop|elementary|zorin|kali)
    ok "Detected OS: ${PRETTY_NAME}"
    ;;
  *)
    warn "This script is written for Ubuntu/Debian-based systems."
    warn "Detected: ${PRETTY_NAME}. Attempting to continue anyway..."
    ;;
esac

# ── sudo check ────────────────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
  SUDO=""
  warn "Running as root – dropping sudo prefix."
else
  if ! command -v sudo &>/dev/null; then
    die "sudo is not installed and you are not root. Cannot proceed."
  fi
  SUDO="sudo"
fi

# ── apt update ───────────────────────────────────────────────────────────────
info "Refreshing apt package list..."
$SUDO apt-get update -qq

# ── Core build tools ─────────────────────────────────────────────────────────
APT_DEPS=(
  curl wget git build-essential
  python3 python3-pip python3-venv
  libssl-dev pkg-config
  libncurses5-dev libncursesw5-dev
  libglib2.0-dev
)
info "Installing build dependencies..."
$SUDO apt-get install -y -qq "${APT_DEPS[@]}"
ok "Build dependencies installed"

# ── Python version check ─────────────────────────────────────────────────────
PYTHON=$(command -v python3)
PY_VER=$("$PYTHON" --version 2>&1 | awk '{print $2}')
PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
if [[ "$PY_MAJOR" -lt 3 || ( "$PY_MAJOR" -eq 3 && "$PY_MINOR" -lt 10 ) ]]; then
  info "Python 3.10+ required (found ${PY_VER}). Adding deadsnakes PPA..."
  $SUDO apt-get install -y -qq software-properties-common
  $SUDO add-apt-repository -y ppa:deadsnakes/ppa
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq python3.12 python3.12-venv
  PYTHON=$(command -v python3.12)
  ok "Python 3.12 installed"
else
  ok "Python ${PY_VER} is sufficient"
fi

# ── Rust / Cargo ─────────────────────────────────────────────────────────────
if command -v cargo &>/dev/null; then
  ok "Rust $(rustc --version | awk '{print $2}') already installed"
else
  warn "Rust not found. Installing via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  ok "Rust installed"
fi
export PATH="$HOME/.cargo/bin:$PATH"

# ── weathr (Cargo) ────────────────────────────────────────────────────────────
if command -v weathr &>/dev/null; then
  ok "weathr already installed"
else
  info "Compiling weathr via Cargo (this may take a few minutes)..."
  cargo install weathr
  ok "weathr installed"
fi

# ── fastfetch ─────────────────────────────────────────────────────────────────
install_fastfetch() {
  if command -v fastfetch &>/dev/null; then
    ok "fastfetch already installed"
    return
  fi
  # Try the official PPA first (Ubuntu 23+)
  if $SUDO add-apt-repository -y ppa:zhangsongcui3371/fastfetch 2>/dev/null; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq fastfetch && ok "fastfetch installed (apt)" && return
  fi
  # Fallback: download latest release binary from GitHub
  warn "Falling back to GitHub binary release for fastfetch..."
  LATEST=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
    | grep "browser_download_url.*linux-amd64.deb" | cut -d\" -f4 | head -1)
  if [[ -n "$LATEST" ]]; then
    curl -L "$LATEST" -o /tmp/fastfetch.deb
    $SUDO dpkg -i /tmp/fastfetch.deb
    rm -f /tmp/fastfetch.deb
    ok "fastfetch installed (deb)"
  else
    warn "Could not auto-install fastfetch. Install manually from: https://github.com/fastfetch-cli/fastfetch"
  fi
}
install_fastfetch

# ── apt packages (main payload) ───────────────────────────────────────────────
# btop is in apt since Ubuntu 22.10; otherwise build from source
install_btop() {
  if command -v btop &>/dev/null; then ok "btop already installed"; return; fi
  if $SUDO apt-get install -y -qq btop 2>/dev/null; then
    ok "btop installed (apt)"
  else
    warn "btop not in apt. Downloading binary from GitHub..."
    LATEST=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest \
      | grep "browser_download_url.*x86_64-linux-musl" | grep ".tbz" | cut -d\" -f4 | head -1)
    curl -L "$LATEST" -o /tmp/btop.tbz
    tar -xjf /tmp/btop.tbz -C /tmp
    $SUDO /tmp/btop/install.sh
    rm -rf /tmp/btop /tmp/btop.tbz
    ok "btop installed (binary)"
  fi
}
install_btop

# cmatrix
if command -v cmatrix &>/dev/null; then
  ok "cmatrix already installed"
else
  $SUDO apt-get install -y -qq cmatrix && ok "cmatrix installed"
fi

# lolcat
if command -v lolcat &>/dev/null; then
  ok "lolcat already installed"
else
  # lolcat is available as a gem; fallback to pip version
  if command -v gem &>/dev/null; then
    $SUDO gem install lolcat && ok "lolcat installed (gem)"
  else
    pip3 install --quiet lolcat && ok "lolcat installed (pip)"
  fi
fi

# cbonsai
install_cbonsai() {
  if command -v cbonsai &>/dev/null; then ok "cbonsai already installed"; return; fi
  # Available in Ubuntu 22.04+ universe
  if $SUDO apt-get install -y -qq cbonsai 2>/dev/null; then
    ok "cbonsai installed (apt)"
  else
    warn "cbonsai not in apt. Building from source..."
    $SUDO apt-get install -y -qq libncursesw5-dev
    TMP_DIR=$(mktemp -d)
    git clone --depth=1 https://gitlab.com/jallbrit/cbonsai.git "$TMP_DIR"
    make -C "$TMP_DIR"
    $SUDO make -C "$TMP_DIR" install
    rm -rf "$TMP_DIR"
    ok "cbonsai installed (source)"
  fi
}
install_cbonsai

# ── Terminal Check ───────────────────────────────────────────────────────────
echo ""
info "Checking terminal emulator..."

detect_terminal() {
  if [[ -n "${KITTY_PID:-}" ]]; then echo "kitty"; return; fi
  if [[ -n "${ALACRITTY_SOCKET:-}" ]]; then echo "alacritty"; return; fi
  if [[ -n "${WEZTERM_EXECUTABLE:-}" ]]; then echo "wezterm"; return; fi
  echo "${TERM_PROGRAM:-${LC_TERMINAL:-${TERM:-unknown}}}"
}

CURRENT_TERM=$(detect_terminal)

if [[ "$CURRENT_TERM" == "kitty" || "$CURRENT_TERM" == "alacritty" ]]; then
  ok "GPU-accelerated terminal (${CURRENT_TERM}) detected – ideal environment"
else
  warn "Terminal detected: ${CURRENT_TERM}"
  echo ""
  echo -e "${YELLOW}  For best performance on Linux, a GPU-accelerated terminal is recommended.${RESET}"
  echo "  (e.g., Kitty or Alacritty)"
  echo ""
  
  case "$CURRENT_TERM" in
    xterm*|vte*|gnome-terminal)
      warn "Legacy/standard terminal detected. Animations may be choppy."
      warn "Consider installing Kitty: sudo apt install kitty"
      ;;
    *)
      # No specific adjustments
      ;;
  esac
fi

# ── Persistence: optional systemd unit ───────────────────────────────────────
echo ""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/projector.py"

read -rp "  Create a systemd user service to auto-launch on login? [y/N] " CREATE_SERVICE
if [[ "$CREATE_SERVICE" =~ ^[Yy]$ ]]; then
  UNIT_DIR="$HOME/.config/systemd/user"
  mkdir -p "$UNIT_DIR"
  cat > "$UNIT_DIR/terminal-projector.service" << EOF
[Unit]
Description=Terminal Projector
After=graphical-session.target

[Service]
ExecStart=${PYTHON} ${SCRIPT_DIR}/projector.py
Restart=on-failure
Environment=TERM=xterm-256color

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable terminal-projector.service
  ok "Systemd service enabled – will auto-start at next login"
  info "Control with: systemctl --user start/stop/status terminal-projector"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Installation complete!${RESET}"
echo -e "${GREEN}  Launch with: ${BOLD}./projector.py${RESET}"
echo -e "${GREEN}  Config at:   ${BOLD}~/.config/projector/config.json${RESET}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
