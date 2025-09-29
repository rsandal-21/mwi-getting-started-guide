# Teleport MWI Template Setup Script for Windows
# PowerShell version

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-ValidatedInput {
    param(
        [string]$Prompt,
        [string]$Example
    )

    $value = ""
    while ([string]::IsNullOrWhiteSpace($value)) {
        Write-ColorOutput "`n$Prompt" "Yellow"
        Write-Host "  Example: $Example"
        $value = Read-Host "  >"
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-ColorOutput "  Error: This field is required" "Red"
        }
    }
    return $value.Trim()
}

Write-ColorOutput "======================================" "Blue"
Write-ColorOutput "Teleport MWI Template Setup" "Blue"
Write-ColorOutput "======================================" "Blue"
Write-Host ""
Write-Host "This script will help you configure GitHub repository variables"
Write-Host "for your Teleport MWI workflows."
Write-Host ""
Write-Host "You'll need the following information:"
Write-Host "  1. Your Teleport cluster proxy address"
Write-Host "  2. Your GitHub repository name (for Teleport configuration)"
Write-Host "  3. Your environment label"
Write-Host "  4. Your target server address (for SSH example)"
Write-Host ""

# Collect configuration values
Write-ColorOutput "Step 1: Teleport Cluster Configuration" "Green"
$TELEPORT_PROXY = Get-ValidatedInput `
    -Prompt "Enter your Teleport proxy address (including port):" `
    -Example "mycluster.teleport.sh:443"

Write-ColorOutput "`nStep 2: GitHub Repository" "Green"
$GITHUB_REPO = Get-ValidatedInput `
    -Prompt "Enter your GitHub repository (format: username/repo-name):" `
    -Example "myusername/mwi-getting-started-guide"

Write-ColorOutput "`nStep 3: Environment Label" "Green"
$ENV_LABEL = Get-ValidatedInput `
    -Prompt "Enter your environment label:" `
    -Example "production"

Write-ColorOutput "`nStep 4: Target Server" "Green"
$SERVER_ADDRESS = Get-ValidatedInput `
    -Prompt "Enter your target server address:" `
    -Example "myinstance.mycluster.teleport.sh"

# Display configuration for confirmation
Write-Host ""
Write-ColorOutput "======================================" "Blue"
Write-ColorOutput "Configuration Summary" "Blue"
Write-ColorOutput "======================================" "Blue"
Write-Host "Teleport Proxy: $TELEPORT_PROXY"
Write-Host "GitHub Repository: $GITHUB_REPO"
Write-Host "Environment Label: $ENV_LABEL"
Write-Host "Server Address: $SERVER_ADDRESS"
Write-Host ""

$confirmation = Read-Host "Is this correct? (y/n)"
if ($confirmation -notmatch '^[Yy]$') {
    Write-ColorOutput "Setup cancelled." "Red"
    exit 1
}

Write-Host ""
Write-ColorOutput "Updating Teleport configuration files..." "Green"

# Function to replace text in file
function Update-ConfigFile {
    param(
        [string]$FilePath,
        [string]$OldValue,
        [string]$NewValue
    )

    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        $content = $content -replace [regex]::Escape($OldValue), $NewValue
        Set-Content -Path $FilePath -Value $content -NoNewline
    }
}

# Update Teleport configuration files that can't use GitHub variables
Update-ConfigFile "teleport/github_bot_join_token.yaml" "your-github-username/mwi-getting-started-guide" $GITHUB_REPO
Update-ConfigFile "teleport/github_bot_server_role.yaml" "my-env-label" $ENV_LABEL
Update-ConfigFile "teleport/github_bot_k8s_role.yaml" "my-env-label" $ENV_LABEL

Write-ColorOutput "✓ Teleport configuration files updated" "Green"
Write-Host ""
Write-ColorOutput "======================================" "Blue"
Write-ColorOutput "GitHub Variables Setup" "Blue"
Write-ColorOutput "======================================" "Blue"
Write-Host ""
Write-Host "You need to configure GitHub repository variables for the workflows."
Write-Host ""
Write-Host "Option 1: Using GitHub CLI (gh)"
Write-Host "Run these commands to set the variables:"
Write-Host ""
Write-ColorOutput "gh variable set TELEPORT_PROXY --body `"$TELEPORT_PROXY`"" "Yellow"
Write-ColorOutput "gh variable set ENV_LABEL --body `"$ENV_LABEL`"" "Yellow"
Write-ColorOutput "gh variable set SERVER_ADDRESS --body `"$SERVER_ADDRESS`"" "Yellow"
Write-Host ""
Write-Host "Option 2: Using GitHub Web UI"
Write-Host "1. Go to your repository on GitHub"
Write-Host "2. Navigate to Settings > Secrets and variables > Actions > Variables tab"
Write-Host "3. Click 'New repository variable' and add:"
Write-Host "   - Name: TELEPORT_PROXY, Value: $TELEPORT_PROXY"
Write-Host "   - Name: ENV_LABEL, Value: $ENV_LABEL"
Write-Host "   - Name: SERVER_ADDRESS, Value: $SERVER_ADDRESS"
Write-Host ""

$setVars = Read-Host "Would you like to set the variables using gh CLI now? (y/n)"

if ($setVars -match '^[Yy]$') {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "Error: GitHub CLI (gh) is not installed." "Red"
        Write-Host "Install it from https://cli.github.com/"
        Write-Host "Then run the commands above manually."
    } else {
        Write-Host "Setting GitHub variables..."
        gh variable set TELEPORT_PROXY --body $TELEPORT_PROXY
        gh variable set ENV_LABEL --body $ENV_LABEL
        gh variable set SERVER_ADDRESS --body $SERVER_ADDRESS
        Write-ColorOutput "✓ GitHub variables set successfully" "Green"
    }
}

Write-Host ""
Write-ColorOutput "======================================" "Blue"
Write-ColorOutput "Next Steps" "Blue"
Write-ColorOutput "======================================" "Blue"
Write-Host "1. Apply Teleport configuration:"
Write-Host "   tctl create -f teleport/github_bot_join_token.yaml"
Write-Host "   tctl create -f teleport/github_bot.yaml"
Write-Host "   tctl create -f teleport/github_bot_server_role.yaml"
Write-Host "   tctl create -f teleport/github_bot_k8s_role.yaml"
Write-Host ""
Write-Host "2. Commit and push your changes:"
Write-Host "   git add ."
Write-Host "   git commit -m 'Configure Teleport MWI for my environment'"
Write-Host "   git push"
Write-Host ""
Write-Host "3. Test the workflows:"
Write-Host "   - Go to Actions tab in GitHub"
Write-Host "   - Run 'Check resource usage on server' workflow"
Write-Host "   - Run 'List pods in default namespace' workflow"
Write-Host ""
Write-ColorOutput "Setup complete!" "Green"
