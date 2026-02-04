#!/bin/bash

echo "=========================================="
echo "  Large File Creation Test Script"
echo "=========================================="
echo ""

# Set file size (MB)
FILE_SIZE=${1:-1536}  # Default 1.5GB
FILE_NAME="large-file-${FILE_SIZE}MB.dat"

echo "📝 Creating a ${FILE_SIZE}MB test file..."
echo "File name: $FILE_NAME"
echo ""

# Check available space
AVAILABLE_SPACE=$(df -m . | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt "$FILE_SIZE" ]; then
    echo "❌ Error: Insufficient disk space"
    echo "Required: ${FILE_SIZE}MB"
    echo "Available: ${AVAILABLE_SPACE}MB"
    exit 1
fi

# Create large file
echo "⏳ Creating file (this may take several minutes)..."

if command -v fallocate &> /dev/null; then
    # Use fallocate (faster)
    fallocate -l ${FILE_SIZE}M "$FILE_NAME"
else
    # Use dd
    dd if=/dev/zero of="$FILE_NAME" bs=1M count=$FILE_SIZE status=progress
fi

# Verify file
if [ -f "$FILE_NAME" ]; then
    ACTUAL_SIZE=$(du -h "$FILE_NAME" | cut -f1)
    echo ""
    echo "=========================================="
    echo "✅ File creation successful!"
    echo "=========================================="
    echo "File name: $FILE_NAME"
    echo "Size: $ACTUAL_SIZE"
    echo ""
    echo "Next steps:"
    echo "  1. Initialize Git repository: git init"
    echo "  2. Enable Git LFS: git lfs install"
    echo "  3. Track large file: git lfs track '*.dat'"
    echo "  4. Add file: git add $FILE_NAME"
    echo "  5. Commit: git commit -m 'Add large file'"
    echo "=========================================="
else
    echo "❌ File creation failed"
fi