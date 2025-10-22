# Docker Deployment - Quick Start

This guide provides quick commands to deploy the TOU Document Parser using Docker.

## 🚀 Quick Deploy (3 Steps)

### 1. Build and Start the Container

```bash
# Build and start in one command
docker-compose up -d --build
```

### 2. Verify It's Running

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f
```

### 3. Test the Application

```bash
# Test locally
curl http://localhost:5040/

# Or open in browser
http://localhost:5040
```

## 📦 Available Docker Files

- `Dockerfile` - Simple development version
- `Dockerfile.production` - Optimized production version with Gunicorn
- `docker-compose.yml` - Docker Compose configuration

## 🔧 Common Commands

### Start/Stop

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# Restart containers
docker-compose restart
```

### Logs and Debugging

```bash
# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f tou-document-parser

# Access container shell
docker-compose exec tou-document-parser bash
```

### Updates

```bash
# Rebuild after code changes
docker-compose up -d --build

# Force rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

## 🌐 Production Deployment with Nginx

### Using Production Dockerfile

To use the production-optimized Dockerfile:

```bash
# Build with production Dockerfile
docker build -f Dockerfile.production -t tou-document-parser:prod .

# Run the production container
docker run -d \
  --name tou-document-parser \
  --restart unless-stopped \
  -p 5040:5040 \
  -v $(pwd)/uploads:/app/uploads \
  tou-document-parser:prod
```

### Configure Nginx Reverse Proxy

1. Copy nginx configuration:

```bash
sudo cp nginx.conf /etc/nginx/sites-available/ai-reception.tou.edu.kz
sudo ln -s /etc/nginx/sites-available/ai-reception.tou.edu.kz /etc/nginx/sites-enabled/
```

2. Get SSL certificate:

```bash
sudo certbot --nginx -d ai-reception.tou.edu.kz
```

3. Update SSL paths in nginx.conf:

```nginx
ssl_certificate /etc/letsencrypt/live/ai-reception.tou.edu.kz/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ai-reception.tou.edu.kz/privkey.pem;
```

4. Reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 🔐 Security Notes

- The production Dockerfile runs as non-root user `appuser`
- Uploads directory is mounted as a volume for persistence
- Container restarts automatically unless stopped manually
- Health checks ensure the container is responsive

## 📊 Monitoring

### Check Container Health

```bash
# View container health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Inspect health check
docker inspect --format='{{.State.Health.Status}}' tou-document-parser
```

### Resource Usage

```bash
# View resource usage
docker stats tou-document-parser

# View disk usage
docker system df
```

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Check if port is already in use
sudo lsof -i :5040

# Remove old containers and rebuild
docker-compose down -v
docker-compose up -d --build
```

### Permission Issues

```bash
# Fix uploads directory permissions
sudo chown -R $USER:$USER uploads/
chmod 755 uploads/
```

### Out of Disk Space

```bash
# Clean up Docker resources
docker system prune -a

# Remove unused volumes
docker volume prune
```

## 📂 File Structure for Deployment

Minimal files needed on the server:

```
tou_document_parser/
├── Dockerfile or Dockerfile.production
├── docker-compose.yml
├── server.py
├── pyproject.toml
├── web/
├── build/
└── uploads/ (created automatically)
```

## 🔄 Backup and Restore

### Backup Uploads

```bash
# Create backup
tar -czf uploads-backup-$(date +%Y%m%d).tar.gz uploads/

# Restore backup
tar -xzf uploads-backup-YYYYMMDD.tar.gz
```

### Backup Docker Image

```bash
# Save image
docker save tou-document-parser > tou-document-parser.tar

# Load image on another server
docker load < tou-document-parser.tar
```

## ✅ Checklist for Production

- [ ] Docker and Docker Compose installed
- [ ] Domain DNS configured to point to server
- [ ] SSL certificate obtained (Let's Encrypt)
- [ ] Nginx configured as reverse proxy
- [ ] Firewall configured (ports 80, 443, 22)
- [ ] Docker containers set to auto-restart
- [ ] Backup strategy in place
- [ ] Monitoring set up

## 🆘 Support

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)

---

**Server URL**: https://ai-reception.tou.edu.kz/

**Backend Port**: 5040 (internal)

**Web Port**: 80/443 (external via Nginx)
