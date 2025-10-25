# Quick Setup Instructions

## For Windows Users (PowerShell)

### Transfer files to server:

```powershell
.\transfer-to-server.ps1 -Server "user@192.168.12.35"
```

### Connect to server:

```powershell
ssh user@192.168.12.35
```

## For Linux/Mac Users

### Make scripts executable:

```bash
chmod +x deploy.sh test-deployment.sh transfer-to-server.sh
```

### Transfer files to server:

```bash
./transfer-to-server.sh user@192.168.12.35
```

### Connect to server:

```bash
ssh user@192.168.12.35
```

## On the Server (After SSH)

### 1. Make scripts executable:

```bash
cd /opt/ai_reception
chmod +x deploy.sh test-deployment.sh
```

### 2. Deploy the application:

```bash
./deploy.sh
```

### 3. Test the deployment:

```bash
./test-deployment.sh
```

### 4. Configure domain (one-time setup):

```bash
# Install Nginx
sudo apt-get update
sudo apt-get install nginx certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d ai-reception.tou.edu.kz

# Configure Nginx
sudo cp nginx.conf /etc/nginx/sites-available/ai-reception.tou.edu.kz

# Edit SSL paths
sudo nano /etc/nginx/sites-available/ai-reception.tou.edu.kz
# Update these lines:
#   ssl_certificate /etc/letsencrypt/live/ai-reception.tou.edu.kz/fullchain.pem;
#   ssl_certificate_key /etc/letsencrypt/live/ai-reception.tou.edu.kz/privkey.pem;

# Enable site
sudo ln -s /etc/nginx/sites-available/ai-reception.tou.edu.kz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Configure firewall:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Verification

Visit: https://ai-reception.tou.edu.kz

## Need Help?

- View container logs: `docker-compose logs -f`
- Check container status: `docker-compose ps`
- Restart application: `docker-compose restart`
- Full documentation: See DEPLOYMENT.md
