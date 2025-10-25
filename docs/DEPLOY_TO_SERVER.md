# 📋 Deployment Summary - TOU Document Parser

## Current Status

- ✅ Project transferred to: `192.168.12.35:/home/user/ai_reception.zip`
- 🎯 Target: Make available at `http://192.168.12.35:5040/`
- 🔮 Future: Domain `ai-reception.tou.edu.kz`

---

## What This Project Is

**TOU Document Parser** is a Flutter web application with a Python Flask backend that:

- Accepts document uploads (PDFs, images)
- Uses OCR (Tesseract) to extract text
- Classifies documents into categories (ID cards, diplomas, certificates, etc.)
- Returns structured data

**Technology Stack:**

- Frontend: Flutter Web (Dart)
- Backend: Flask (Python 3.13)
- OCR: Tesseract
- PDF Processing: pdf2image, Pillow
- Deployment: Docker + Docker Compose

---

## 🚀 How to Deploy (3 Options)

### Option 1: Automated Script ⭐ RECOMMENDED

**Run this on the server (192.168.12.35):**

```bash
# SSH into server
ssh user@192.168.12.35

# Extract project
cd /home/user
unzip ai_reception.zip -d ai-reception
cd ai-reception

# Run automated deployment
./server-deploy.sh
```

**What it does:**

- Checks and installs Docker/Docker Compose
- Optionally installs Flutter
- Builds Flutter web app
- Builds Docker image
- Starts container
- Tests deployment
- Shows you the URL

✅ **This is the easiest way!**

---

### Option 2: Build on Local Machine

**If the server doesn't have Flutter, build locally:**

**Step 1: On your local machine (with Flutter):**

```bash
cd path/to/ai-reception
./build-and-transfer.sh
# Follow the prompts
```

**OR manually:**

```bash
flutter build web --release
scp -r build/web user@192.168.12.35:/home/user/ai-reception/build/
```

**Step 2: On the server:**

```bash
ssh user@192.168.12.35
cd /home/user/ai-reception
docker-compose up -d --build
```

---

### Option 3: Fully Manual

**On the server:**

```bash
# 1. Extract
cd /home/user
unzip ai_reception.zip -d ai-reception
cd ai-reception

# 2. Install Docker (if needed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt-get install -y docker-compose

# Log out and back in

# 3. Build Flutter web app (if Flutter installed)
flutter build web --release
# OR transfer build/web from your local machine

# 4. Deploy with Docker
docker-compose up -d --build

# 5. Check status
docker-compose ps
docker-compose logs -f

# 6. Test
curl http://localhost:5040/
```

---

## 📂 Important Files

### Configuration Files

- `docker-compose.yml` - Docker orchestration
- `Dockerfile` - Docker image definition
- `server.py` - Flask backend server
- `nginx.conf` - For domain setup with HTTPS

### Deployment Scripts

- `server-deploy.sh` - **Automated deployment (USE THIS!)**
- `build-and-transfer.sh` - Build on local machine
- `setup-domain.sh` - Set up domain with Nginx
- `deploy-existing-build.sh` - Deploy if build/web exists

### Documentation

- `QUICKSTART_SERVER.md` - Quick start guide
- `DEPLOYMENT_GUIDE.md` - Detailed deployment steps
- `DEPLOYMENT.md` - Original deployment docs
- `DOCKER.md` - Docker command reference

---

## 🔍 Verification Steps

After deployment, check:

1. **Container is running:**

   ```bash
   docker ps
   # Should show "ai-reception"
   ```

2. **Application responds:**

   ```bash
   curl http://localhost:5040/
   # Should return HTML or JSON
   ```

3. **Logs look good:**

   ```bash
   docker-compose logs
   # Should show Flask server started
   ```

4. **Test in browser:**
   - Open: `http://192.168.12.35:5040/`
   - You should see the Flutter web UI

---

## 🌐 Setting Up Domain (ai-reception.tou.edu.kz)

**After basic deployment works:**

### Step 1: DNS Configuration

Point `ai-reception.tou.edu.kz` to `192.168.12.35` in your DNS

### Step 2: Install Nginx and SSL

```bash
ssh user@192.168.12.35
cd /home/user/ai-reception

# Run automated domain setup
./setup-domain.sh

# OR manually:
sudo apt-get install -y nginx certbot python3-certbot-nginx
sudo certbot --nginx -d ai-reception.tou.edu.kz
```

### Step 3: Test

- HTTP: `http://ai-reception.tou.edu.kz/`
- HTTPS: `https://ai-reception.tou.edu.kz/`

---

## 🆘 Troubleshooting

### Problem: "build/web not found"

**Solution:** Build Flutter web app first

```bash
flutter build web --release
# OR transfer from local machine
```

### Problem: "Docker not found"

**Solution:** Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Problem: "Permission denied" (Docker)

**Solution:** Add user to docker group

```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Problem: Empty page or 404

**Solution:** Check if build/web has index.html

```bash
ls -la build/web/
# Should show index.html, main.dart.js, etc.
```

### Problem: Container won't start

**Solution:** Check logs

```bash
docker-compose logs
# Look for errors
```

### Problem: Port 5040 already in use

**Solution:** Find and kill the process

```bash
sudo lsof -i :5040
sudo kill -9 <PID>
```

---

## 📊 Useful Commands

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

# Shell into container
docker exec -it ai-reception bash

# View container stats
docker stats

# Check disk usage
docker system df
```

---

## 🎯 Quick Command Reference

**On Server (192.168.12.35):**

```bash
# Deploy everything
cd /home/user/ai-reception && ./server-deploy.sh

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart after changes
docker-compose restart

# Full rebuild
docker-compose down && docker-compose up -d --build
```

**On Local Machine (to build and transfer):**

```bash
cd path/to/ai-reception
./build-and-transfer.sh
```

---

## ✅ Success Criteria

You know it's working when:

- ✅ `docker ps` shows container running
- ✅ `curl http://localhost:5040/` returns content
- ✅ Browser shows Flutter web UI at `http://192.168.12.35:5040/`
- ✅ You can upload a document and get OCR results

---

## 🎉 Next Steps After Deployment

1. **Test thoroughly** - Upload various document types
2. **Set up monitoring** - Check logs regularly
3. **Configure backups** - Backup uploads folder
4. **Set up domain** - Configure DNS and SSL
5. **Optimize performance** - Monitor resource usage

---

## 📞 Support

If you get stuck:

1. Check the logs: `docker-compose logs -f`
2. Verify build/web exists: `ls -la build/web/`
3. Check Docker status: `docker ps`
4. Review the error messages carefully
5. Try rebuilding: `docker-compose up -d --build`

---

**🚀 Recommended First Step:**

```bash
ssh user@192.168.12.35
cd /home/user
unzip ai_reception.zip -d ai-reception
cd ai-reception
./server-deploy.sh
```

That's it! The script handles everything else.
