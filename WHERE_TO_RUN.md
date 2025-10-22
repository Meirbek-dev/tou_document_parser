# 🚨 IMPORTANT: Where to Run What

## The Problem
You're trying to run `build-and-deploy.sh` on **cs01 (Linux server)**, but this script needs Flutter which is only on your **development machine**.

---

## ✅ CORRECT Way to Deploy

### You Have 2 Machines:

1. **Development Machine** (Windows) - Where you run `flutter run -d chrome`
2. **Linux Server** (cs01) - Where you're currently logged in at `/home/user/ai-reception`

---

## 📋 Step-by-Step Instructions

### Option 1: Build on Development Machine, Deploy from cs01

#### Step 1: On Your Windows Development Machine

Open Command Prompt or PowerShell in your project directory:

```bash
# Build the Flutter web app
flutter build web --release
```

This creates `build/web/` folder.

#### Step 2: Transfer build/web to cs01

Use **WinSCP** or **FileZilla** to transfer the `build/web` folder from your Windows machine to:
```
/home/user/ai-reception/build/web/
```

**Or** use command line (in PowerShell on Windows):
```powershell
# Assuming you have SSH access from Windows
scp -r build/web user@cs01-ip:/home/user/ai-reception/build/
```

#### Step 3: On cs01 (where you are now)

Once `build/web` is in place:

```bash
cd /home/user/ai-reception

# Run the simplified deployment script
./deploy-existing-build.sh
```

This will:
- Check if build/web exists ✅
- Transfer it to 192.168.12.35
- Restart the Docker container
- Test the deployment

---

### Option 2: Build AND Deploy from Development Machine

If your **Windows development machine** can SSH to both cs01 and 192.168.12.35:

#### On Your Windows Development Machine:

```bash
# In your project directory
flutter build web --release

# Then transfer to cs01
scp -r build/web user@cs01-ip:/home/user/ai-reception/build/
scp server.py Dockerfile user@cs01-ip:/home/user/ai-reception/

# Then SSH to cs01 and deploy
ssh user@cs01-ip
cd /home/user/ai-reception
./deploy-existing-build.sh
```

---

### Option 3: Quick Manual Deployment

If you already have `build/web` on cs01:

```bash
cd /home/user/ai-reception

# Transfer to deployment server
rsync -avz --delete build/web/ user@192.168.12.35:~/tou_document_parser/build/web/

# Transfer updated files
scp server.py Dockerfile user@192.168.12.35:~/tou_document_parser/

# Restart
ssh user@192.168.12.35 "cd ~/tou_document_parser && docker-compose down && docker-compose up -d --build"

# Test
curl http://192.168.12.35:5040/
```

---

## ❌ What NOT to Do

**DON'T** run `build-and-deploy.sh` on cs01 - it will hang because Flutter is not installed there!

---

## 🔍 Current Situation Check

Run this to see what you have:

```bash
cd /home/user/ai-reception

# Check if build/web exists
if [ -d "build/web" ]; then
    echo "✅ build/web exists!"
    echo "Files: $(find build/web -type f | wc -l)"
    ls -la build/web/ | head -10
else
    echo "❌ build/web NOT found - you need to build Flutter app first"
fi
```

---

## 📞 Quick Commands

### If you have build/web ready:
```bash
./deploy-existing-build.sh
```

### If you DON'T have build/web:
You need to get it from your Windows development machine first!

---

## 🎯 TL;DR (Summary)

1. **Build** on Windows: `flutter build web --release`
2. **Copy** `build/web` to cs01 at `/home/user/ai-reception/build/web/`
3. **Deploy** from cs01: `./deploy-existing-build.sh`
4. **Access**: http://192.168.12.35:5040/

That's it! 🚀
