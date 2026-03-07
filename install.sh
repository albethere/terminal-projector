#!/usr/bin/env bash

# Terminal Projector Dependencies Installer

set -e

echo "[*] Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "[-] Homebrew is not installed. Please install it first:"
    echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

echo "[*] Checking for Rust (Cargo)..."
if ! command -v cargo &> /dev/null; then
    echo "[-] Cargo is not installed. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "[*] Installing Homebrew dependencies..."
brew update
brew install fastfetch btop cbonsai cmatrix lolcat

echo "[*] Installing weathr via Cargo..."
cargo install weathr

echo "[+] Installation complete! You can now run ./projector.py"
