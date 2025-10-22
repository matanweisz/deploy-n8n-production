#!/bin/bash

# =============================================================================
# N8N AWS Deployment Script
# =============================================================================

set -e # Exit on any error

echo "🚀 Starting N8N Deployment"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root"
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Start Docker service
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Check if user was added to docker group and inform about restart
if groups $USER | grep -q '\bdocker\b'; then
    echo "✅ User already in docker group"
else
    echo "⚠️  User added to docker group - you may need to logout and login again"
    echo "    Or run: newgrp docker"
fi

# Verify Docker Compose is available (modern Docker includes it)
echo "🔧 Checking Docker Compose availability..."
if docker compose version &>/dev/null; then
    echo "✅ Docker Compose (plugin) is available"
elif command -v docker-compose &>/dev/null; then
    echo "✅ Docker Compose (standalone) is available"
else
    echo "📥 Installing Docker Compose plugin..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    echo "✅ Docker Compose installed successfully"
fi

# Verify required files exist
echo "🔍 Verifying project files..."
if [ ! -f .env.example ]; then
    echo "❌ Error: .env.example file not found!"
    echo "   Please ensure you're running this script from the project directory."
    exit 1
fi
if [ ! -f docker-compose.yml ]; then
    echo "❌ Error: docker-compose.yml file not found!"
    echo "   Please ensure you're running this script from the project directory."
    exit 1
fi
echo "✅ All required files found"

# Ensure openssl is installed for key generation
if ! command -v openssl &>/dev/null; then
    echo "📦 Installing openssl..."
    sudo apt-get update
    sudo apt-get install -y openssl
fi

# Create .env file from example
echo "📝 Creating .env file..."
cp .env.example .env

# Generate and replace security keys
echo "🔐 Generating security keys..."
POSTGRES_PASSWORD=$(openssl rand -base64 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Use | as delimiter to avoid issues with special characters
sed -i "s|secure-postgres-password|${POSTGRES_PASSWORD}|g" .env
sed -i "s|n8n-encryption-key|${N8N_ENCRYPTION_KEY}|g" .env

# Make .env file secure
sudo chmod 600 .env

echo "✅ Security keys generated and updated in .env file"

# Prompt for domain name
echo ""
echo "🌐 Domain Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Enter the domain name for your n8n instance"
echo "Example: n8n.yourdomain.com"
echo ""
read -p "Domain name: " N8N_DOMAIN

# Validate domain is not empty
while [ -z "$N8N_DOMAIN" ]; do
    echo "❌ Domain name cannot be empty"
    read -p "Domain name: " N8N_DOMAIN
done

# Update domain in .env file
sed -i "s|N8N_DOMAIN=<your-domain.com>|N8N_DOMAIN=${N8N_DOMAIN}|g" .env

echo "✅ Domain configured: $N8N_DOMAIN"

# Create data directories and set permissions
echo "📁 Creating data directories..."
mkdir -p data/postgres data/n8n
sudo chown -R 999:999 data/postgres # PostgreSQL user
sudo chown -R 1000:1000 data/n8n    # Node user for n8n

# Start services with Docker Compose
echo ""
echo "🚢 Starting n8n services..."
if docker compose version &>/dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

# Wait a moment for services to initialize
sleep 5

# Check service status
echo ""
echo "📊 Service Status:"
if docker compose version &>/dev/null; then
    docker compose ps
else
    docker-compose ps
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 N8N Deployment Completed Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Services Started:"
echo "   • PostgreSQL Database"
echo "   • n8n Workflow Automation"
echo ""
echo "🌐 Your n8n instance:"
echo "   Domain: https://$N8N_DOMAIN"
echo "   Local: http://localhost:5678"
echo ""
echo "📋 Next Steps:"
echo "   1. Configure your external reverse proxy (nginx/traefik) to:"
echo "      • Proxy https://$N8N_DOMAIN to http://YOUR_SERVER_IP:5678"
echo "      • Enable SSL/TLS certificates"
echo "   2. Ensure your DNS points $N8N_DOMAIN to your server"
echo "   3. Access n8n at https://$N8N_DOMAIN to complete setup"
echo ""
echo "📊 Useful Commands:"
echo "   • View logs:    docker compose logs -f"
echo "   • Stop services: docker compose down"
echo "   • Restart:      docker compose restart"
