#!/bin/bash

# Igloo Ventures - Build Deployment Package
# Creates deployment package that can be copied to server

set -e  # Exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building Igloo Ventures Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUILD_DIR="${PROJECT_ROOT}/build-${TIMESTAMP}"

echo "Project root: ${PROJECT_ROOT}"
echo "Build directory: ${BUILD_DIR}"
echo ""

# Check for Hugo
echo -e "${GREEN}[1/3] Checking Hugo installation...${NC}"
if ! command -v hugo &> /dev/null; then
    echo -e "${RED}✗ Hugo is not installed${NC}"
    echo "Install Hugo: brew install hugo (Mac) or apt install hugo (Linux)"
    exit 1
fi
echo -e "${GREEN}✓ Hugo found: $(hugo version | head -1)${NC}"

# Create build directory
mkdir -p "${BUILD_DIR}"

# Build Hugo site
echo -e "${GREEN}[2/3] Building Hugo site...${NC}"
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

# Package site
echo -e "${GREEN}[3/3] Packaging site...${NC}"
tar -czf "${BUILD_DIR}/igloo-site.tar.gz" \
    -C public .

echo -e "${GREEN}✓ Site packaged${NC}"

# Copy deployment script
cp "${SCRIPT_DIR}/deploy-on-server.sh" "${BUILD_DIR}/"
chmod +x "${BUILD_DIR}/deploy-on-server.sh"

# Create instructions
cat > "${BUILD_DIR}/DEPLOY_INSTRUCTIONS.txt" << 'EOF'
Deployment Instructions
========================

1. Copy these files to your server:

   scp igloo-site.tar.gz root@your_server:/root/
   scp deploy-on-server.sh root@your_server:/root/

2. SSH to your server:

   ssh root@your_server

3. Run the deployment script:

   cd /root
   chmod +x deploy-on-server.sh
   sudo ./deploy-on-server.sh

That's it! The script will:
- Backup existing deployment
- Extract site to /var/www/iglooventures/public/
- Set proper permissions

After deployment, verify:
- Website: https://iglooventures.biz
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Deployment package created in:"
echo "  ${BUILD_DIR}/"
echo ""
echo "Files:"
ls -lh "${BUILD_DIR}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Copy to server:"
echo "   cd ${BUILD_DIR}"
echo "   scp igloo-site.tar.gz deploy-on-server.sh root@your_server:/root/"
echo ""
echo "2. SSH and deploy:"
echo "   ssh root@your_server"
echo "   cd /root && sudo ./deploy-on-server.sh"
echo ""
cat "${BUILD_DIR}/DEPLOY_INSTRUCTIONS.txt"
