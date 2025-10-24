#!/bin/bash
# Build and Deploy Script for TOU Document Parser
# Run this on your DEVELOPMENT machine (where Flutter is installed)

set -e

echo "🏗️  Building Flutter Web App for Production"
echo "============================================"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found!"
    echo ""
    echo "Please run this script on your development machine where Flutter is installed."
    echo "Or install Flutter first."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build web app for production
echo "🔨 Building web app (this may take a minute)..."
flutter build web --release --web-renderer html

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Check if build/web exists
if [ ! -d "build/web" ]; then
    echo "❌ build/web directory not found!"
    exit 1
fi

echo "📊 Build output:"
ls -lh build/web/ | head -10
echo ""

# Ask for deployment
read -p "Do you want to deploy to server 192.168.12.35? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Deploying to server..."
    echo ""

    SERVER="user@192.168.12.35"
    REMOTE_DIR="~/tou_document_parser"

    # Transfer files
    echo "📤 Transferring files..."
    rsync -avz --progress --delete \
        build/web/ \
        $SERVER:$REMOTE_DIR/build/web/

    rsync -avz --progress \
        server.py \
        pyproject.toml \
        $SERVER:$REMOTE_DIR/

    # Restart container
    echo ""
    echo "🔄 Restarting container..."
    ssh $SERVER "cd $REMOTE_DIR && docker-compose down && docker-compose up -d --build"

    echo ""
    echo "⏳ Waiting for application to start..."
    sleep 5

    # Test
    echo "🧪 Testing application..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.12.35:5040/)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Application is responding (HTTP $HTTP_CODE)"
    else
        echo "⚠️  Application returned HTTP $HTTP_CODE"
    fi

    echo ""
    echo "🎉 Deployment complete!"
    echo ""
    echo "📍 Access your application at:"
    echo "   http://192.168.12.35:5040/"
else
    echo ""
    echo "ℹ️  Build complete but not deployed."
    echo ""
    echo "To deploy manually, run:"
    echo "  rsync -avz build/web/ user@192.168.12.35:~/tou_document_parser/build/web/"
    echo "  ssh user@192.168.12.35 'cd ~/tou_document_parser && docker-compose restart'"
fi
