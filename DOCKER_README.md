# Docker Deployment Guide

## Overview

This project includes a comprehensive Docker setup designed for deployment on various systems (Windows, macOS, Linux). The setup includes both production and development configurations with optimized multi-stage builds.

## 🐳 Docker Files

### Core Files
- **`Dockerfile`** - Production-ready multi-stage build
- **`Dockerfile.dev`** - Development environment with hot reloading
- **`docker-compose.yml`** - Orchestration for multiple services
- **`.dockerignore`** - Optimizes build context

### Deployment Scripts
- **`deploy.sh`** - Linux/macOS deployment script
- **`deploy.bat`** - Windows deployment script

## 🚀 Quick Start

### Prerequisites
1. **Docker Desktop** installed and running
2. **Git** for cloning the repository

### Option 1: Using Deployment Scripts (Recommended)

#### Windows
```cmd
# Build and run production
deploy.bat build-prod
deploy.bat run-prod

# Build and run development
deploy.bat build-dev
deploy.bat run-dev

# Stop containers
deploy.bat stop

# View logs
deploy.bat logs ai-driven-inventory-prod
```

#### Linux/macOS
```bash
# Make script executable (first time only)
chmod +x deploy.sh

# Build and run production
./deploy.sh build-prod
./deploy.sh run-prod

# Build and run development
./deploy.sh build-dev
./deploy.sh run-dev

# Stop containers
./deploy.sh stop

# View logs
./deploy.sh logs ai-driven-inventory-prod
```

### Option 2: Using Docker Compose

```bash
# Production deployment
docker-compose up -d

# Development deployment
docker-compose --profile development up -d

# Stop all services
docker-compose down
```

### Option 3: Manual Docker Commands

```bash
# Build production image
docker build -t ai-driven-inventory:latest .

# Run production container
docker run -d \
  --name ai-driven-inventory-prod \
  -p 8000:8000 \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  ai-driven-inventory:latest

# Build development image
docker build -f Dockerfile.dev -t ai-driven-inventory:dev .

# Run development container
docker run -d \
  --name ai-driven-inventory-dev \
  -p 8001:8000 \
  -v $(pwd)/app:/app/app \
  -v $(pwd)/utils.py:/app/utils.py \
  -v $(pwd)/artifacts/React:/app/frontend \
  --restart unless-stopped \
  ai-driven-inventory:dev
```

## 🌐 Accessing the Application

### Production Environment
- **Application**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

### Development Environment
- **Application**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs
- **Health Check**: http://localhost:8001/health

## 🔧 Configuration

### Environment Variables

The application supports the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 8000 | Application port |
| `HOST` | 0.0.0.0 | Application host |
| `DATABASE_URL` | sqlite:///./inventory.db | Database connection string |
| `LOG_LEVEL` | INFO | Logging level |
| `ENVIRONMENT` | production | Environment mode |

### Volume Mounts

The containers use the following volume mounts for data persistence:

- **`./data:/app/data`** - Application data directory
- **`./logs:/app/logs`** - Application logs
- **`./app:/app/app`** - Backend source code (development only)
- **`./artifacts/React:/app/frontend`** - Frontend source code (development only)

## 🏗️ Architecture

### Multi-Stage Build Process

1. **Frontend Builder Stage**
   - Uses Node.js 18 Alpine
   - Installs React dependencies
   - Builds production React app

2. **Backend Builder Stage**
   - Uses Python 3.11 Slim
   - Installs Python dependencies
   - Prepares backend code

3. **Production Stage**
   - Minimal Python 3.11 Slim image
   - Copies built frontend and backend
   - Runs as non-root user
   - Includes health checks

### Security Features

- **Non-root user**: Application runs as `appuser`
- **Minimal base image**: Uses slim Python image
- **Health checks**: Built-in container health monitoring
- **Security headers**: CORS and security middleware

## 📊 Monitoring & Logs

### Health Checks
The container includes automatic health checks:
```bash
# Check container health
docker inspect ai-driven-inventory-prod --format='{{.State.Health.Status}}'
```

### Logs
```bash
# View application logs
docker logs -f ai-driven-inventory-prod

# View logs with timestamps
docker logs -f --timestamps ai-driven-inventory-prod
```

### Resource Usage
```bash
# Monitor container resources
docker stats ai-driven-inventory-prod
```

## 🔄 Development Workflow

### Hot Reloading (Development)
The development container supports hot reloading:

1. **Backend**: FastAPI with `--reload` flag
2. **Frontend**: Vite development server
3. **Volume mounts**: Source code changes reflect immediately

### Code Changes
```bash
# Start development container
./deploy.sh run-dev

# Make changes to your code
# Changes are automatically detected and reloaded
```

## 🐛 Troubleshooting

### Common Issues

#### Container won't start
```bash
# Check Docker logs
docker logs ai-driven-inventory-prod

# Check if port is already in use
netstat -an | grep 8000
```

#### Build fails
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t ai-driven-inventory:latest .
```

#### Permission issues (Linux/macOS)
```bash
# Fix volume permissions
sudo chown -R $USER:$USER ./data ./logs
```

### Debugging Commands

```bash
# Enter running container
docker exec -it ai-driven-inventory-prod /bin/bash

# Check container environment
docker exec ai-driven-inventory-prod env

# Test database connection
docker exec ai-driven-inventory-prod python -c "from app.main import engine; print(engine)"
```

## 🚀 Production Deployment

### Recommended Production Setup

1. **Use Docker Compose** for orchestration
2. **Set up reverse proxy** (Nginx) for SSL termination
3. **Configure logging** to external service
4. **Set up monitoring** (Prometheus/Grafana)
5. **Use external database** (PostgreSQL/MySQL)

### Example Production docker-compose.yml
```yaml
version: '3.8'
services:
  app:
    build: .
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/inventory
      - LOG_LEVEL=WARNING
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=inventory
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

## 📝 Maintenance

### Regular Tasks

1. **Update base images**:
   ```bash
   docker pull python:3.11-slim
   docker pull node:18-alpine
   ```

2. **Clean up unused resources**:
   ```bash
   docker system prune -f
   ```

3. **Backup data**:
   ```bash
   docker cp ai-driven-inventory-prod:/app/data ./backup/
   ```

4. **Monitor disk usage**:
   ```bash
   docker system df
   ```

## 🤝 Contributing

When contributing to the Docker setup:

1. **Test on multiple platforms** (Windows, macOS, Linux)
2. **Update documentation** for any changes
3. **Follow security best practices**
4. **Include health checks** for new services
5. **Optimize image size** where possible

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
- [React Production Build](https://create-react-app.dev/docs/production-build/)
- [Docker Security Best Practices](https://docs.docker.com/develop/dev-best-practices/) 