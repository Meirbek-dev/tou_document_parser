#!/bin/bash
# Automated deployment script for Ubuntu server
# Run this ON THE SERVER after extracting the zip file

set -e

echo "🚀 TOU Document Parser - Server Deployment"
echo "==========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${BLUE}Working directory: $SCRIPT_DIR${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check prerequisites
echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

# Check Docker
if ! command_exists docker; then
    echo -e "${RED}❌ Docker not found!${NC}"
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Docker installed${NC}"
    echo -e "${YELLOW}⚠️  Please log out and log back in for Docker permissions to take effect${NC}"
    echo "Then run this script again."
    exit 0
else
    echo -e "${GREEN}✅ Docker found: $(docker --version)${NC}"
fi

# Check Docker Compose
if ! command_exists docker-compose; then
    echo -e "${RED}❌ Docker Compose not found!${NC}"
    echo "Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✅ Docker Compose found: $(docker-compose --version)${NC}"
fi

# Check Flutter
if ! command_exists flutter; then
    echo -e "${YELLOW}⚠️  Flutter not found${NC}"
    echo ""
    read -p "Do you want to install Flutter on this server? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing Flutter..."
        sudo apt-get update
        sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

        cd /tmp
        wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
        tar xf flutter_linux_3.24.5-stable.tar.xz
        sudo mv flutter /opt/flutter

        # Add to PATH
        echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
        export PATH="$PATH:/opt/flutter/bin"

        cd "$SCRIPT_DIR"
        echo -e "${GREEN}✅ Flutter installed${NC}"
    else
        echo -e "${YELLOW}Skipping Flutter installation.${NC}"
        echo -e "${YELLOW}You'll need to build the web app on another machine and transfer build/web/${NC}"
    fi
else
    echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -1)${NC}"
fi

echo ""

# Step 2: Build Flutter web app
echo -e "${YELLOW}Step 2: Building Flutter web app...${NC}"

if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
    echo -e "${GREEN}✅ build/web directory already exists${NC}"
    read -p "Do you want to rebuild? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping build step."
    else
        if command_exists flutter; then
            echo "Building Flutter web app..."
            flutter clean
            flutter pub get
            flutter build web --release --web-renderer html
            echo -e "${GREEN}✅ Build complete${NC}"
        else
            echo -e "${RED}❌ Cannot rebuild without Flutter${NC}"
        fi
    fi
else
    echo -e "${YELLOW}build/web not found. Building...${NC}"
    if command_exists flutter; then
        flutter clean
        flutter pub get
        flutter build web --release --web-renderer html
        echo -e "${GREEN}✅ Build complete${NC}"
    else
        echo -e "${RED}❌ ERROR: build/web directory not found and Flutter is not installed!${NC}"
        echo ""
        echo "You have two options:"
        echo "1. Install Flutter on this server and rerun this script"
        echo "2. Build the web app on your local machine and transfer build/web here"
        echo ""
        echo "Option 2 instructions:"
        echo "  On your local machine (with Flutter installed):"
        echo "    cd path/to/ai-reception"
        echo "    flutter build web --release"
        echo "    scp -r build/web user@192.168.12.35:/home/user/ai-reception/build/"
        echo ""
        exit 1
    fi
fi

# Verify build
if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}❌ ERROR: build/web/index.html not found!${NC}"
    echo "The Flutter web app was not built successfully."
    exit 1
fi

echo -e "${GREEN}✅ Flutter web app ready${NC}"
echo ""

# Step 3: Create uploads directory
echo -e "${YELLOW}Step 3: Creating uploads directory...${NC}"
mkdir -p uploads
echo -e "${GREEN}✅ Uploads directory ready${NC}"
echo ""

# Step 4: Build and start Docker container
echo -e "${YELLOW}Step 4: Building and starting Docker container...${NC}"

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^tou-document-parser$"; then
    echo "Stopping existing container..."
    docker-compose down
fi

# Build and start
echo "Building Docker image..."
docker-compose build

echo "Starting container..."
docker-compose up -d

echo -e "${GREEN}✅ Docker container started${NC}"
echo ""

# Step 5: Wait for container to be ready
echo -e "${YELLOW}Step 5: Waiting for application to start...${NC}"
sleep 5

# Step 6: Test deployment
echo -e "${YELLOW}Step 6: Testing deployment...${NC}"

# Check container status
if docker ps --format '{{.Names}}' | grep -q "^tou-document-parser$"; then
    echo -e "${GREEN}✅ Container is running${NC}"
else
    echo -e "${RED}❌ Container is not running!${NC}"
    echo "Checking logs..."
    docker-compose logs
    exit 1
fi

# Test HTTP endpoint
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5040/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Application is responding (HTTP $HTTP_CODE)${NC}"
elif [ "$HTTP_CODE" = "404" ]; then
    echo -e "${YELLOW}⚠️  Application returned HTTP 404 (this might be normal if index.html is missing)${NC}"
else
    echo -e "${RED}❌ Application is not responding (HTTP $HTTP_CODE)${NC}"
    echo "Checking logs..."
    docker-compose logs --tail=20
fi

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "📍 Your application is accessible at:"
echo -e "${BLUE}   http://192.168.12.35:5040/${NC}"
echo ""
echo "🔍 Useful commands:"
echo "   View logs:        docker-compose logs -f"
echo "   Stop:             docker-compose down"
echo "   Restart:          docker-compose restart"
echo "   Rebuild:          docker-compose up -d --build"
echo ""

# Check if accessible from outside
EXTERNAL_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Server IP: $EXTERNAL_IP"
echo ""

# Offer to set up domain
echo -e "${YELLOW}Would you like to set up the domain (ai-reception.tou.edu.kz) now? (y/n)${NC}"
read -p "" -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "setup-domain.sh" ]; then
        chmod +x setup-domain.sh
        ./setup-domain.sh
    else
        echo "setup-domain.sh not found. Skipping domain setup."
    fi
fi

echo ""
echo -e "${GREEN}All done! 🚀${NC}"
