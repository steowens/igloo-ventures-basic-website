#!/bin/bash

# Igloo Ventures Deployment Script
# Deploys Hugo static site to Ubuntu 24.04.3 LTS server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Igloo Ventures Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration - UPDATE THESE
VM_USER="${VM_USER:-your_username}"
VM_HOST="${VM_HOST:-your_server_ip}"
DEPLOY_PATH="/var/www/iglooventures"

# Local paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

echo -e "${BLUE}Configuration:${NC}"
echo "  VM: ${VM_USER}@${VM_HOST}"
echo "  Local: ${PROJECT_ROOT}"
echo "  Remote: ${DEPLOY_PATH}"
echo ""

# Prompt for VM details if defaults
if [[ "${VM_USER}" == "your_username" ]]; then
    read -p "Enter VM username: " VM_USER
fi
if [[ "${VM_HOST}" == "your_server_ip" ]]; then
    read -p "Enter VM IP or domain: " VM_HOST
fi

# Test SSH connection
echo -e "${GREEN}[1/5] Testing SSH connection...${NC}"
if ssh -q -o BatchMode=yes -o ConnectTimeout=5 ${VM_USER}@${VM_HOST} exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ SSH connection failed${NC}"
    echo "Please ensure:"
    echo "  - SSH key is configured (ssh-copy-id ${VM_USER}@${VM_HOST})"
    echo "  - VM is accessible"
    exit 1
fi

# Check for Hugo
echo -e "${GREEN}[2/5] Checking Hugo installation...${NC}"
if ! command -v hugo &> /dev/null; then
    echo -e "${RED}✗ Hugo is not installed${NC}"
    echo "Install Hugo: brew install hugo (Mac) or apt install hugo (Linux)"
    exit 1
fi
echo -e "${GREEN}✓ Hugo found: $(hugo version | head -1)${NC}"

# Build Hugo site
echo -e "${GREEN}[3/5] Building Hugo site...${NC}"
cd "${PROJECT_ROOT}"

# Clean previous build
rm -rf public/

# Build
hugo

if [ ! -d "public" ]; then
    echo -e "${RED}✗ Hugo build failed - public/ not found${NC}"
    exit 1
fi

# Count files
FILE_COUNT=$(find public -type f | wc -l)
echo -e "${GREEN}✓ Hugo site built successfully (${FILE_COUNT} files)${NC}"

# Create deployment package
echo -e "${GREEN}[4/5] Creating deployment package...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf /tmp/igloo-deploy-${TIMESTAMP}.tar.gz -C public .

DEPLOY_PACKAGE="/tmp/igloo-deploy-${TIMESTAMP}.tar.gz"
PACKAGE_SIZE=$(du -h ${DEPLOY_PACKAGE} | cut -f1)
echo -e "${GREEN}✓ Package created: ${DEPLOY_PACKAGE} (${PACKAGE_SIZE})${NC}"

# Backup current deployment and upload
echo -e "${GREEN}[5/5] Deploying to VM...${NC}"

# Create backup, upload, and extract in one SSH session
ssh ${VM_USER}@${VM_HOST} << ENDSSH
set -e

# Create directory if it doesn't exist
mkdir -p ${DEPLOY_PATH}

# Backup current deployment
if [ -d "${DEPLOY_PATH}/public" ] && [ "\$(ls -A ${DEPLOY_PATH}/public 2>/dev/null)" ]; then
    echo "Creating backup..."
    tar -czf ${DEPLOY_PATH}/backup-\$(date +%Y%m%d_%H%M%S).tar.gz \
        -C ${DEPLOY_PATH} public/ 2>/dev/null || true
    # Keep only last 3 backups
    cd ${DEPLOY_PATH}
    ls -t backup-*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true
    echo "Backup created"
else
    echo "No existing deployment to backup"
fi

# Prepare for new deployment
mkdir -p ${DEPLOY_PATH}/public
ENDSSH

# Upload the package
scp ${DEPLOY_PACKAGE} ${VM_USER}@${VM_HOST}:/tmp/igloo-deploy.tar.gz

# Extract and cleanup
ssh ${VM_USER}@${VM_HOST} << ENDSSH
set -e

# Clear current public directory
rm -rf ${DEPLOY_PATH}/public/*

# Extract new deployment
echo "Extracting deployment..."
tar -xzf /tmp/igloo-deploy.tar.gz -C ${DEPLOY_PATH}/public/

# Cleanup
rm /tmp/igloo-deploy.tar.gz

# Verify deployment
FILE_COUNT=\$(find ${DEPLOY_PATH}/public -type f | wc -l)
echo "Deployed \${FILE_COUNT} files to ${DEPLOY_PATH}/public/"

# Set proper permissions
chmod -R 755 ${DEPLOY_PATH}/public/

echo "Deployment complete!"
ENDSSH

echo -e "${GREEN}✓ Deployment complete${NC}"

# Cleanup local package
rm ${DEPLOY_PACKAGE}

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Deployed components:"
echo "  ✓ Hugo static site -> ${DEPLOY_PATH}/public/"
echo "  ✓ ${FILE_COUNT} files deployed"
echo ""
echo "Verify deployment:"
echo "  Website: https://iglooventures.biz"
echo ""
echo "Useful commands:"
echo "  View files:   ssh ${VM_USER}@${VM_HOST} 'ls -la ${DEPLOY_PATH}/public/'"
echo "  Check nginx:  ssh ${VM_USER}@${VM_HOST} 'sudo nginx -t && sudo systemctl status nginx'"
echo "  SSH to VM:    ssh ${VM_USER}@${VM_HOST}"
echo ""

# Offer to test
read -p "Test the deployment now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Testing website..."
    if curl -f -s -o /dev/null https://iglooventures.biz; then
        echo -e "${GREEN}✓ Website is responding${NC}"
    else
        echo -e "${YELLOW}⚠ Website test failed (may need SSL setup)${NC}"
        echo "Try: http://iglooventures.biz"
    fi
fi

echo ""
