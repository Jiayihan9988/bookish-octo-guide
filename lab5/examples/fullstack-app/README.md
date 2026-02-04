# Full Stack Application Example

This is a complete Docker multi-container application example, including:

- **Frontend**: Nginx + HTML/CSS/JavaScript
- **Backend**: Flask (Python) REST API
- **Database**: MySQL 8.0

## Quick Start

```bash
# Enter project directory
cd /home/3/examples/fullstack-app

# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

## Access the Application

- **Frontend Interface**: http://localhost:8080
- **Backend API**: http://localhost:5000/api/health

## Test API

```bash
# Health check
curl http://localhost:5000/api/health

# Get user list
curl http://localhost:5000/api/users

# Add user
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'
```

## Management Commands

```bash
# Stop services
docker-compose stop

# Start services
docker-compose start

# Restart services
docker-compose restart

# View logs
docker-compose logs backend
docker-compose logs db

# Enter container
docker exec -it fullstack-backend bash
docker exec -it fullstack-db mysql -ppassword

# Remove all services
docker-compose down

# Remove all services and data
docker-compose down -v
```

## Project Structure

```
fullstack-app/
├── backend/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── frontend/
│   └── index.html
├── database/
│   └── init.sql
├── docker-compose.yml
└── README.md
```

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Docker Network (app-network)    │
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────┐ │
│  │ Frontend │  │ Backend  │  │  DB   │ │
│  │  Nginx   │→ │  Flask   │→ │ MySQL │ │
│  │  :8080   │  │  :5000   │  │ :3306 │ │
│  └──────────┘  └──────────┘  └───────┘ │
│                                         │
└─────────────────────────────────────────┘
```

## Features

- ✅ User Management (CRUD)
- ✅ Data Persistence
- ✅ Health Checks
- ✅ Auto-restart
- ✅ Inter-container Communication
- ✅ Responsive Interface

## Learning Points

1. **Multi-container Orchestration**: Using Docker Compose to manage multiple services
2. **Service Dependencies**: backend depends on db, frontend depends on backend
3. **Health Checks**: Ensure database starts before backend
4. **Data Persistence**: Using Volumes to store database data
5. **Network Communication**: Containers communicate via service names
6. **Port Mapping**: Expose services to the host

## Troubleshooting

### Backend Cannot Connect to Database

```bash
# Check if database is healthy
docker-compose ps

# View database logs
docker-compose logs db

# Restart database
docker-compose restart db
```

### Frontend Cannot Access Backend

Check CORS configuration and backend service status:

```bash
docker-compose logs backend
curl http://localhost:5000/api/health
```

### Data Loss

Ensure Volume is being used:

```bash
docker volume ls
docker volume inspect fullstack-app_db-data
```