#!/bin/bash

# Igloo Ventures - Server Deployment Script
# Run this ON THE SERVER after copying deployment package

set -e  # Exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Igloo Ventures Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root or with sudo${NC}"
   exit 1
fi

# Configuration
DEPLOY_PATH="/var/www/iglooventures"
SITE_PACKAGE="igloo-site.tar.gz"

# Check for package
echo -e "${GREEN}[1/4] Checking deployment package...${NC}"

if [ ! -f "${SITE_PACKAGE}" ]; then
    echo -e "${RED}✗ ${SITE_PACKAGE} not found in current directory${NC}"
    echo "Please copy igloo-site.tar.gz to $(pwd)"
    exit 1
fi

echo -e "${GREEN}✓ Deployment package found${NC}"

# Create deployment directory if needed
echo -e "${GREEN}[2/4] Preparing deployment directory...${NC}"
mkdir -p ${DEPLOY_PATH}

# Backup existing deployment
echo -e "${GREEN}[3/4] Backing up current deployment...${NC}"

if [ -d "${DEPLOY_PATH}/public" ] && [ "$(ls -A ${DEPLOY_PATH}/public 2>/dev/null)" ]; then
    BACKUP_FILE="${DEPLOY_PATH}/backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "Creating backup: ${BACKUP_FILE}"

    tar -czf "${BACKUP_FILE}" \
        -C ${DEPLOY_PATH} \
        --ignore-failed-read \
        public/ 2>/dev/null || true

    # Keep only last 5 backups
    cd ${DEPLOY_PATH}
    ls -t backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

    echo -e "${GREEN}✓ Backup created${NC}"
else
    echo "No existing deployment to backup"
fi

# Extract site
echo -e "${GREEN}[4/4] Deploying site...${NC}"

# Remove old public directory
rm -rf ${DEPLOY_PATH}/public

# Create new public directory
mkdir -p ${DEPLOY_PATH}/public

# Extract new site
cd ${DEPLOY_PATH}/public
tar -xzf /root/${SITE_PACKAGE}

# Set proper permissions
chmod -R 755 ${DEPLOY_PATH}/public/

echo -e "${GREEN}✓ Site deployed${NC}"

# Verify deployment
FILE_COUNT=$(find ${DEPLOY_PATH}/public -type f | wc -l)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Deployed to: ${DEPLOY_PATH}"
echo ""
echo "Components:"
echo "  ✓ Hugo static site: ${DEPLOY_PATH}/public/"
echo "  ✓ ${FILE_COUNT} files deployed"
echo ""
echo "Verify deployment:"
echo "  curl http://localhost"
echo "  curl https://iglooventures.biz"
echo ""
echo "Useful commands:"
echo "  ls -la ${DEPLOY_PATH}/public/         # View files"
echo "  sudo nginx -t                         # Test nginx config"
echo "  sudo systemctl reload nginx           # Reload nginx"
echo ""
echo "Rollback (if needed):"
echo "  cd ${DEPLOY_PATH}"
echo "  ls -lh backup-*.tar.gz"
echo "  rm -rf public/"
echo "  mkdir public"
echo "  tar -xzf backup-YYYYMMDD_HHMMSS.tar.gz"
echo ""
