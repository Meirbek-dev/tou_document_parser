# 🚀 Quick Deployment Guide for TOU Document Parser

## Current Situation
- Project transferred to: `192.168.12.35:/home/user/ai_reception.zip`
- Target URL: `http://192.168.12.35:5040/`
- Future domain: `ai-reception.tou.edu.kz`

---

## 📋 Prerequisites Check

SSH into your server:
```bash
ssh user@192.168.12.35
```

Then run these checks:
```bash
# Check if Docker is installed
docker --version

# Check if Docker Compose is installed
docker-compose --version

# Check if Flutter is installed
flutter --version
```

---

## 🎯 Deployment Steps

### Step 1: Extract the Project

```bash
cd /home/user
unzip ai_reception.zip -d ai-reception
cd ai-reception
```

### Step 2: Build Flutter Web App

**Option A: If Flutter is installed on the server**
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer html
```

**Option B: If Flutter is NOT installed (Recommended)**

Install Flutter on Ubuntu:
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Download Flutter
cd /tmp
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
sudo mv flutter /opt/flutter

# Add to PATH
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter --version

# Build the web app
cd /home/user/ai-reception
flutter clean
flutter pub get
flutter build web --release --web-renderer html
```

**Option C: Build on your local machine**

If you have Flutter on your local Windows/Mac machine:
```bash
# On your local machine
cd path/to/ai-reception
flutter build web --release

# Then transfer the build folder to server
scp -r build/web user@192.168.12.35:/home/user/ai-reception/build/
```

### Step 3: Install Docker (if not installed)

```bash
# Update packages
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install -y docker-compose

# Log out and back in, then verify
docker --version
docker-compose --version
```

### Step 4: Deploy with Docker

```bash
cd /home/user/ai-reception

# Make sure build/web exists
ls -la build/web/

# Build and start the Docker container
docker-compose up -d --build
```

### Step 5: Verify Deployment

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Test the application
curl http://localhost:5040/

# Or from another machine
curl http://192.168.12.35:5040/
```

### Step 6: Open in Browser

Open your browser and navigate to:
```
http://192.168.12.35:5040/
```

You should see your Flutter web application! ✅

---

## 🔧 Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs

# Rebuild from scratch
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Empty page or 404 error
```bash
# Verify build/web exists and has files
ls -la build/web/

# If missing, you need to build the Flutter app first
flutter build web --release
```

### Port already in use
```bash
# Check what's using port 5040
sudo lsof -i :5040

# Kill the process or change port in docker-compose.yml
```

---

## 🌐 Setting up Domain (ai-reception.tou.edu.kz)

### Step 1: Install Nginx

```bash
sudo apt-get update
sudo apt-get install -y nginx
```

### Step 2: Configure Nginx

```bash
# Copy the nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/ai-reception.tou.edu.kz

# Enable the site
sudo ln -s /etc/nginx/sites-available/ai-reception.tou.edu.kz /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 3: Get SSL Certificate

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate (make sure DNS is pointing to your server first!)
sudo certbot --nginx -d ai-reception.tou.edu.kz

# Auto-renewal is set up automatically
```

### Step 4: Configure Firewall

```bash
# Allow HTTP, HTTPS, and SSH
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## 🔄 Updating the Application

When you make changes:

```bash
cd /home/user/ai-reception

# Pull latest code (if using git)
git pull

# Rebuild Flutter app (if frontend changed)
flutter build web --release

# Restart Docker container
docker-compose down
docker-compose up -d --build
```

---

## 📊 Useful Commands

```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View logs
docker-compose logs -f ai-reception

# Access container shell
docker exec -it ai-reception bash

# Stop the application
docker-compose down

# Start the application
docker-compose up -d

# Rebuild and restart
docker-compose up -d --build

# Check resource usage
docker stats
```

---

## 🆘 Need Help?

Common issues:

1. **Empty page** → Build Flutter web app first
2. **Connection refused** → Check if Docker container is running
3. **404 errors** → Verify build/web has index.html
4. **Port conflicts** → Change port in docker-compose.yml
5. **Permission errors** → Check file ownership and Docker permissions

---

## ✅ Quick Checklist

- [ ] Extracted ai_reception.zip
- [ ] Flutter installed or web app built
- [ ] Docker and Docker Compose installed
- [ ] build/web directory exists with files
- [ ] Docker container built and running
- [ ] Application accessible on http://192.168.12.35:5040/
- [ ] (Optional) Domain DNS configured
- [ ] (Optional) Nginx installed and configured
- [ ] (Optional) SSL certificate installed

---

**You're all set! 🎉**
