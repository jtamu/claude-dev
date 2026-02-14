#!/bin/bash
set -e

SSH_DIR="/home/dev/.ssh"
KEY_PATH="$SSH_DIR/id_ed25519"

# Generate SSH key if not present (e.g. first run or new volume)
if [ ! -f "$KEY_PATH" ]; then
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "claude-dev-ui@$(hostname)"
  chmod 600 "$KEY_PATH"
  chmod 644 "$KEY_PATH.pub"
fi

# Output public key so user can add to GitHub/GitLab etc.
echo ""
echo "=============================================="
echo "UI container SSH public key (for git clone etc.)"
echo "Add this key to your Git provider's deploy keys / SSH keys:"
echo "=============================================="
cat "$KEY_PATH.pub"
echo "=============================================="
echo ""

exec "$@"
