#!/usr/bin/env bash
# =============================================================================
#  Terminal Projector - Cross-Platform Install Router
#  Detects OS and routes to the correct platform-specific installer.
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_os() {
  case "$(uname -s)" in
    Darwin*)  echo "mac" ;;
    Linux*)   echo "linux" ;;
    MINGW*|CYGWIN*|MSYS*) echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}

OS=$(detect_os)

case "$OS" in
  mac)
    echo "[*] macOS detected – launching install_mac.sh"
    chmod +x "$SCRIPT_DIR/install_mac.sh"
    exec "$SCRIPT_DIR/install_mac.sh"
    ;;
  linux)
    echo "[*] Linux detected – launching install_linux.sh"
    chmod +x "$SCRIPT_DIR/install_linux.sh"
    exec "$SCRIPT_DIR/install_linux.sh"
    ;;
  windows)
    echo "[*] Windows (MINGW/Cygwin) detected – please run install_windows.ps1 in PowerShell instead:"
    echo '    powershell -ExecutionPolicy Bypass -File install_windows.ps1'
    ;;
  *)
    echo "[!] Unknown OS: $(uname -s). Please run the appropriate platform script manually."
    echo "    macOS:   ./install_mac.sh"
    echo "    Linux:   ./install_linux.sh"
    echo "    Windows: powershell -ExecutionPolicy Bypass -File install_windows.ps1"
    exit 1
    ;;
esac
