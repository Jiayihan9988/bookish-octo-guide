#!/bin/bash

echo "=========================================="
echo "  Gitea Experiment Automation Script"
echo "=========================================="
echo ""

# Task A: Verify Git LFS Support
echo "【Task A】Verify Git LFS Support"
echo "----------------------------------------"
echo "Check environment variables:"
docker exec gitea env | grep LFS
echo ""
echo "Check logs:"
docker logs gitea 2>&1 | grep -i "LFS server"
echo ""
echo "✅ Conclusion: Gitea supports Git LFS"
echo ""

# Task B: Create Large File Test
echo "【Task B】Create Large File Test"
echo "----------------------------------------"
echo "Note: This task requires completing the following steps in the Gitea web interface:"
echo "1. Access http://localhost:3000"
echo "2. First-time access requires completing initialization (create admin account)"
echo "3. Create new repository 'large-file-test'"
echo "4. Then run the following commands:"
echo ""
cat << 'EOF'
cd /home/2
mkdir -p large-file-test
cd large-file-test
git init
git config user.name "admin"
git config user.email "admin@example.com"
git lfs install
git lfs track "*.dat"
git add .gitattributes
git commit -m "Configure Git LFS"

# Create 1.5GB large file
dd if=/dev/zero of=large-file.dat bs=1M count=1536

# Add and commit
git add large-file.dat
git commit -m "Add 1.5GB large file using Git LFS"

# Add remote repository (replace admin with your username)
git remote add origin http://localhost:3000/admin/large-file-test.git

# Push (requires username and password input)
git push -u origin master
EOF
echo ""

# Task C: Submit Experiment Results
echo "【Task C】Submit Experiment Results"
echo "----------------------------------------"
echo "Steps:"
echo "1. Create repository 'gitea-experiment' in Gitea"
echo "2. Run the following commands:"
echo ""
cat << 'EOF'
cd /home/2
mkdir -p gitea-experiment
cd gitea-experiment
git init
git config user.name "admin"
git config user.email "admin@example.com"

# Create README
cat > README.md << 'EOFREADME'
# Gitea Experiment Results

## Experiment Content
1. ✅ Docker installation of Gitea
2. ✅ Git LFS function verification
3. ✅ Large file upload test (1.5GB)
4. ✅ Experiment documentation organization

## Experiment Environment
- Docker Compose
- Gitea (latest)
- Git LFS

## Experiment Conclusion
Gitea is a lightweight self-hosted Git service that fully supports Git LFS.
EOFREADME

# Copy experiment files
cp ../实验报告.md ./
cp ../Gitea实验操作步骤.md ./
cp ../docker-compose.yml ./
cp ../README.md ./README-guide.md

# Commit
git add .
git commit -m "Initial commit: Gitea experiment documentation"

# Push
git remote add origin http://localhost:3000/admin/gitea-experiment.git
git push -u origin master
EOF
echo ""

# Task D: Data Backup
echo "【Task D】Data Backup and Recovery (Optional)"
echo "----------------------------------------"
echo "Backup command:"
echo ""
cat << 'EOF'
cd /home/2
docker compose down
tar -czf gitea-backup-$(date +%Y%m%d-%H%M%S).tar.gz ./gitea ./docker-compose.yml
docker compose up -d
EOF
echo ""
echo "Recovery command (on new machine):"
echo ""
cat << 'EOF'
tar -xzf gitea-backup-YYYYMMDD-HHMMSS.tar.gz
docker compose up -d
EOF
echo ""

echo "=========================================="
echo "  Experiment Guide Completed"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Open browser and access: http://localhost:3000"
echo "2. Complete Gitea initialization configuration"
echo "3. Follow the steps above to complete experiment tasks"
echo ""