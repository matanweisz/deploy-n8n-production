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

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &>/dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed successfully"
else
    echo "✅ Docker Compose already installed"
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

# Create data directories and set permissions
echo "📁 Creating data directories..."
mkdir -p data/postgres data/n8n
sudo chown -R 999:999 data/postgres # PostgreSQL user
sudo chown -R 1000:1000 data/n8n    # Node user for n8n

echo ""
echo "🎉 N8N deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Update your .env file with your actual domain name:"
echo "   N8N_DOMAIN=your-domain.com"
echo ""
echo "2. Configure your external nginx to proxy to this server"
echo "   The n8n service will be available on port 5678"
echo ""
echo "3. Start the services after updating .env:"
echo "   docker compose up -d"
echo ""
echo "4. Check services status:"
echo "   docker compose ps"
echo "   docker compose logs -f"
