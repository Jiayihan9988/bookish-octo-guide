#!/bin/bash

echo "=========================================="
echo "  Verify Gitea Git LFS Support"
echo "=========================================="
echo ""

# Check if container is running
if ! docker ps | grep -q gitea; then
    echo "❌ Gitea container is not running"
    echo "Please start Gitea first: ./start-gitea.sh"
    exit 1
fi

echo "Method 1: Check configuration file"
echo "----------------------------------------"
docker exec gitea cat /data/gitea/conf/app.ini | grep -A 10 "\[server\]" | grep LFS
echo ""

echo "Method 2: Check LFS configuration"
echo "----------------------------------------"
docker exec gitea cat /data/gitea/conf/app.ini | grep -A 5 "\[lfs\]"
echo ""

echo "Method 3: Check environment variables"
echo "----------------------------------------"
docker exec gitea env | grep LFS
echo ""

echo "=========================================="
echo "✅ Verification completed"
echo "=========================================="
echo ""
echo "If you see LFS_START_SERVER=true, LFS is enabled"