#!/bin/bash

# Deployment script for AI Reception
# This script automates the deployment process on your server

set -e  # Exit on error

echo "=========================================="
echo "AI Reception Deployment Script"
echo "=========================================="

# Configuration
APP_DIR="/opt/ai_reception"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Docker and Docker Compose are installed"

# Create application directory if it doesn't exist
if [ ! -d "$APP_DIR" ]; then
    print_info "Creating application directory: $APP_DIR"
    sudo mkdir -p "$APP_DIR"
    sudo chown $USER:$USER "$APP_DIR"
fi

# Navigate to application directory
cd "$APP_DIR"
print_success "Changed to directory: $APP_DIR"

# Stop existing containers if running
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    print_info "Stopping existing containers..."
    docker-compose down || true
fi

# Build Docker image
print_info "Building Docker image..."
docker-compose build

# Start containers
print_info "Starting containers..."
docker-compose up -d

# Wait for container to be ready
print_info "Waiting for container to be ready..."
sleep 5

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    print_success "Container is running!"

    # Show container status
    echo ""
    print_info "Container Status:"
    docker-compose ps

    echo ""
    print_success "Deployment completed successfully!"
    echo ""
    print_info "You can now access the application at: https://ai-reception.tou.edu.kz"
    print_info "To view logs: docker-compose logs -f"
    print_info "To stop: docker-compose down"
else
    print_error "Container failed to start. Check logs with: docker-compose logs"
    exit 1
fi
