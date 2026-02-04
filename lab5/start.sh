#!/bin/bash

# Docker Learning & Practice - Quick Start Script
# This script will guide you through all Docker learning and practice operations

set -e

echo "=========================================="
echo "  🐳 Docker Learning & Practice - Quick Start"
echo "=========================================="
echo ""

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
echo -e "${BLUE}[1/8] Checking Docker environment...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed, please install Docker first${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed, please install Docker Compose first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker version: $(docker --version)${NC}"
echo -e "${GREEN}✅ Docker Compose version: $(docker-compose --version)${NC}"
echo ""

# Create screenshots directory
echo -e "${BLUE}[2/8] Creating screenshots directory...${NC}"
mkdir -p /home/3/screenshots
echo -e "${GREEN}✅ Screenshots directory created: /home/3/screenshots${NC}"
echo ""

# Run hello-world
echo -e "${BLUE}[3/8] Running first container (hello-world)...${NC}"
echo -e "${YELLOW}📸 Please take a screenshot and save as: screenshots/01-hello-world.png${NC}"
docker run hello-world
echo -e "${GREEN}✅ hello-world container ran successfully${NC}"
echo ""
read -p "Press Enter to continue..."

# View containers and images
echo -e "${BLUE}[4/8] Viewing container and image lists...${NC}"
echo -e "${YELLOW}📸 Please take a screenshot and save as: screenshots/03-docker-ps.png${NC}"
echo ""
echo "=== Container List ==="
docker ps -a
echo ""
echo "=== Image List ==="
docker images
echo -e "${GREEN}✅ List viewing completed${NC}"
echo ""
read -p "Press Enter to continue..."

# Build simple web application
echo -e "${BLUE}[5/8] Building custom image...${NC}"
cd /home/3/examples/simple-web
echo -e "${YELLOW}📸 Please take a screenshot and save as: screenshots/05-docker-build.png${NC}"
docker build -t my-nginx:v1 .
echo ""
echo "Starting web service..."
docker run -d -p 8080:80 --name my-web my-nginx:v1
echo -e "${GREEN}✅ Web service started: http://localhost:8080${NC}"
echo -e "${YELLOW}📸 Please visit in browser and take a screenshot${NC}"
echo ""
read -p "Press Enter to continue..."

# Cleanup
docker rm -f my-web

# Docker Compose example
echo -e "${BLUE}[6/8] Running Docker Compose example...${NC}"
cd /home/3/examples/compose-demo
echo -e "${YELLOW}📸 Please take a screenshot and save as: screenshots/06-docker-compose-ps.png${NC}"
docker-compose up -d
sleep 3
docker-compose ps
echo -e "${GREEN}✅ Compose services started: http://localhost:8080${NC}"
echo ""
read -p "Press Enter to continue..."

# Cleanup
docker-compose down

# Data persistence example
echo -e "${BLUE}[7/8] Testing data persistence...${NC}"
echo "Creating Volume..."
docker volume create test-volume
docker volume ls
echo ""
echo "Running container with Volume..."
docker run -d --name nginx-vol -v test-volume:/usr/share/nginx/html -p 8081:80 nginx
docker exec nginx-vol bash -c "echo '<h1>Persistent Data</h1>' > /usr/share/nginx/html/index.html"
echo -e "${GREEN}✅ Data persistence test completed${NC}"
echo ""
read -p "Press Enter to continue..."

# Cleanup
docker rm -f nginx-vol
docker volume rm test-volume

# Start complete application
echo -e "${BLUE}[8/8] Starting complete full-stack application...${NC}"
cd /home/3/examples/fullstack-app
echo -e "${YELLOW}📸 Please take a screenshot and save as: screenshots/20-multi-container-app.png${NC}"
echo ""
echo "Starting all services (frontend + backend + database)..."
docker-compose up -d

echo ""
echo "Waiting for services to start (approx. 30 seconds)..."
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""

echo ""
echo "=== Service Status ==="
docker-compose ps
echo ""

echo -e "${GREEN}✅ All services are now running!${NC}"
echo ""
echo "=========================================="
echo "  🎉 Docker Learning Environment is Ready!"
echo "=========================================="
echo ""
echo "📱 Access URLs:"
echo "  - Frontend Interface: http://localhost:8080"
echo "  - Backend API: http://localhost:5000/api/health"
echo ""
echo "🧪 Test Commands:"
echo "  curl http://localhost:5000/api/health"
echo "  curl http://localhost:5000/api/users"
echo ""
echo "📸 Screenshot Tasks:"
echo "  1. Visit http://localhost:8080 and take screenshot"
echo "  2. Add a user and take screenshot"
echo "  3. View user list and take screenshot"
echo ""
echo "📚 Documentation Locations:"
echo "  - README.md - Complete Learning Guide"
echo "  - Practice Operation Guide.md - Detailed Steps"
echo "  - Docker Learning Practice Documentation.md - Theoretical Knowledge"
echo ""
echo "🛠️ Management Commands:"
echo "  docker-compose ps      # Check service status"
echo "  docker-compose logs    # View logs"
echo "  docker-compose down    # Stop all services"
echo ""
echo "=========================================="
echo ""
