#!/bin/bash

# ManAC Deployment Script with uWSGI and Nginx

set -e

echo "=== ManAC Deployment with uWSGI + Nginx ==="

# Update package list
echo "[1/8] Updating package list..."
apt-get update

# Install uWSGI and Python plugins
echo "[2/8] Installing uWSGI and dependencies..."
apt-get install -y uwsgi uwsgi-plugin-python3 python3-pip nginx

# Create virtual environment (if needed)
echo "[3/8] Setting up Python virtual environment..."
cd /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/django_backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Collect static files
echo "[4/8] Collecting static files..."
python manage.py collectstatic --noinput

# Create required directories
echo "[5/8] Creating required directories..."
mkdir -p /run/uwsgi
mkdir -p /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/django_backend/static
mkdir -p /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/django_backend/media

# Set permissions
echo "[6/8] Setting permissions..."
chown -R www-data:www-data /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/django_backend
chmod -R 755 /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/django_backend

# Copy uWSGI configuration
echo "[7/8] Configuring uWSGI..."
cp /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/deploy/uwsgi/manac_uwsgi.ini /etc/uwsgi/apps-available/
ln -sf /etc/uwsgi/apps-available/manac_uwsgi.ini /etc/uwsgi/apps-enabled/

# Copy Nginx configuration
echo "[8/8] Configuring Nginx..."
cp /media/eye-of-god/IVAN/script/common/Mobile/Managements/ManAc/deploy/nginx/manac_backend.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/manac_backend.conf /etc/nginx/sites-enabled/

# Test and reload Nginx
nginx -t
systemctl reload nginx

# Start uWSGI
systemctl restart uwsgi

echo "=== Deployment Complete ==="
echo "Backend should be available at http://manac_backend.ictu.loc"
echo ""
echo "To check status:"
echo "  systemctl status uwsgi"
echo "  systemctl status nginx"
echo ""
echo "To view logs:"
echo "  journalctl -u uwsgi -f"
echo "  tail -f /var/log/nginx/error.log"
