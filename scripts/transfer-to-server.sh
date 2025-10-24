#!/bin/bash

# Script to transfer files to server for deployment
# Usage: ./transfer-to-server.sh user@server-ip

set -e

# Check if server address is provided
if [ -z "$1" ]; then
    echo "Usage: $0 user@192.168.12.35"
    echo "Example: $0 user@192.168.12.35"
    exit 1
fi

SERVER=$1
REMOTE_DIR="/opt/tou_document_parser"

echo "=========================================="
echo "Transfer Files to Server"
echo "=========================================="
echo "Server: $SERVER"
echo "Remote Directory: $REMOTE_DIR"
echo ""

# Create remote directory
echo "Creating remote directory..."
ssh $SERVER "mkdir -p $REMOTE_DIR"

# Files and directories to transfer
echo "Transferring files..."
rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '.dart_tool' \
    --exclude 'build/' \
    --exclude 'android/' \
    --exclude 'ios/' \
    --exclude 'linux/' \
    --exclude 'macos/' \
    --exclude 'windows/' \
    --exclude 'lib/' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude '.venv' \
    --exclude 'venv' \
    --exclude 'uploads/*' \
    Dockerfile \
    Dockerfile.production \
    docker-compose.yml \
    server.py \
    pyproject.toml \
    nginx.conf \
    deploy.sh \
    web/ \
    build/ \
    $SERVER:$REMOTE_DIR/

echo ""
echo "✓ Files transferred successfully!"
echo ""
echo "Next steps:"
echo "1. SSH into your server: ssh $SERVER"
echo "2. Navigate to directory: cd $REMOTE_DIR"
echo "3. Run deployment: chmod +x deploy.sh && ./deploy.sh"
echo ""
