#!/bin/bash

echo "=========================================="
echo "  Stop Gitea Service"
echo "=========================================="
echo ""

docker-compose down

echo "✅ Gitea has been stopped"