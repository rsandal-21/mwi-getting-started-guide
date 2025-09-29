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

# Try to detect proxy from tsh status if user is logged in
DETECTED_PROXY=""
if command -v tsh &> /dev/null; then
    if tsh status &> /dev/null; then
        DETECTED_PROXY=$(tsh status --format=json 2>/dev/null | sed -n 's/.*"profile_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | sed 's|https://||' | sed 's|http://||')
        if [ -n "$DETECTED_PROXY" ]; then
            echo -e "${BLUE}Detected Teleport proxy from tsh status: ${DETECTED_PROXY}${NC}"
            read -p "Use this proxy? (y/n) " -r REPLY
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                TELEPORT_PROXY="$DETECTED_PROXY"
            fi
        fi
    fi
fi

if [ -z "$TELEPORT_PROXY" ]; then
    prompt_input "Enter your Teleport proxy address (including port):" \
        "mycluster.teleport.sh:443" \
        "TELEPORT_PROXY"
fi

echo ""
echo -e "${GREEN}Step 2: GitHub Repository${NC}"

# Try to detect GitHub repository from git remote
DETECTED_REPO=""
if command -v git &> /dev/null && [ -d .git ]; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        # Extract owner/repo from various GitHub URL formats
        # Supports: https://github.com/owner/repo.git, git@github.com:owner/repo.git, etc.
        DETECTED_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+)(\.git)?$|\1|' | sed 's|\.git$||')
        if [ -n "$DETECTED_REPO" ]; then
            echo -e "${BLUE}Detected GitHub repository from git remote: ${DETECTED_REPO}${NC}"
            read -p "Use this repository? (y/n) " -r REPLY
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                GITHUB_REPO="$DETECTED_REPO"
            fi
        fi
    fi
fi

if [ -z "$GITHUB_REPO" ]; then
    prompt_input "Enter your GitHub repository (format: username/repo-name):" \
        "myusername/mwi-getting-started-guide" \
        "GITHUB_REPO"
fi

echo ""
echo -e "${GREEN}Step 3: Target Server${NC}"

# Try to detect a server from tsh ls
DETECTED_SERVER=""
if command -v tsh &> /dev/null; then
    # Get first available server
    DETECTED_SERVER=$(tsh ls --format=names 2>/dev/null | head -1)
    if [ -n "$DETECTED_SERVER" ]; then
        echo -e "${BLUE}Detected server from tsh ls: ${DETECTED_SERVER}${NC}"
        read -p "Use this server? (y/n) " -r REPLY
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SERVER_ADDRESS="$DETECTED_SERVER"
        fi
    fi
fi

if [ -z "$SERVER_ADDRESS" ]; then
    prompt_input "Enter your target server address:" \
        "myinstance.mycluster.teleport.sh" \
        "SERVER_ADDRESS"
fi

echo ""
echo -e "${GREEN}Step 4: Environment Label${NC}"

# Try to detect labels from the selected server
DETECTED_LABEL=""
LABEL_LIST=""
if command -v tsh &> /dev/null && [ -n "$SERVER_ADDRESS" ]; then
    # Get labels for the specific server
    # Strategy: Find lines between hostname match and first occurrence of "labels", then extract key-value pairs
    LABEL_LIST=$(tsh ls --format=json 2>/dev/null | awk -v host="$SERVER_ADDRESS" '
        $0 ~ "\"hostname\".*\"" host "\"" { found=1 }
        found && /"labels"/ { in_labels=1; next }
        in_labels && /}/ { exit }
        in_labels && /"[^"]*"[[:space:]]*:[[:space:]]*"[^"]*"/ {
            gsub(/^[[:space:]]*"|"[[:space:]]*:[[:space:]]*"|"[[:space:]]*,?[[:space:]]*$/, " ")
            gsub(/[[:space:]]+/, " ")
            sub(/^ /, "")
            n = split($0, parts, " ")
            if (n >= 2) print "  " parts[1] ": " parts[2]
        }
    ')

    if [ -n "$LABEL_LIST" ]; then
        echo -e "${BLUE}Available labels on server '${SERVER_ADDRESS}':${NC}"
        echo "$LABEL_LIST"
        echo ""

        # Look for common environment labels
        DETECTED_LABEL=$(echo "$LABEL_LIST" | sed -n 's/^[[:space:]]*\(env\|environment\|stage\):[[:space:]]*\(.*\)/\2/p' | head -1)
        if [ -n "$DETECTED_LABEL" ]; then
            echo -e "${BLUE}Suggested environment label: ${DETECTED_LABEL}${NC}"
            read -p "Use this label? (y/n) " -r REPLY
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ENV_LABEL="$DETECTED_LABEL"
            fi
        else
            echo -e "${YELLOW}Tip: You can use any label key from above, or create a new one (e.g., 'production', 'dev')${NC}"
            echo ""
        fi
    fi
fi

if [ -z "$ENV_LABEL" ]; then
    prompt_input "Enter your environment label:" \
        "production" \
        "ENV_LABEL"
fi

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
