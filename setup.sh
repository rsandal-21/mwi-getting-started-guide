#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Teleport MWI Template Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "This script will help you configure GitHub repository variables"
echo "for your Teleport MWI workflows."
echo ""
echo "You'll need the following information:"
echo "  1. Your Teleport cluster proxy address"
echo "  2. Your GitHub repository name (for Teleport configuration)"
echo "  3. Your environment label"
echo "  4. Your target server address (for SSH example)"
echo ""

# Function to prompt for input with validation
prompt_input() {
    local prompt=$1
    local example=$2
    local var_name=$3
    local value=""

    while [ -z "$value" ]; do
        echo -e "${YELLOW}${prompt}${NC}"
        echo -e "  Example: ${example}"
        read -p "  > " value
        if [ -z "$value" ]; then
            echo -e "${RED}  Error: This field is required${NC}"
        fi
    done

    eval "$var_name='$value'"
}

# Collect configuration values
echo -e "${GREEN}Step 1: Teleport Cluster Configuration${NC}"
prompt_input "Enter your Teleport proxy address (including port):" \
    "mycluster.teleport.sh:443" \
    "TELEPORT_PROXY"

echo ""
echo -e "${GREEN}Step 2: GitHub Repository${NC}"
prompt_input "Enter your GitHub repository (format: username/repo-name):" \
    "myusername/mwi-getting-started-guide" \
    "GITHUB_REPO"

echo ""
echo -e "${GREEN}Step 3: Environment Label${NC}"
prompt_input "Enter your environment label:" \
    "production" \
    "ENV_LABEL"

echo ""
echo -e "${GREEN}Step 4: Target Server${NC}"
prompt_input "Enter your target server address:" \
    "myinstance.mycluster.teleport.sh" \
    "SERVER_ADDRESS"

# Display configuration for confirmation
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Configuration Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo "Teleport Proxy: $TELEPORT_PROXY"
echo "GitHub Repository: $GITHUB_REPO"
echo "Environment Label: $ENV_LABEL"
echo "Server Address: $SERVER_ADDRESS"
echo ""
read -p "Is this correct? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Updating Teleport configuration files...${NC}"

# Update Teleport configuration files that can't use GitHub variables
sed -i.bak "s|your-github-username/mwi-getting-started-guide|${GITHUB_REPO}|g" teleport/github_bot_join_token.yaml
sed -i.bak "s|my-env-label|${ENV_LABEL}|g" teleport/github_bot_server_role.yaml
sed -i.bak "s|my-env-label|${ENV_LABEL}|g" teleport/github_bot_k8s_role.yaml

# Remove backup files
find teleport/ -name "*.bak" -type f -delete

echo -e "${GREEN}✓ Teleport configuration files updated${NC}"
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}GitHub Variables Setup${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "You need to configure GitHub repository variables for the workflows."
echo ""
echo "Option 1: Using GitHub CLI (gh)"
echo "Run these commands to set the variables:"
echo ""
echo -e "${YELLOW}gh variable set TELEPORT_PROXY --body \"$TELEPORT_PROXY\"${NC}"
echo -e "${YELLOW}gh variable set ENV_LABEL --body \"$ENV_LABEL\"${NC}"
echo -e "${YELLOW}gh variable set SERVER_ADDRESS --body \"$SERVER_ADDRESS\"${NC}"
echo ""
echo "Option 2: Using GitHub Web UI"
echo "1. Go to your repository on GitHub"
echo "2. Navigate to Settings > Secrets and variables > Actions > Variables tab"
echo "3. Click 'New repository variable' and add:"
echo "   - Name: TELEPORT_PROXY, Value: $TELEPORT_PROXY"
echo "   - Name: ENV_LABEL, Value: $ENV_LABEL"
echo "   - Name: SERVER_ADDRESS, Value: $SERVER_ADDRESS"
echo ""
read -p "Would you like to set the variables using gh CLI now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
        echo "Install it from https://cli.github.com/"
        echo "Then run the commands above manually."
    else
        echo "Setting GitHub variables..."
        gh variable set TELEPORT_PROXY --body "$TELEPORT_PROXY"
        gh variable set ENV_LABEL --body "$ENV_LABEL"
        gh variable set SERVER_ADDRESS --body "$SERVER_ADDRESS"
        echo -e "${GREEN}✓ GitHub variables set successfully${NC}"
    fi
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}======================================${NC}"
echo "1. Apply Teleport configuration:"
echo "   tctl create -f teleport/github_bot_join_token.yaml"
echo "   tctl create -f teleport/github_bot.yaml"
echo "   tctl create -f teleport/github_bot_server_role.yaml"
echo "   tctl create -f teleport/github_bot_k8s_role.yaml"
echo ""
echo "2. Commit and push your changes:"
echo "   git add ."
echo "   git commit -m 'Configure Teleport MWI for my environment'"
echo "   git push"
echo ""
echo "3. Test the workflows:"
echo "   - Go to Actions tab in GitHub"
echo "   - Run 'Check resource usage on server' workflow"
echo "   - Run 'List pods in default namespace' workflow"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
