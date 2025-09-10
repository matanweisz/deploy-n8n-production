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

# Start Docker service
echo "🔄 Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Start N8N services
echo "🎯 Starting N8N services..."
sudo docker compose up -d
