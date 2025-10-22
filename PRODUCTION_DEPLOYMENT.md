# 🚀 Production Deployment Guide

## Current Status: ✅ DEPLOYED

Your TOU Document Parser is successfully deployed and running!

- **Current Access**: http://192.168.12.35:5040/
- **Container Status**: Running
- **Backend**: Flask + Python 3.13
- **Frontend**: Flutter Web

---

## 📋 What You've Done

✅ Transferred all project files to server
✅ Built Docker image
✅ Started Docker container
✅ Application is accessible on port 5040

---

## 🌐 Setting Up Domain: ai-reception.tou.edu.kz

### Prerequisites

1. **DNS Configuration**: Ensure that `ai-reception.tou.edu.kz` points to `192.168.12.35`
   - You need to configure this in your DNS provider or internal DNS server
   - Add an A record: `ai-reception.tou.edu.kz` → `192.168.12.35`

2. **Server Access**: You need sudo access on the server

### Step-by-Step Domain Setup

#### 1. SSH into your server
```bash
ssh user@192.168.12.35
cd ~/tou_document_parser
```

#### 2. Run the automated setup script
```bash
chmod +x setup-domain.sh
./setup-domain.sh
```

This script will:
- Install Nginx (if not installed)
- Configure Nginx as a reverse proxy
- Set up HTTP → HTTPS redirect
- Configure firewall rules

#### 3. Get SSL Certificate (for HTTPS)

**Option A: Using Let's Encrypt (Free, Recommended)**
```bash
# Install Certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate (this will automatically configure Nginx)
sudo certbot --nginx -d ai-reception.tou.edu.kz
```

**Option B: Using Your Own SSL Certificate**
```bash
# Place your certificates in /etc/nginx/ssl/
sudo mkdir -p /etc/nginx/ssl
sudo cp your-certificate.crt /etc/nginx/ssl/ai-reception.tou.edu.kz.crt
sudo cp your-private-key.key /etc/nginx/ssl/ai-reception.tou.edu.kz.key

# Set proper permissions
sudo chmod 600 /etc/nginx/ssl/ai-reception.tou.edu.kz.key
sudo chmod 644 /etc/nginx/ssl/ai-reception.tou.edu.kz.crt
```

#### 4. Verify Setup
```bash
# Test Nginx configuration
sudo nginx -t

# If successful, reload Nginx
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx
```

#### 5. Test Your Domain
```bash
# From the server
curl http://ai-reception.tou.edu.kz
curl https://ai-reception.tou.edu.kz  # if SSL is configured
```

From your browser, visit: http://ai-reception.tou.edu.kz

---

## 🔧 Managing Your Application

### View Logs
```bash
ssh user@192.168.12.35
cd ~/tou_document_parser

# View application logs
docker-compose logs -f

# View last 100 lines
docker-compose logs --tail=100
```

### Restart Application
```bash
ssh user@192.168.12.35
cd ~/tou_document_parser

# Restart container
docker-compose restart

# Or stop and start
docker-compose down
docker-compose up -d
```

### Update Application Code
```bash
# On your local machine
cd /home/user/ai-reception

# Transfer updated files
rsync -avz server.py user@192.168.12.35:~/tou_document_parser/

# SSH to server and rebuild
ssh user@192.168.12.35
cd ~/tou_document_parser
docker-compose down
docker-compose up -d --build
```

### Check Container Status
```bash
ssh user@192.168.12.35
docker-compose -f ~/tou_document_parser/docker-compose.yml ps
```

### Access Container Shell (for debugging)
```bash
ssh user@192.168.12.35
docker exec -it tou-document-parser bash
```

---

## 🛡️ Security Considerations

1. **Firewall Configuration**
   ```bash
   sudo ufw enable
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp    # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw status
   ```

2. **Regular Updates**
   ```bash
   # Update system packages
   sudo apt-get update && sudo apt-get upgrade -y

   # Rebuild Docker image with latest dependencies
   cd ~/tou_document_parser
   docker-compose build --no-cache
   docker-compose up -d
   ```

3. **Backup Uploads Folder**
   ```bash
   # The uploads folder is mounted as a volume
   # Backup regularly
   cd ~/tou_document_parser
   tar -czf uploads-backup-$(date +%Y%m%d).tar.gz uploads/
   ```

---

## 📊 Monitoring

### Check Application Health
```bash
# From your local machine
curl http://192.168.12.35:5040/

# Or visit in browser
http://192.168.12.35:5040/
```

### Monitor Resources
```bash
ssh user@192.168.12.35

# Check container resource usage
docker stats tou-document-parser

# Check disk space
df -h

# Check uploads folder size
du -sh ~/tou_document_parser/uploads/
```

---

## 🆘 Troubleshooting

### Application Not Accessible

1. **Check if container is running**
   ```bash
   docker-compose ps
   ```

2. **Check logs for errors**
   ```bash
   docker-compose logs --tail=50
   ```

3. **Verify port is listening**
   ```bash
   sudo netstat -tulpn | grep 5040
   ```

4. **Restart container**
   ```bash
   docker-compose restart
   ```

### Domain Not Working

1. **Check DNS**
   ```bash
   nslookup ai-reception.tou.edu.kz
   ping ai-reception.tou.edu.kz
   ```

2. **Check Nginx status**
   ```bash
   sudo systemctl status nginx
   sudo nginx -t
   ```

3. **Check Nginx logs**
   ```bash
   sudo tail -f /var/log/nginx/ai-reception.access.log
   sudo tail -f /var/log/nginx/ai-reception.error.log
   ```

### SSL Issues

1. **Renew Let's Encrypt certificate**
   ```bash
   sudo certbot renew
   ```

2. **Check certificate expiration**
   ```bash
   sudo certbot certificates
   ```

---

## 📞 Quick Reference Commands

### Deployment Commands
```bash
# Transfer files from local to server
./transfer-to-server.sh user@192.168.12.35

# SSH to server
ssh user@192.168.12.35

# Deploy/Restart application
cd ~/tou_document_parser
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop application
docker-compose down
```

### Nginx Commands
```bash
# Test configuration
sudo nginx -t

# Reload (without downtime)
sudo systemctl reload nginx

# Restart
sudo systemctl restart nginx

# Status
sudo systemctl status nginx
```

---

## 🎯 Current URLs

- **Direct Access**: http://192.168.12.35:5040/
- **Domain (after setup)**: http://ai-reception.tou.edu.kz/
- **HTTPS (after SSL)**: https://ai-reception.tou.edu.kz/

---

## ✅ Deployment Checklist

- [x] Transfer files to server
- [x] Build Docker image
- [x] Start container
- [x] Application accessible on port 5040
- [ ] Configure DNS for ai-reception.tou.edu.kz
- [ ] Install and configure Nginx
- [ ] Get SSL certificate
- [ ] Configure firewall
- [ ] Test domain access
- [ ] Set up monitoring
- [ ] Configure backups

---

**Deployed on**: October 17, 2025
**Server**: 192.168.12.35
**Container**: tou-document-parser
**Status**: ✅ Running
