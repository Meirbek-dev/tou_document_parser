#!/bin/bash
# Quick deployment update script
# Usage: ./quick-update.sh

SERVER="user@192.168.12.35"
REMOTE_DIR="~/tou_document_parser"

echo "🚀 Quick Update Deployment"
echo "=========================="
echo ""

# Check if server is reachable
echo "Checking server connectivity..."
if ! ssh -q $SERVER exit; then
    echo "❌ Cannot connect to server: $SERVER"
    exit 1
fi
echo "✅ Server is reachable"
echo ""

# Transfer updated files
echo "📤 Transferring files..."
rsync -avz --progress \
    server.py \
    pyproject.toml \
    web/ \
    build/flutter_assets/ \
    $SERVER:$REMOTE_DIR/

if [ $? -ne 0 ]; then
    echo "❌ File transfer failed"
    exit 1
fi
echo "✅ Files transferred"
echo ""

# Rebuild and restart
echo "🔄 Rebuilding and restarting container..."
ssh $SERVER "cd $REMOTE_DIR && docker-compose down && docker-compose up -d --build"

if [ $? -ne 0 ]; then
    echo "❌ Container restart failed"
    exit 1
fi
echo "✅ Container restarted"
echo ""

# Wait a moment for container to start
echo "⏳ Waiting for application to start..."
sleep 5

# Check status
echo "📊 Checking container status..."
ssh $SERVER "docker-compose -f $REMOTE_DIR/docker-compose.yml ps"
echo ""

# Test application
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
echo ""
echo "📝 View logs with:"
echo "   ssh $SERVER 'docker-compose -f $REMOTE_DIR/docker-compose.yml logs -f'"
