# Terminal Projector

A completely automated, OS-agnostic terminal multiplexer for pure aesthetic dopamine built in Python.
Renders localized weather, system stats, and animated ASCII art right in your terminal buffer.

## Installation
Run the included install script to automatically fetch required dependencies (Homebrew, Rust, etc.) and binaries (`weathr`, `fastfetch`, `btop`, `cbonsai`, `cmatrix`):

```bash
chmod +x install.sh
./install.sh
```

## Usage
Simply run the python script:

```bash
chmod +x projector.py
./projector.py
```

The config file will be auto-generated at `~/.config/projector/config.json`. You can modify it to adjust durations and commands in real-time.
