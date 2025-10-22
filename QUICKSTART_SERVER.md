# 🚀 Quick Start - Deploy on Server

You've transferred the project to `192.168.12.35`. Here's what to do next:

## Option 1: Automated Deployment (Easiest) ⭐

SSH into your server and run the automated script:

```bash
ssh user@192.168.12.35

# Extract the zip
cd /home/user
unzip ai_reception.zip -d ai-reception
cd ai-reception

# Run automated deployment
./server-deploy.sh
```

This script will:

- ✅ Check and install Docker if needed
- ✅ Check and install Flutter if needed (or prompt you)
- ✅ Build the Flutter web app
- ✅ Build and start the Docker container
- ✅ Test the deployment
- ✅ Give you the URL to access

**That's it!** The script handles everything.

---

## Option 2: Manual Deployment

If you prefer manual control:

### Step 1: Extract and setup

```bash
ssh user@192.168.12.35
cd /home/user
unzip ai_reception.zip -d ai-reception
cd ai-reception
```

### Step 2: Build Flutter Web App

**If Flutter is NOT on the server**, build on your local machine:

```bash
# On your local machine (where you have Flutter)
cd path/to/ai-reception
flutter build web --release

# Transfer to server
scp -r build/web user@192.168.12.35:/home/user/ai-reception/build/
```

**If Flutter IS on the server**:

```bash
flutter build web --release --web-renderer html
```

### Step 3: Install Docker (if not installed)

```bash
# Check if Docker is installed
docker --version

# If not, install it
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install -y docker-compose

# Log out and back in for permissions
exit
ssh user@192.168.12.35
cd /home/user/ai-reception
```

### Step 4: Deploy

```bash
# Build and start
docker-compose up -d --build

# Check status
docker-compose ps
docker-compose logs -f
```

### Step 5: Test

Open browser: **http://192.168.12.35:5040/**

---

## 🆘 Troubleshooting

### "build/web not found"

You need to build the Flutter app first. See Step 2 above.

### "Docker not found"

Install Docker. See Step 3 above.

### "Permission denied"

```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### "Port 5040 already in use"

```bash
sudo lsof -i :5040
# Kill the process or change port in docker-compose.yml
```

### Empty page or 404

```bash
# Check if build/web has files
ls -la build/web/

# If empty, rebuild
flutter build web --release
docker-compose restart
```

---

## 📋 Quick Commands

```bash
# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Start
docker-compose up -d

# Rebuild
docker-compose up -d --build
```

---

## ✅ Success Checklist

- [ ] Extracted ai_reception.zip on server
- [ ] Docker installed
- [ ] Flutter web app built (build/web exists)
- [ ] Docker container running
- [ ] Accessible at http://192.168.12.35:5040/

---

**🎯 Recommended: Use Option 1 (Automated Script)**

It handles everything for you automatically!
