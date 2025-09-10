# n8n Production Deployment

A complete production-ready deployment of n8n with PostgreSQL database, designed for VM deployment with external nginx reverse proxy.

## Overview

This project provides a simple, one-script deployment of n8n for production use with:

- **n8n** - Latest stable version with production optimizations
- **PostgreSQL 17** - Alpine-based database with persistent storage
- **Security** - Auto-generated encryption keys and secure configurations
- **Health Checks** - Built-in health monitoring for both services
- **Persistence** - Local data storage with proper permissions

## Quick Start

**Just run the setup script:**

```bash
./deploy-n8n.sh
```

That's it! The script will:

1. Update your system
2. Install Docker and Docker Compose
3. Generate secure encryption keys
4. Create the `.env` file with proper configuration
5. Set up data directories with correct permissions

## After Deployment

### 1. Configure Your Domain

Edit the `.env` file to set your actual domain

Update the `N8N_DOMAIN` line:

```
N8N_DOMAIN=your-n8n-domain.com
```

### 2. Start Services With Docker Compose

After updating the domain configuration, you can start the services with Docker Compose:

```bash
docker compose up -d
```

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

## Update N8N

To update n8n run:

```bash
docker compose pull n8n
docker compose up -d n8n
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
- **Execution Pruning**: Old executions cleaned up automatically (14 days)
- **Timezone**: Set to Asia/Jerusalem (configurable)
- **Resource Limits**: Production-optimized concurrency settings

## Troubleshooting

### Services Won't Start

Check logs for errors:

```bash
docker compose logs
```

### n8n Not Accessible

1. Check if services are running: `docker compose ps`
2. Verify your external nginx configuration
3. Ensure your domain points to the server
4. Check firewall allows traffic on port 5678

## Backup

### Database Backup

```bash
docker compose exec postgres pg_dump -U n8n-user n8n > n8n-backup-$(date +%Y%m%d).sql
```

### Full Data Backup

```bash
tar -czf n8n-data-backup-$(date +%Y%m%d).tar.gz data/
```

