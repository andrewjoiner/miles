#!/bin/bash
# deploy.sh — Deploy Miles's OpenClaw configuration to the Azure VM
#
# Usage: ./scripts/deploy.sh
#
# This script copies agent configuration files and skills to the VM.
# It does NOT start or restart the container — do that manually after verifying.
#
# Prerequisites:
#   - SSH config entry 'miles-vm' exists
#   - VM is running and accessible
#   - Docker container directory ~/miles/ exists on VM

set -euo pipefail

VM_HOST="miles-vm"
REMOTE_DIR="~/miles"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Miles Agent Deploy ==="
echo "Source: $SCRIPT_DIR"
echo "Target: $VM_HOST:$REMOTE_DIR"
echo ""

# Check SSH connectivity
echo "Checking SSH connectivity..."
if ! ssh -q "$VM_HOST" exit 2>/dev/null; then
    echo "ERROR: Cannot connect to $VM_HOST. Check SSH config and NSG rules."
    echo "Your current IP: $(curl -s ifconfig.me)"
    exit 1
fi

# Deploy agent configuration files
echo "Deploying agent configuration..."
scp "$SCRIPT_DIR/config/templates/soul.md.template" "$VM_HOST:$REMOTE_DIR/workspace/SOUL.md"
scp "$SCRIPT_DIR/config/templates/agents.md.template" "$VM_HOST:$REMOTE_DIR/workspace/AGENTS.md"
scp "$SCRIPT_DIR/config/templates/user.md.template" "$VM_HOST:$REMOTE_DIR/workspace/USER.md"
scp "$SCRIPT_DIR/config/templates/tools.md.template" "$VM_HOST:$REMOTE_DIR/workspace/TOOLS.md"
scp "$SCRIPT_DIR/config/templates/heartbeat.md.template" "$VM_HOST:$REMOTE_DIR/workspace/HEARTBEAT.md"
scp "$SCRIPT_DIR/config/templates/security-rules.md.template" "$VM_HOST:$REMOTE_DIR/workspace/SECURITY.md"
echo "  Agent config files deployed."

# Deploy skills
echo "Deploying skills..."
ssh "$VM_HOST" "mkdir -p $REMOTE_DIR/workspace/skills"
scp "$SCRIPT_DIR/skills/"*.md "$VM_HOST:$REMOTE_DIR/workspace/skills/"
echo "  Skills deployed: $(ls "$SCRIPT_DIR/skills/"*.md | wc -l | tr -d ' ') files"

# Deploy openclaw.json if it exists (filled, not template)
if [ -f "$SCRIPT_DIR/config/openclaw.json" ]; then
    echo "Deploying openclaw.json..."
    scp "$SCRIPT_DIR/config/openclaw.json" "$VM_HOST:$REMOTE_DIR/openclaw.json"
    echo "  openclaw.json deployed."
else
    echo "  SKIP: config/openclaw.json not found (only template exists). Fill in values first."
fi

echo ""
echo "=== Deploy Complete ==="
echo ""
echo "Next steps:"
echo "  1. SSH to VM: ssh $VM_HOST"
echo "  2. Verify files: ls -la $REMOTE_DIR/workspace/"
echo "  3. Check model: docker exec miles-openclaw openclaw status | grep model"
echo "  4. If ready, restart: cd $REMOTE_DIR && docker compose restart"
echo ""
echo "REMINDER: Verify model is NOT Opus before any interaction."
