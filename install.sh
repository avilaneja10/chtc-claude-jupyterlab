#!/bin/bash
# install.sh
# Run on the CHTC access point after editing ~/.chtc-jupyterlab/config.sh

set -euo pipefail

CONFIG="${CHTC_LAB_CONFIG:-$HOME/.chtc-jupyterlab/config.sh}"
if [ ! -f "$CONFIG" ]; then
    echo "No config at $CONFIG"
    echo "Run:  mkdir -p ~/.chtc-jupyterlab && cp config.sh ~/.chtc-jupyterlab/config.sh"
    echo "then edit it before running this."
    exit 1
fi
. "$CONFIG"

SRC="$(cd "$(dirname "$0")" && pwd)"

echo "Installing launcher scripts to ~/bin"
mkdir -p "$HOME/bin"
install -m 755 "$SRC/bin/lab" "$SRC/bin/lab-stop" "$HOME/bin/"

echo "Installing job files to $PROJECT_DIR"
mkdir -p "$PROJECT_DIR/logs"
install -m 644 "$SRC/job/session.sub" "$PROJECT_DIR/"
install -m 755 "$SRC/job/launch_session.sh" "$PROJECT_DIR/"
install -m 755 "$SRC/bin/tunnel.sh" "$PROJECT_DIR/"

echo "Installing shared files to $TOOLS"
mkdir -p "$TOOLS/bin" "$TOOLS/claude-config"
install -m 644 "$SRC/env.sh" "$TOOLS/"
install -m 644 "$CONFIG" "$TOOLS/config.sh"
install -m 755 "$SRC/bin/claude-login" "$TOOLS/bin/"

mkdir -p "$WORKDIR"

echo ""
echo "Done."
echo ""
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) echo "  ~/bin is not on your PATH. Add to ~/.bashrc:"
       echo "    export PATH=\"\$HOME/bin:\$PATH\""
       echo "" ;;
esac
if [ ! -x "$TOOLS/bin/claude" ]; then
    echo "  Claude Code is not at $TOOLS/bin/claude yet."
    echo "  See step 3 in the README."
    echo ""
fi
echo "  Next:  lab"
