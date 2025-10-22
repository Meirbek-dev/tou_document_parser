#!/bin/bash
# Script to configure Nginx for ai-reception.tou.edu.kz

echo "Setting up Nginx for ai-reception.tou.edu.kz"

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Copy nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/ai-reception.tou.edu.kz

# Update SSL certificate paths (if using Let's Encrypt)
sudo sed -i 's|/etc/nginx/ssl/ai-reception.tou.edu.kz.crt|/etc/letsencrypt/live/ai-reception.tou.edu.kz/fullchain.pem|g' /etc/nginx/sites-available/ai-reception.tou.edu.kz
sudo sed -i 's|/etc/nginx/ssl/ai-reception.tou.edu.kz.key|/etc/letsencrypt/live/ai-reception.tou.edu.kz/privkey.pem|g' /etc/nginx/sites-available/ai-reception.tou.edu.kz

# Enable the site
sudo ln -sf /etc/nginx/sites-available/ai-reception.tou.edu.kz /etc/nginx/sites-enabled/

# Remove default site if exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Reload nginx
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "✓ Nginx configured successfully!"
else
    echo "✗ Nginx configuration test failed. Please check the configuration."
    exit 1
fi

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp

echo ""
echo "Next steps:"
echo "1. Make sure DNS for ai-reception.tou.edu.kz points to 192.168.12.35"
echo "2. Install SSL certificate using certbot:"
echo "   sudo apt-get install certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d ai-reception.tou.edu.kz"
