#!/bin/bash
# Helper script to build and transfer from your development machine
# Run this on your LOCAL machine (where Flutter is installed)

set -e

echo "📦 Build and Transfer to Server"
echo "================================"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found!"
    echo "Please install Flutter first or run this on a machine with Flutter installed."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Clean and build
echo "🧹 Cleaning previous build..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Building web app for production..."
flutter build web --release --web-renderer html

if [ ! -d "build/web" ]; then
    echo "❌ Build failed - build/web not found"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "📊 Build contents:"
ls -lh build/web/ | head -10
echo ""

# Ask for server details
read -p "Enter server address (e.g., user@192.168.12.35): " SERVER

if [ -z "$SERVER" ]; then
    echo "❌ Server address is required"
    exit 1
fi

read -p "Enter remote path (default: /home/user/ai-reception): " REMOTE_PATH
REMOTE_PATH=${REMOTE_PATH:-/home/user/ai-reception}

echo ""
echo "📤 Transferring build/web to $SERVER:$REMOTE_PATH/build/"
echo ""

# Create remote directory
ssh "$SERVER" "mkdir -p $REMOTE_PATH/build"

# Transfer build/web
rsync -avz --progress --delete build/web/ "$SERVER:$REMOTE_PATH/build/web/"

if [ $? -ne 0 ]; then
    echo "❌ Transfer failed"
    exit 1
fi

echo ""
echo "✅ Transfer complete!"
echo ""

# Ask if they want to deploy
read -p "Deploy on server now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Deploying on server..."
    ssh "$SERVER" "cd $REMOTE_PATH && docker-compose up -d --build"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Deployment complete!"
        echo ""
        echo "📍 Application should be available at:"
        echo "   http://192.168.12.35:5040/"
    else
        echo ""
        echo "❌ Deployment failed. Check logs with:"
        echo "   ssh $SERVER 'cd $REMOTE_PATH && docker-compose logs'"
    fi
else
    echo ""
    echo "To deploy manually on the server, run:"
    echo "  ssh $SERVER"
    echo "  cd $REMOTE_PATH"
    echo "  docker-compose up -d --build"
fi

echo ""
echo "🎉 Done!"
