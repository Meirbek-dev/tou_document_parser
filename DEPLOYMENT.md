# Docker Deployment Guide for TOU Document Parser

This guide will help you deploy the TOU Document Parser application to your server and make it accessible via https://ai-reception.tou.edu.kz/

## Prerequisites

- A Linux server (Ubuntu 20.04+ or similar)
- Docker and Docker Compose installed
- SSH access to the server
- Domain name configured (ai-reception.tou.edu.kz)
- SSL certificates for the domain

## Step 1: Prepare Your Server

### Install Docker and Docker Compose

```bash
# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose -y

# Verify installation
docker --version
docker-compose --version
```

### Install Nginx (if not already installed)

```bash
sudo apt-get install nginx -y
```

## Step 2: Transfer Files to Server

From your local machine, transfer the project files to the server:

```bash
# Create directory on server
ssh user@192.168.12.35 "mkdir -p ~/tou_document_parser"

# Transfer files using rsync or scp
rsync -avz --exclude 'node_modules' --exclude '.git' \
  /path/to/local/tou_document_parser/ \
  user@192.168.12.35:~/tou_document_parser/

# OR using scp
scp -r tou_document_parser user@192.168.12.35:~/
```

## Step 3: Build and Run Docker Container

SSH into your server and navigate to the project directory:

```bash
ssh user@192.168.12.35
cd ~/tou_document_parser
```

Build and start the Docker container:

```bash
# Build the Docker image
docker-compose build

# Start the container
docker-compose up -d

# Check if container is running
docker-compose ps

# View logs
docker-compose logs -f
```

## Step 4: Configure Nginx as Reverse Proxy

### Set up SSL certificates

If you don't have SSL certificates, use Let's Encrypt:

```bash
# Install Certbot
sudo apt-get install certbot python3-certbot-nginx -y

# Obtain SSL certificate
sudo certbot --nginx -d ai-reception.tou.edu.kz
```

### Configure Nginx

```bash
# Copy the nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/ai-reception.tou.edu.kz

# If using Let's Encrypt, update the nginx.conf with certbot paths
# Edit the file to use Let's Encrypt certificates:
sudo nano /etc/nginx/sites-available/ai-reception.tou.edu.kz
```

Update SSL certificate paths in the file:

```nginx
ssl_certificate /etc/letsencrypt/live/ai-reception.tou.edu.kz/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ai-reception.tou.edu.kz/privkey.pem;
```

Enable the site:

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/ai-reception.tou.edu.kz /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## Step 5: Configure Firewall

```bash
# Allow HTTP, HTTPS, and SSH
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Check status
sudo ufw status
```

## Step 6: Verify Deployment

1. Check if Docker container is running:

```bash
docker-compose ps
docker-compose logs
```

2. Test the backend directly:

```bash
curl http://localhost:5040/
```

3. Access the application via browser:

```
https://ai-reception.tou.edu.kz
```

## Useful Commands

### Docker Management

```bash
# Stop the application
docker-compose down

# Restart the application
docker-compose restart

# View logs
docker-compose logs -f

# Rebuild and restart
docker-compose up -d --build

# Access container shell
docker-compose exec tou-document-parser bash
```

### Nginx Management

```bash
# Reload nginx
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# Check nginx status
sudo systemctl status nginx

# View nginx error logs
sudo tail -f /var/log/nginx/error.log

# View application access logs
sudo tail -f /var/log/nginx/ai-reception.access.log
```

### Troubleshooting

```bash
# Check if port 5040 is listening
sudo netstat -tlnp | grep 5040

# Check Docker container status
docker ps -a

# View container logs
docker logs tou-document-parser

# Check nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## Updating the Application

When you need to update the application:

```bash
# Stop the current container
docker-compose down

# Pull latest changes (if using git)
git pull

# OR transfer updated files from local machine
rsync -avz /path/to/local/tou_document_parser/ user@server-ip:~/tou_document_parser/

# Rebuild and start
docker-compose up -d --build
```

## Auto-start on Boot

Ensure Docker starts on boot:

```bash
sudo systemctl enable docker
sudo systemctl enable nginx
```

The `docker-compose.yml` file includes `restart: unless-stopped`, which ensures the container restarts automatically after system reboot.

## Security Recommendations

1. Keep Docker and system packages updated
2. Use strong passwords for server access
3. Configure automatic SSL certificate renewal:

```bash
sudo certbot renew --dry-run
```

4. Regularly backup the `uploads` directory:

```bash
# Create backup
tar -czf uploads-backup-$(date +%Y%m%d).tar.gz uploads/

# Restore backup
tar -xzf uploads-backup-YYYYMMDD.tar.gz
```

5. Monitor application logs regularly
6. Set up monitoring and alerting (optional)

## Support

For issues or questions, check:

- Docker logs: `docker-compose logs`
- Nginx logs: `/var/log/nginx/`
- Application status: `docker-compose ps`
