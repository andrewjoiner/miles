# 01 — Azure VM Provisioning

## Resource Group
Reuse existing resource group (shared with Ava and Surveyor):
```bash
# Verify it exists
az group show --name rg-openclaw-eastus
```

## Create the VM

```bash
az vm create \
  --resource-group rg-openclaw-eastus \
  --name vm-miles-01 \
  --image Ubuntu2404 \
  --size Standard_B2ms \
  --admin-username openclaw \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --public-ip-sku Standard \
  --storage-sku StandardSSD_LRS \
  --os-disk-size-gb 30
```

**VM size:** Standard_B2ms (2 vCPU, 8GB RAM) — same as Ava and Surveyor, ~$81/mo PAYG on Azure Sponsorship.

## Note the Public IP
```bash
az vm show -d --resource-group rg-openclaw-eastus --name vm-miles-01 --query publicIps -o tsv
```

Save this IP — you'll need it for SSH config and NSG rules.

## Configure NSG (Network Security Group)

Restrict SSH to Andrew's IP only:
```bash
# Get your current IP
MY_IP=$(curl -s ifconfig.me)

# Find the NSG name (auto-created with the VM)
NSG_NAME=$(az network nsg list --resource-group rg-openclaw-eastus --query "[?contains(name, 'miles')].name" -o tsv)

# Update the SSH rule
az network nsg rule update \
  --resource-group rg-openclaw-eastus \
  --nsg-name $NSG_NAME \
  --name default-allow-ssh \
  --source-address-prefixes "$MY_IP/32"
```

**Note:** Andrew's IP changes frequently. Update NSG each session:
```bash
az network nsg rule update \
  --resource-group rg-openclaw-eastus \
  --nsg-name $NSG_NAME \
  --name default-allow-ssh \
  --source-address-prefixes "$(curl -s ifconfig.me)/32"
```

## SSH Config

Add to `~/.ssh/config`:
```
Host miles-vm
    HostName {{VM_PUBLIC_IP}}
    User openclaw
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## Verify Connection
```bash
ssh miles-vm "uname -a && df -h && free -h"
```

## Install Tailscale (for stable remote access)

```bash
ssh miles-vm "curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up"
```

Follow the auth link to add the VM to your Tailnet. Once connected, you can use the Tailscale IP instead of the public IP (doesn't change when your home IP changes).

## Update CLAUDE.md
After provisioning, update the Azure VM Details section in the project CLAUDE.md with:
- Resource group name
- VM name
- Public IP (and Tailscale IP)
- SSH config entry
- Provisioned date
