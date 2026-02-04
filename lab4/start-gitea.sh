#!/bin/bash

echo "=========================================="
echo "  Gitea Docker Startup Script"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "Please install Docker Desktop first"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop"
    exit 1
fi

echo "✅ Docker is ready"
echo ""

# Create data directory
if [ ! -d "./gitea" ]; then
    echo "📁 Creating data directory..."
    mkdir -p ./gitea
fi

# Start Gitea
echo "🚀 Starting Gitea container..."
docker-compose up -d

# Wait for container to start
echo "⏳ Waiting for Gitea to start..."
sleep 5

# Check container status
if docker ps | grep -q gitea; then
    echo ""
    echo "=========================================="
    echo "✅ Gitea started successfully!"
    echo "=========================================="
    echo ""
    echo "Access URL: http://localhost:3000"
    echo ""
    echo "First-time access requires completing initialization configuration:"
    echo "  1. Access http://localhost:3000"
    echo "  2. Create admin account"
    echo "  3. Complete installation"
    echo ""
    echo "View logs: docker logs gitea"
    echo "Stop service: docker-compose down"
    echo "=========================================="
else
    echo ""
    echo "❌ Gitea failed to start"
    echo "Please check logs: docker logs gitea"
fi