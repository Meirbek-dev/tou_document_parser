#!/bin/bash
# Simplified deployment script that assumes build/web already exists
# Run this AFTER you've built the Flutter app on your dev machine

set -e

SERVER="user@192.168.12.35"
REMOTE_DIR="~/tou_document_parser"

echo "📦 Simple Deployment Script"
echo "============================="
echo ""

# Check if build/web exists
if [ ! -d "build/web" ]; then
    echo "❌ ERROR: build/web directory not found!"
    echo ""
    echo "You need to build the Flutter web app first."
    echo ""
    echo "On your DEVELOPMENT machine (where you run 'flutter run -d chrome'):"
    echo "  1. Open terminal/command prompt in project directory"
    echo "  2. Run: flutter build web --release"
    echo "  3. Copy the 'build/web' folder to this machine at:"
    echo "     /home/user/ai-reception/build/web/"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Found build/web directory"
echo ""

# Check server connectivity
echo "Checking server connectivity..."
if ! ssh -q $SERVER exit; then
    echo "❌ Cannot connect to server: $SERVER"
    exit 1
fi
echo "✅ Server is reachable"
echo ""

# Show what will be deployed
echo "📊 Build info:"
echo "   Files: $(find build/web -type f | wc -l) files"
echo "   Size: $(du -sh build/web | cut -f1)"
echo ""

read -p "Deploy to $SERVER? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting deployment..."
echo ""

# Transfer build/web
echo "📤 Transferring build/web..."
rsync -avz --progress --delete \
    build/web/ \
    $SERVER:$REMOTE_DIR/build/web/

if [ $? -ne 0 ]; then
    echo "❌ Transfer failed!"
    exit 1
fi

# Transfer server.py and Dockerfile
echo ""
echo "📤 Transferring server files..."
scp server.py Dockerfile $SERVER:$REMOTE_DIR/

# Restart container
echo ""
echo "🔄 Restarting container..."
ssh $SERVER "cd $REMOTE_DIR && docker-compose down && docker-compose up -d --build"

if [ $? -ne 0 ]; then
    echo "❌ Container restart failed!"
    exit 1
fi

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
    echo ""
    echo "Check logs with:"
    echo "  ssh $SERVER 'docker-compose -f $REMOTE_DIR/docker-compose.yml logs --tail=50'"
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 Access your application at:"
echo "   http://192.168.12.35:5040/"
