#!/bin/bash
# push-to-vm.sh — Push all Miles config files to VM staging directory
#
# Usage: ./scripts/push-to-vm.sh
#
# This pushes everything to ~/miles-staging/ on the VM.
# Then SSH in and run ~/miles-staging/setup-vm.sh to install.
#
# Prerequisites:
#   - SSH config entry 'miles-vm' exists
#   - VM is running and accessible
#   - config/staging.env has been filled with real credentials

set -euo pipefail

VM_HOST="miles-vm"
STAGING_DIR="~/miles-staging"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Push Miles Config to VM ==="
echo "Source: $SCRIPT_DIR"
echo "Target: $VM_HOST:$STAGING_DIR"
echo ""

# Check SSH connectivity
echo "Checking SSH connectivity..."
if ! ssh -o ConnectTimeout=10 -q "$VM_HOST" exit 2>/dev/null; then
    echo "ERROR: Cannot connect to $VM_HOST."
    echo "Your current IP: $(curl -s ifconfig.me)"
    echo ""
    echo "Update NSG rule:"
    echo "  az network nsg rule update \\"
    echo "    --resource-group rg-openclaw-eastus \\"
    echo "    --nsg-name vm-miles-01NSG \\"
    echo "    --name default-allow-ssh \\"
    echo "    --source-address-prefixes \"\$(curl -s -4 ifconfig.me)/32\""
    exit 1
fi
echo "  Connected."
echo ""

# Create staging directory
ssh "$VM_HOST" "mkdir -p $STAGING_DIR/{templates,skills}"

# Push credentials
echo "Pushing credentials..."
scp "$SCRIPT_DIR/config/staging.env" "$VM_HOST:$STAGING_DIR/staging.env"
scp "$SCRIPT_DIR/config/openclaw.json" "$VM_HOST:$STAGING_DIR/openclaw.json"
echo "  Credentials pushed."

# Push config templates
echo "Pushing config templates..."
scp "$SCRIPT_DIR/config/templates/"*.template "$VM_HOST:$STAGING_DIR/templates/"
echo "  Templates pushed."

# Push skills
echo "Pushing skills..."
scp "$SCRIPT_DIR/skills/"*.md "$VM_HOST:$STAGING_DIR/skills/"
echo "  Skills pushed."

# Push Google OAuth client_secret.json (if available locally)
CLIENT_SECRET="$HOME/Downloads/client_secret_227680329104-54s9fo0lrcb1musknblp9be73v1m1qtb.apps.googleusercontent.com.json"
if [ -f "$CLIENT_SECRET" ]; then
    echo "Pushing client_secret.json..."
    scp "$CLIENT_SECRET" "$VM_HOST:$STAGING_DIR/client_secret.json"
    echo "  client_secret.json pushed."
else
    echo "  SKIP: client_secret.json not found at expected path."
    echo "  You'll need to copy it manually for Google Calendar OAuth."
fi

# Push setup script
echo "Pushing setup script..."
scp "$SCRIPT_DIR/scripts/setup-vm.sh" "$VM_HOST:$STAGING_DIR/setup-vm.sh"
ssh "$VM_HOST" "chmod +x $STAGING_DIR/setup-vm.sh"
echo "  Setup script pushed."

echo ""
echo "=== Push Complete ==="
echo ""
echo "Next steps:"
echo "  1. SSH to VM: ssh $VM_HOST"
echo "  2. Run setup: ~/miles-staging/setup-vm.sh"
echo "  3. Follow the on-screen instructions for manual steps"
