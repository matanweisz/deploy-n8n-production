# n8n Production Deployment

## Overview

This project provides a **fully automated, one-script deployment** of n8n for production use with:

- **n8n** - Latest stable version (1.110.1) with production optimizations
- **PostgreSQL 17** - Alpine-based database with persistent storage
- **Security** - Auto-generated encryption keys and secure configurations
- **Health Checks** - Built-in health monitoring for both services
- **Persistence** - Local data storage with proper permissions
- **Automated Setup** - Complete end-to-end deployment with zero manual configuration

## Prerequisites

- **Operating System**: Ubuntu/Debian-based Linux distribution
- **Server Requirements**: Minimum 2GB RAM (optimized for 16GB)
- **Access**: sudo privileges required
- **Domain**: A domain name pointing to your server (for production use)

## Quick Start

**Just run the setup script and follow the prompts:**

```bash
chmod +x deploy-n8n.sh
./deploy-n8n.sh
```

> **Note**: If you already have a `.env` file from a previous installation, back it up first as the script will overwrite it.

The script will automatically:

1. ✅ Update your system packages
2. ✅ Install Docker and Docker Compose (if not already installed)
3. ✅ Verify all required files are present
4. ✅ Generate secure encryption keys
5. ✅ **Prompt you for your domain name** (interactive)
6. ✅ Create and configure the `.env` file
7. ✅ Set up data directories with correct permissions
8. ✅ **Start all services automatically**
9. ✅ Display service status and next steps

**That's it!** Your n8n instance will be up and running when the script completes.

## After Deployment

Once the script completes successfully, configure your reverse proxy:

### Configure Reverse Proxy (nginx/traefik/caddy)

Point your reverse proxy to forward traffic from your domain to the n8n service:

- **Source**: `https://your-domain.com` (your configured domain)
- **Target**: `http://your-server-ip:5678`
- **SSL/TLS**: Enable HTTPS with certificates (Let's Encrypt recommended)

Example nginx configuration:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support for n8n
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Access Your n8n Instance

Once your reverse proxy is configured, access n8n at:
- **https://your-domain.com** (production URL)
- **http://localhost:5678** (local access for testing)

## Management Commands

### Check Service Status

```bash
docker compose ps
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f n8n
docker compose logs -f postgres
```

### Stop Services

```bash
docker compose down
```

### Start Services

```bash
docker compose up -d
```

## File Structure

```
.
├── deploy-n8n.sh          # Main deployment script
├── docker-compose.yml     # Docker services configuration
├── .env.example          # Environment template
├── .env                  # Generated environment variables (created by script)
├── data/                 # Persistent data (created by script)
│   ├── postgres/         # PostgreSQL data
│   └── n8n/             # n8n data and workflows
└── README.md            # This file
```

## Environment Variables

| Variable             | Description           | Example              |
| -------------------- | --------------------- | -------------------- |
| `N8N_DOMAIN`         | Your n8n domain       | `n8n.yourdomain.com` |
| `POSTGRES_PASSWORD`  | Database password     | Auto-generated       |
| `N8N_ENCRYPTION_KEY` | n8n encryption key    | Auto-generated       |
| `POSTGRES_DB`        | Database name         | `n8n`                |
| `POSTGRES_USER`      | Database user         | `n8n-user`           |
| `N8N_CONCURRENCY`    | Execution concurrency | `20`                 |
| `N8N_LOG_LEVEL`      | Logging level         | `info`               |

## Production Features

- **Security**: Auto-generated secure passwords and encryption keys
- **SSL Ready**: Configured for HTTPS with external reverse proxy
- **Persistent Storage**: Data survives container restarts
- **Health Checks**: Automatic service health monitoring
- **Execution Pruning**: Old executions cleaned up automatically (30 days)
- **Timezone**: Set to Asia/Jerusalem (configurable)
- **Resource Limits**: Optimized for 16GB RAM server with proper CPU/memory allocation

## Configuration Changes

### Change Domain Name

If you need to change your domain after initial setup:

1. Stop the services:
   ```bash
   docker compose down
   ```

2. Edit the `.env` file:
   ```bash
   nano .env
   ```

3. Update the `N8N_DOMAIN` value

4. Restart services:
   ```bash
   docker compose up -d
   ```

### Update n8n Version

To update to a newer version of n8n:

1. Edit `docker-compose.yml` and update the image version
2. Pull the new image and restart:
   ```bash
   docker compose pull n8n
   docker compose up -d n8n
   ```

## Troubleshooting

### Services Won't Start

Check logs for errors:

```bash
docker compose logs
```

### n8n Not Accessible

1. Check if services are running: `docker compose ps`
2. Verify your external reverse proxy configuration
3. Ensure your DNS points to the correct server IP
4. Check firewall allows traffic on port 5678
5. Review logs: `docker compose logs -f n8n`

### Database Connection Issues

If n8n can't connect to PostgreSQL:

```bash
# Check PostgreSQL is healthy
docker compose ps postgres

# View PostgreSQL logs
docker compose logs postgres

# Restart services
docker compose restart
```

## Backup

### Database Backup

```bash
docker compose exec postgres pg_dump -U n8n-user n8n > n8n-backup-$(date +%Y%m%d).sql
```

### Full Data Backup

```bash
tar -czf n8n-data-backup-$(date +%Y%m%d).tar.gz data/
```
