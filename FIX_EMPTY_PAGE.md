# 🔧 Fix: Empty Page Issue

## Problem
You're getting an empty page at http://192.168.12.35:5040/ because the Flutter web app hasn't been built for production.

## Solution

You need to build the Flutter web app on your **development machine** (where you normally run `flutter run -d chrome`), then deploy the built files to the server.

---

## 🚀 Quick Fix (Choose ONE method)

### Method 1: Automated Script (Recommended)

On your **development machine** where Flutter is installed:

```bash
# Make script executable
chmod +x build-and-deploy.sh

# Run the script
./build-and-deploy.sh
```

This script will:
1. ✅ Build the Flutter web app
2. ✅ Transfer built files to server
3. ✅ Restart the Docker container
4. ✅ Test the deployment

---

### Method 2: Manual Steps

#### Step 1: Build on Development Machine

On your **Windows/development machine** where you run `flutter run -d chrome`:

```bash
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build for web (production)
flutter build web --release --web-renderer html
```

This creates the `build/web/` directory with your compiled app.

#### Step 2: Transfer to Server

On your **Linux machine** (where you have the project):

```bash
cd /home/user/ai-reception

# Copy the build/web directory from your development machine
# (Use WinSCP, scp, or rsync to get it here first)

# Then transfer to server
rsync -avz --progress --delete build/web/ user@192.168.12.35:~/tou_document_parser/build/web/

# Also transfer updated server.py
scp server.py user@192.168.12.35:~/tou_document_parser/
```

#### Step 3: Update Dockerfile

Transfer the updated Dockerfile:
```bash
scp Dockerfile user@192.168.12.35:~/tou_document_parser/
```

#### Step 4: Restart Container

```bash
ssh user@192.168.12.35
cd ~/tou_document_parser
docker-compose down
docker-compose up -d --build
```

---

## 🧪 Test After Deployment

```bash
# Test from command line
curl http://192.168.12.35:5040/

# Or open in browser
http://192.168.12.35:5040/
```

You should now see your Flutter app instead of an empty page!

---

## 📝 What Changed

### Before (Wrong):
- Server was trying to serve from `web/` (template directory)
- Missing compiled Flutter JavaScript/Dart files
- Result: Empty page

### After (Correct):
- Server serves from `build/web/` (compiled Flutter app)
- Includes all compiled JavaScript, Dart, and assets
- Result: Working Flutter app! ✅

---

## 🔄 Future Updates

Whenever you make changes to your Flutter app:

1. **On development machine:**
   ```bash
   flutter build web --release --web-renderer html
   ```

2. **Transfer and deploy:**
   ```bash
   # Option A: Use the automated script
   ./build-and-deploy.sh

   # Option B: Manual deployment
   rsync -avz build/web/ user@192.168.12.35:~/tou_document_parser/build/web/
   ssh user@192.168.12.35 "cd ~/tou_document_parser && docker-compose restart"
   ```

---

## ❓ Troubleshooting

### If you still see empty page:

1. **Check Docker logs:**
   ```bash
   ssh user@192.168.12.35
   docker-compose -f ~/tou_document_parser/docker-compose.yml logs --tail=50
   ```

2. **Verify build/web exists:**
   ```bash
   ssh user@192.168.12.35
   ls -la ~/tou_document_parser/build/web/
   ```

3. **Check if files are being served:**
   ```bash
   curl -I http://192.168.12.35:5040/
   curl http://192.168.12.35:5040/flutter.js
   ```

4. **Check browser console:**
   - Open http://192.168.12.35:5040/
   - Press F12 (Developer Tools)
   - Check Console tab for errors
   - Check Network tab to see what files are loading

---

## 📋 Required Directory Structure

Your server should have:

```
~/tou_document_parser/
├── server.py
├── pyproject.toml
├── Dockerfile
├── docker-compose.yml
├── build/
│   └── web/              ← This is REQUIRED!
│       ├── index.html
│       ├── main.dart.js
│       ├── flutter.js
│       ├── flutter_service_worker.js
│       ├── assets/
│       └── ... (other compiled files)
└── uploads/
```

---

## 💡 Why This Happens

Flutter web apps need to be **compiled** before deployment:

- **Development**: `flutter run -d chrome` compiles on-the-fly
- **Production**: `flutter build web` creates optimized static files

The `build/web/` directory contains:
- Compiled Dart → JavaScript
- Optimized assets
- Service workers
- All dependencies bundled

Without this build step, you only have templates, not the actual app! 🎯
