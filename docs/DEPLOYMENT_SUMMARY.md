# TOU Document Parser - Docker Deployment Summary

## 📋 Overview

Your Flutter web application with Python backend is now containerized and ready for deployment to **https://ai-reception.tou.edu.kz/**

## 📦 Created Files

### Docker Files

1. **Dockerfile** - Simple Docker image for development/testing
2. **Dockerfile.production** - Optimized production image with Gunicorn and security hardening
3. **docker-compose.yml** - Docker Compose configuration for easy deployment
4. **.dockerignore** - Excludes unnecessary files from Docker image

### Configuration Files

5. **nginx.conf** - Nginx reverse proxy configuration for HTTPS
6. **server.py** (updated) - Backend now supports both Windows and Linux/Docker environments

### Deployment Scripts

7. **deploy.sh** - Automated deployment script for Linux server
8. **transfer-to-server.sh** - Script to transfer files to server (Linux/Mac)
9. **transfer-to-server.ps1** - Script to transfer files to server (Windows PowerShell)

### Documentation

10. **DEPLOYMENT.md** - Complete step-by-step deployment guide
11. **DOCKER.md** - Quick reference for Docker commands
12. **DEPLOYMENT_SUMMARY.md** - This file

## 🚀 Quick Start (For You)

Since you're on Windows, use PowerShell:

### Step 1: Transfer Files to Server

```powershell
.\transfer-to-server.ps1 -Server "user@your-server-ip"
```

Replace `user@your-server-ip` with your actual server SSH credentials.

### Step 2: SSH into Server

```powershell
ssh user@your-server-ip
```

### Step 3: Deploy

```bash
cd /opt/ai_reception
chmod +x deploy.sh
./deploy.sh
```

### Step 4: Configure Domain and SSL

```bash
# Install Nginx if not installed
sudo apt-get install nginx -y

# Get SSL certificate
sudo apt-get install certbot python3-certbot-nginx -y
sudo certbot --nginx -d ai-reception.tou.edu.kz

# Copy and configure Nginx
sudo cp nginx.conf /etc/nginx/sites-available/ai-reception.tou.edu.kz

# Edit to use Let's Encrypt certificates
sudo nano /etc/nginx/sites-available/ai-reception.tou.edu.kz
```

Update these lines:

```nginx
ssl_certificate /etc/letsencrypt/live/ai-reception.tou.edu.kz/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ai-reception.tou.edu.kz/privkey.pem;
```

Enable and restart:

```bash
sudo ln -s /etc/nginx/sites-available/ai-reception.tou.edu.kz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🎯 What Changed in Your Code

### server.py Updates

The Python server now automatically detects if it's running on Windows or Linux:

- **Windows**: Uses your existing Tesseract paths (`C:\tools\tesseract\`)
- **Linux/Docker**: Uses standard Linux paths (`/usr/share/tesseract-ocr/`)

This means:

- ✅ Your local development on Windows still works
- ✅ Docker container works in production
- ✅ No manual configuration needed

## 🏗️ Architecture

```
Internet (HTTPS)
    ↓
Nginx (Port 443)
    ↓
Docker Container (Port 5040)
    ↓
Flask Application
    ↓
Tesseract OCR + PDF Processing
```

## 🔧 Key Features

### Docker Configuration

- **Base Image**: Python 3.13 slim
- **OCR Support**: Tesseract with Russian and English languages
- **PDF Support**: Poppler utils for PDF processing
- **Production**: Gunicorn WSGI server (4 workers, 2 threads each)
- **Security**: Runs as non-root user
- **Health Checks**: Automatic container health monitoring
- **Persistence**: Uploads directory mounted as volume

### Nginx Configuration

- **HTTPS**: SSL/TLS support
- **File Uploads**: 100MB max upload size
- **Timeouts**: Extended timeouts for file processing (600 seconds)
- **Proxy Headers**: Proper forwarding of client information
- **Logging**: Separate access and error logs

## 📊 Port Configuration

- **5040**: Flask application (internal to server)
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS (public access)

## 🔐 Security Features

1. **Non-root Container**: Application runs as user `appuser` (UID 1000)
2. **HTTPS Only**: All HTTP traffic redirected to HTTPS
3. **SSL/TLS**: Modern encryption protocols (TLS 1.2+)
4. **File Validation**: Secure filename handling
5. **Environment Isolation**: Application isolated in Docker container

## 📁 Directory Structure on Server

```
/opt/ai_reception/
├── Dockerfile
├── Dockerfile.production
├── docker-compose.yml
├── server.py
├── pyproject.toml
├── nginx.conf
├── deploy.sh
├── web/
│   ├── index.html
│   └── manifest.json
├── build/
│   └── flutter_assets/
└── uploads/ (created automatically)
```

## 🧪 Testing Checklist

After deployment, verify:

- [ ] Container is running: `docker-compose ps`
- [ ] Backend responds: `curl http://localhost:5040/`
- [ ] Domain resolves: `nslookup ai-reception.tou.edu.kz`
- [ ] SSL works: Visit `https://ai-reception.tou.edu.kz`
- [ ] File upload works: Test document upload
- [ ] OCR processing works: Upload PDF and verify classification
- [ ] Logs are clean: `docker-compose logs`

## 🔄 Maintenance Commands

### View Logs

```bash
docker-compose logs -f
```

### Restart Application

```bash
docker-compose restart
```

### Update Application

```bash
# Transfer new files
# Then:
docker-compose down
docker-compose up -d --build
```

### Backup Uploads

```bash
tar -czf uploads-backup-$(date +%Y%m%d).tar.gz uploads/
```

### View Resource Usage

```bash
docker stats ai-reception
```

## 🆘 Troubleshooting

### Container Won't Start

```bash
docker-compose logs
docker-compose down -v
docker-compose up -d --build
```

### Port Already in Use

```bash
sudo lsof -i :5040
# Kill the process or change port in docker-compose.yml
```

### Permission Errors

```bash
sudo chown -R $USER:$USER uploads/
chmod 755 uploads/
```

### SSL Certificate Issues

```bash
sudo certbot renew --dry-run
sudo systemctl reload nginx
```

## 📞 Support Resources

1. **DEPLOYMENT.md** - Complete deployment guide
2. **DOCKER.md** - Docker command reference
3. Docker logs: `docker-compose logs -f`
4. Nginx logs: `/var/log/nginx/ai-reception.*.log`

## ✅ Deployment Checklist

### Prerequisites

- [ ] Linux server with Ubuntu 20.04+ or similar
- [ ] Docker and Docker Compose installed
- [ ] Domain DNS configured to point to server IP
- [ ] SSH access to server
- [ ] Firewall allows ports 80, 443, 22

### Deployment Steps

- [ ] Files transferred to server
- [ ] Docker container built and running
- [ ] Nginx installed and configured
- [ ] SSL certificate obtained
- [ ] Domain accessible via HTTPS
- [ ] Application tested and working

### Post-Deployment

- [ ] Automatic container restart configured
- [ ] Backup strategy in place
- [ ] Monitoring set up (optional)
- [ ] SSL auto-renewal configured

## 🎉 Success Criteria

Your deployment is successful when:

1. ✅ You can access https://ai-reception.tou.edu.kz
2. ✅ SSL certificate is valid (green lock in browser)
3. ✅ You can upload a document
4. ✅ The document is classified correctly
5. ✅ Container auto-restarts after server reboot

## 📚 Additional Information

- **Container Name**: `ai_reception`
- **Image Name**: `ai_reception-ai_reception`
- **Network**: `app-network` (bridge)
- **Restart Policy**: `unless-stopped`
- **Health Check**: Every 30 seconds

---

## 🚀 Ready to Deploy?

Follow the Quick Start section above or refer to **DEPLOYMENT.md** for detailed instructions.

Good luck with your deployment! 🎯
