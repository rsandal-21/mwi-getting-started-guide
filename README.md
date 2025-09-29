# Teleport Machine Workload Identity (MWI) - Getting Started Template

This template repository provides example GitHub Actions workflows that demonstrate Teleport's Machine Workload Identity (MWI) integration.

## 🚀 Quick Start

After creating a repository from this template, run the setup script:

### Linux/macOS
```bash
./setup.sh
```

### Windows (PowerShell)
```powershell
./setup.ps1
```

The script will:
1. Prompt you for configuration values (Teleport proxy, repo name, env label, server address)
2. Update Teleport configuration files
3. Optionally set GitHub repository variables using `gh` CLI

**What are GitHub Variables?**
The workflows use GitHub repository variables (`${{ vars.VARIABLE_NAME }}`) so you don't need to hard-code values. This makes the template cleaner and easier to maintain.

## 📋 What's Included

This template includes two example workflows:

1. **Server Access** (`.github/workflows/server.yaml`)
   - Connects to a server via Teleport
   - Runs `mpstat` to check resource usage
   - Demonstrates SSH access from GitHub Actions

2. **Kubernetes Access** (`.github/workflows/k8s.yaml`)
   - Connects to a Kubernetes cluster via Teleport
   - Lists pods in the default namespace
   - Demonstrates kubectl access from GitHub Actions

## ⚙️ Manual Setup

If you prefer to configure manually:

### 1. Set GitHub Repository Variables

Go to **Settings > Secrets and variables > Actions > Variables** and add:

| Variable Name | Description | Example |
|--------------|-------------|---------|
| `TELEPORT_PROXY` | Your Teleport proxy address with port | `mycluster.teleport.sh:443` |
| `ENV_LABEL` | Environment label for resource filtering | `production` |
| `SERVER_ADDRESS` | Target server address for SSH example | `myinstance.mycluster.teleport.sh` |

Or use the GitHub CLI:
```bash
gh variable set TELEPORT_PROXY --body "mycluster.teleport.sh:443"
gh variable set ENV_LABEL --body "production"
gh variable set SERVER_ADDRESS --body "myinstance.mycluster.teleport.sh"
```

### 2. Update Teleport Configuration Files

Replace placeholders in:

- [ ] `teleport/github_bot_join_token.yaml` - Replace `your-github-username/mwi-getting-started-guide` with your repo
- [ ] `teleport/github_bot_server_role.yaml` - Replace `my-env-label` with your environment label
- [ ] `teleport/github_bot_k8s_role.yaml` - Replace `my-env-label` with your environment label

## 🔧 Applying Configuration to Teleport

After configuring the template, apply the Teleport resources to your cluster:

```bash
tctl create -f teleport/github_bot_join_token.yaml
tctl create -f teleport/github_bot.yaml
tctl create -f teleport/github_bot_server_role.yaml
tctl create -f teleport/github_bot_k8s_role.yaml
```

## ✅ Testing

1. Commit and push your changes
2. Go to the **Actions** tab in your GitHub repository
3. Manually trigger the workflows:
   - "Check resource usage on server"
   - "List pods in default namespace"

## 📚 Documentation

For detailed information about Teleport Machine Workload Identity, see:
- [Getting Started Guide](https://goteleport.com/docs/machine-workload-identity/machine-id/getting-started/)
- [Teleport Documentation](https://goteleport.com/docs/)

## 🔍 Validation

This repository includes automatic validation:
- The **Validate Configuration** workflow checks for unconfigured placeholders
- The **Template Cleanup** workflow creates a setup reminder issue when you first use the template
- These workflows help ensure your configuration is complete before running the example workflows
