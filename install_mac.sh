#!/usr/bin/env bash
# =============================================================================
#  Terminal Projector - macOS Installer
#  Handles: Homebrew, Rust/Cargo, terminal check, and all dependencies
# =============================================================================

set -euo pipefail

# ── Colours ────────────────────────────────────────────────────────────────
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

# ── Header ─────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
  ┌─────────────────────────────────────────┐
  │      Terminal Projector – macOS Setup    │
  └─────────────────────────────────────────┘
EOF
echo -e "${RESET}"

# ── macOS Version Gate ──────────────────────────────────────────────────────
MACOS_VER=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VER" | cut -d. -f1)
if [[ "$MACOS_MAJOR" -lt 12 ]]; then
  die "macOS 12 (Monterey) or newer is required. You are running ${MACOS_VER}."
fi
ok "macOS ${MACOS_VER} detected"

# ── Xcode CLI Tools ─────────────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools (this may take a few minutes)..."
  xcode-select --install 2>/dev/null || true
  # Block until the tools are installed
  until xcode-select -p &>/dev/null; do sleep 5; done
fi
ok "Xcode Command Line Tools present"

# ── Homebrew ─────────────────────────────────────────────────────────────────
if command -v brew &>/dev/null; then
  ok "Homebrew $(brew --version | head -1 | awk '{print $2}') already installed"
  info "Updating Homebrew..."
  brew update --quiet
else
  warn "Homebrew not found. Installing now..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  ok "Homebrew installed"
fi

# ── Rust / Cargo ─────────────────────────────────────────────────────────────
if command -v cargo &>/dev/null; then
  ok "Rust $(rustc --version | awk '{print $2}') already installed"
else
  warn "Rust/Cargo not found. Installing via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  ok "Rust installed"
fi

# ── Python 3.10+ check ────────────────────────────────────────────────────────
PYTHON=$(command -v python3 || true)
if [[ -z "$PYTHON" ]]; then
  warn "python3 not found – installing via Homebrew..."
  brew install python
  PYTHON=$(command -v python3)
fi
PY_MINOR=$("$PYTHON" -c "import sys; print(sys.version_info.minor)")
PY_MAJOR=$("$PYTHON" -c "import sys; print(sys.version_info.major)")
if [[ "$PY_MAJOR" -lt 3 || ( "$PY_MAJOR" -eq 3 && "$PY_MINOR" -lt 10 ) ]]; then
  warn "Python 3.10+ is required (found $("$PYTHON" --version)). Installing newer version..."
  brew install python@3.12
  PYTHON=$(brew --prefix)/bin/python3.12
fi
ok "Python $("$PYTHON" --version) found at ${PYTHON}"

# ── Homebrew Packages ────────────────────────────────────────────────────────
BREW_PKGS=(fastfetch btop cbonsai cmatrix lolcat)
for pkg in "${BREW_PKGS[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    ok "${pkg} already installed"
  else
    info "Installing ${pkg}..."
    brew install "$pkg"
    ok "${pkg} installed"
  fi
done

# ── weathr (Cargo) ───────────────────────────────────────────────────────────
if command -v weathr &>/dev/null; then
  ok "weathr already installed"
else
  info "Installing weathr via Cargo..."
  cargo install weathr
  ok "weathr installed"
fi

# ── Terminal Check / Apple Terminal ──────────────────────────────────────────
echo ""
info "Checking terminal emulator..."
TERM_APP="${TERM_PROGRAM:-${LC_TERMINAL:-unknown}}"

if [[ "$TERM_APP" == "Apple_Terminal" ]]; then
  ok "Apple Terminal detected – ideal environment detected (Stable & Native)"
else
  warn "Apple Terminal not detected (current: ${TERM_APP})"
  echo ""
  echo -e "${YELLOW}  Apple Terminal is the recommended terminal for Terminal Projector.${RESET}"
  echo "  It provides the most stable native environment on macOS."
  echo ""
  case "$TERM_APP" in
    iTerm.app)
      warn "iTerm2 detected. For best stability, consider switching to the native Terminal.app."
      ;;
    vscode)
      warn "VS Code terminal detected – some animations may flicker. Use Terminal.app instead."
      ;;
    *)
      warn "Terminal '${TERM_APP}' detected. No specific adjustments applied."
      ;;
  esac
fi

# ── Make projector executable ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/projector.py"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN}  Installation complete!${RESET}"
echo -e "${GREEN}  Launch with: ${BOLD}./projector.py${RESET}"
echo -e "${GREEN}  Config at:   ${BOLD}~/.config/projector/config.json${RESET}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
