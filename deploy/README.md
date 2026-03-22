# ManAC Deployment Guide

## Overview
This directory contains deployment configuration files for deploying ManAC on a server with Nginx and Bind9.

## Architecture
- **Backend**: Django (running with Gunicorn) - `http://manac_backend.ictu.loc`
- **Frontend**: React (built for production) - `http://manac.ictu.loc`
- **Database**: SQLite (development) or PostgreSQL (production)
- **Web Server**: Nginx as reverse proxy
- **DNS**: Bind9 for local domain resolution

## Requirements
- Ubuntu 20.04+ or Debian 11+
- Python 3.8+
- Node.js 16+
- Nginx
- Bind9

## Files Included
- `nginx/manac_backend.conf` - Nginx config for Django backend
- `nginx/manac_frontend.conf` - Nginx config for React frontend
- `gunicorn/gunicorn.conf.py` - Gunicorn configuration
- `bind9/zone.ictu.loc` - Bind9 zone file
- `.env.production.example` - Environment variables template

## Quick Start

### 1. Backend Deployment
```bash
# Install Python dependencies
cd django_backend
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Start Gunicorn
gunicorn -c gunicorn/gunicorn.conf.py manac.wsgi:application
```

### 2. Frontend Build
```bash
cd react-frontend
npm install
npm run build
```

### 3. Nginx Configuration
```bash
# Copy nginx configs
sudo cp nginx/*.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/manac_backend.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/manac_frontend.conf /etc/nginx/sites-enabled/

# Test nginx config
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### 4. Bind9 Configuration
```bash
# Copy zone file
sudo cp bind9/zone.ictu.loc /etc/bind/zones/

# Add to named.conf.local
# Include the zone configuration

# Restart bind9
sudo systemctl restart bind9
```
