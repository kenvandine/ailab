#!/bin/bash
# Quick installer for ai-dev-box
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Installing ai-dev-box..."

# pipx is the cleanest option - isolated venv, adds to PATH automatically
if command -v pipx &>/dev/null; then
    pipx install --editable "$SCRIPT_DIR"
    echo ""
    echo "Installation complete! Try:"
    echo "  ai-dev-box --help"
    echo "  ai-dev-box new mybox"
    exit 0
fi

# Fall back to a local venv with a wrapper script in ~/.local/bin
VENV="$HOME/.local/share/ai-dev-box/venv"
BIN="$HOME/.local/bin"

mkdir -p "$VENV" "$BIN"
python3 -m venv "$VENV"
"$VENV/bin/pip" install --quiet --editable "$SCRIPT_DIR"

# Write a thin wrapper so the tool is on PATH
cat > "$BIN/ai-dev-box" <<EOF
#!/bin/bash
exec "$VENV/bin/ai-dev-box" "\$@"
EOF
chmod +x "$BIN/ai-dev-box"

echo ""
echo "Installation complete!"
echo "Make sure $BIN is on your PATH, then try:"
echo "  ai-dev-box --help"
echo "  ai-dev-box new mybox"
