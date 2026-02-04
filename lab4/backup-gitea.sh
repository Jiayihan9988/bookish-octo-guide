#!/bin/bash

echo "=========================================="
echo "  Gitea Data Backup Script"
echo "=========================================="
echo ""

# Generate backup filename (with timestamp)
BACKUP_NAME="gitea-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# Stop container
echo "⏸️  Stopping Gitea container..."
docker-compose down

# Backup data
echo "📦 Compressing backup data..."
tar -czf "$BACKUP_NAME" ./gitea ./docker-compose.yml

# Restart container
echo "🚀 Restarting Gitea container..."
docker-compose up -d

# Display backup information
if [ -f "$BACKUP_NAME" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_NAME" | cut -f1)
    echo ""
    echo "=========================================="
    echo "✅ Backup completed!"
    echo "=========================================="
    echo "Backup file: $BACKUP_NAME"
    echo "File size: $BACKUP_SIZE"
    echo ""
    echo "Restoration method:"
    echo "  1. Extract: tar -xzf $BACKUP_NAME"
    echo "  2. Start: docker-compose up -d"
    echo "=========================================="
else
    echo "❌ Backup failed"
fi