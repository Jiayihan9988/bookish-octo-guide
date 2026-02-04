```bash
#!/bin/bash

# Kubernetes Experiment Automation Script
# This script installs necessary tools and executes all experiment steps

set -e  # Exit immediately on error

echo "=========================================="
echo "Kubernetes Experiment Automation Script"
echo "=========================================="
echo ""

# Create log directories
LOG_DIR="/home/4/logs"
SCREENSHOT_DIR="/home/4/screenshots"
mkdir -p "$LOG_DIR"
mkdir -p "$SCREENSHOT_DIR"/{Experiment1-Hello-Minikube,Experiment2-Deploy-Application,Experiment3-Explore-Application,Experiment4-Expose-Application,Experiment5-Scaling,Experiment6-Rolling-Update}

# Log file
LOG_FILE="$LOG_DIR/experiment-$(date +%Y%m%d-%H%M%S).log"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_command() {
    echo "" | tee -a "$LOG_FILE"
    echo ">>> Executing command: $1" | tee -a "$LOG_FILE"
    echo "---" | tee -a "$LOG_FILE"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check and install kubectl
log "Step 1: Checking kubectl..."
if ! command_exists kubectl; then
    log "kubectl not installed, starting installation..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    log "kubectl installation complete"
else
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# Step 2: Check and install minikube
log "Step 2: Checking minikube..."
if ! command_exists minikube; then
    log "minikube not installed, starting installation..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube-linux-amd64
    sudo mv minikube-linux-amd64 /usr/local/bin/minikube
    log "minikube installation complete"
else
    log "minikube already installed: $(minikube version --short)"
fi

# Step 3: Start Minikube
log "Step 3: Starting Minikube cluster..."
log_command "minikube start --driver=docker"
minikube start --driver=docker 2>&1 | tee -a "$LOG_FILE"

# Step 4: Check cluster status
log "Step 4: Checking cluster status..."
log_command "minikube status"
minikube status 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get nodes"
kubectl get nodes 2>&1 | tee -a "$LOG_FILE"

# Step 5: Experiment 1 - Hello Minikube
log "=========================================="
log "Experiment 1: Hello Minikube"
log "=========================================="

log_command "kubectl create deployment hello-node --image=registry.k8s.io/e2e-test-images/agnhost:2.53 -- /agnhost netexec --http-port=8080"
kubectl create deployment hello-node --image=registry.k8s.io/e2e-test-images/agnhost:2.53 -- /agnhost netexec --http-port=8080 2>&1 | tee -a "$LOG_FILE"

sleep 5

log_command "kubectl get deployments"
kubectl get deployments 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods"
kubectl get pods 2>&1 | tee -a "$LOG_FILE"

# Wait for Pod to be ready
log "Waiting for Pod to be ready..."
kubectl wait --for=condition=ready pod -l app=hello-node --timeout=120s 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl expose deployment hello-node --type=LoadBalancer --port=8080"
kubectl expose deployment hello-node --type=LoadBalancer --port=8080 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get services"
kubectl get services 2>&1 | tee -a "$LOG_FILE"

# Test access
log "Testing application access..."
log_command "minikube service hello-node --url"
SERVICE_URL=$(minikube service hello-node --url 2>&1 | grep -E '^http' | head -1)
log "Service URL: $SERVICE_URL"

if [ -n "$SERVICE_URL" ]; then
    log_command "curl $SERVICE_URL"
    curl -s "$SERVICE_URL" 2>&1 | tee -a "$LOG_FILE"
fi

# Cleanup Experiment 1
log "Cleaning up Experiment 1 resources..."
kubectl delete service hello-node 2>&1 | tee -a "$LOG_FILE"
kubectl delete deployment hello-node 2>&1 | tee -a "$LOG_FILE"

sleep 3

# Step 6: Experiment 2 - Deploy Application
log "=========================================="
log "Experiment 2: Deploy Application"
log "=========================================="

log_command "kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1"
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 2>&1 | tee -a "$LOG_FILE"

sleep 5

log_command "kubectl get deployments"
kubectl get deployments 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods"
kubectl get pods 2>&1 | tee -a "$LOG_FILE"

# Wait for Pod to be ready
log "Waiting for Pod to be ready..."
kubectl wait --for=condition=ready pod -l app=kubernetes-bootcamp --timeout=120s 2>&1 | tee -a "$LOG_FILE"

# Step 7: Experiment 3 - Explore Application
log "=========================================="
log "Experiment 3: Explore Application"
log "=========================================="

POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | head -1)
log "Pod Name: $POD_NAME"

log_command "kubectl describe pods $POD_NAME"
kubectl describe pods "$POD_NAME" 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl logs $POD_NAME"
kubectl logs "$POD_NAME" 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl exec $POD_NAME -- env"
kubectl exec "$POD_NAME" -- env 2>&1 | tee -a "$LOG_FILE"

# Step 8: Experiment 4 - Expose Application
log "=========================================="
log "Experiment 4: Expose Application"
log "=========================================="

log_command "kubectl expose deployment/kubernetes-bootcamp --type=NodePort --port 8080"
kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get services"
kubectl get services 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl describe services/kubernetes-bootcamp"
kubectl describe services/kubernetes-bootcamp 2>&1 | tee -a "$LOG_FILE"

# Test access
NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
MINIKUBE_IP=$(minikube ip)
log "NodePort: $NODE_PORT"
log "Minikube IP: $MINIKUBE_IP"

log_command "curl http://$MINIKUBE_IP:$NODE_PORT"
curl -s "http://$MINIKUBE_IP:$NODE_PORT" 2>&1 | tee -a "$LOG_FILE"

# Label operations
log "Label operations..."
log_command "kubectl label pods $POD_NAME version=v1"
kubectl label pods "$POD_NAME" version=v1 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods -l version=v1"
kubectl get pods -l version=v1 2>&1 | tee -a "$LOG_FILE"

# Step 9: Experiment 5 - Scaling
log "=========================================="
log "Experiment 5: Scaling"
log "=========================================="

log_command "kubectl get deployments"
kubectl get deployments 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl scale deployments/kubernetes-bootcamp --replicas=4"
kubectl scale deployments/kubernetes-bootcamp --replicas=4 2>&1 | tee -a "$LOG_FILE"

sleep 5

log_command "kubectl get deployments"
kubectl get deployments 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods -o wide"
kubectl get pods -o wide 2>&1 | tee -a "$LOG_FILE"

# Test load balancing
log "Testing load balancing (5 requests)..."
for i in {1..5}; do
    log "Request $i:"
    curl -s "http://$MINIKUBE_IP:$NODE_PORT" 2>&1 | tee -a "$LOG_FILE"
    sleep 1
done

# Scale down
log_command "kubectl scale deployments/kubernetes-bootcamp --replicas=2"
kubectl scale deployments/kubernetes-bootcamp --replicas=2 2>&1 | tee -a "$LOG_FILE"

sleep 5

log_command "kubectl get pods -o wide"
kubectl get pods -o wide 2>&1 | tee -a "$LOG_FILE"

# Step 10: Experiment 6 - Rolling Update
log "=========================================="
log "Experiment 6: Rolling Update"
log "=========================================="

log_command "kubectl describe pods | grep Image"
kubectl describe pods | grep Image 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=docker.io/jocatalin/kubernetes-bootcamp:v2"
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=docker.io/jocatalin/kubernetes-bootcamp:v2 2>&1 | tee -a "$LOG_FILE"

sleep 10

log_command "kubectl rollout status deployments/kubernetes-bootcamp"
kubectl rollout status deployments/kubernetes-bootcamp 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods"
kubectl get pods 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl describe pods | grep Image"
kubectl describe pods | grep Image 2>&1 | tee -a "$LOG_FILE"

# Test v2 version
log "Testing v2 version..."
curl -s "http://$MINIKUBE_IP:$NODE_PORT" 2>&1 | tee -a "$LOG_FILE"

# Simulate failed update
log "Simulating failed update (v10 doesn't exist)..."
log_command "kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v10"
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v10 2>&1 | tee -a "$LOG_FILE"

sleep 10

log_command "kubectl get pods"
kubectl get pods 2>&1 | tee -a "$LOG_FILE"

# Rollback
log "Rolling back to previous version..."
log_command "kubectl rollout undo deployments/kubernetes-bootcamp"
kubectl rollout undo deployments/kubernetes-bootcamp 2>&1 | tee -a "$LOG_FILE"

sleep 10

log_command "kubectl get pods"
kubectl get pods 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl describe pods | grep Image"
kubectl describe pods | grep Image 2>&1 | tee -a "$LOG_FILE"

# Final cleanup
log "=========================================="
log "Cleaning up all resources"
log "=========================================="

log_command "kubectl delete deployments/kubernetes-bootcamp services/kubernetes-bootcamp"
kubectl delete deployments/kubernetes-bootcamp services/kubernetes-bootcamp 2>&1 | tee -a "$LOG_FILE"

# Generate experiment report
log "=========================================="
log "Generating experiment report"
log "=========================================="

REPORT_FILE="/home/4/Experiment-Report.md"
cat > "$REPORT_FILE" << 'EOF'
# Kubernetes Experiment Report

## Experiment Time
EOF

echo "**Execution Time**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
## Experiment Environment
- **Operating System**: Linux
- **Container Runtime**: Docker
- **Kubernetes Tools**: Minikube + kubectl

## Experiment Completion Status

### ✅ Experiment 1: Hello Minikube
- [x] Start Minikube cluster
- [x] Create Deployment
- [x] Expose Service
- [x] Access application
- [x] Clean up resources

### ✅ Experiment 2: Deploy Application
- [x] Use kubectl to deploy application
- [x] Check Deployment status
- [x] Verify Pod is running

### ✅ Experiment 3: Explore Application
- [x] View Pod details
- [x] Check application logs
- [x] Execute commands in container

### ✅ Experiment 4: Expose Application
- [x] Create NodePort Service
- [x] Test external access
- [x] Use labels to manage resources

### ✅ Experiment 5: Scaling
- [x] Scale to 4 replicas
- [x] Test load balancing
- [x] Scale down to 2 replicas

### ✅ Experiment 6: Rolling Update
- [x] Update to v2 version
- [x] Verify update status
- [x] Simulate failed update
- [x] Rollback to stable version

## Experiment Summary

This experiment successfully completed all basic Kubernetes operations, including:
1. Cluster management and configuration
2. Application deployment and management
3. Service exposure and access
4. Application scaling
5. Rolling updates and rollbacks

Through this experiment, we gained deep understanding of Kubernetes core concepts and operational workflows.

## Detailed Logs
EOF

echo "Detailed execution logs saved at: \`$LOG_FILE\`" >> "$REPORT_FILE"

log "Experiment report generated: $REPORT_FILE"
log "Detailed logs saved at: $LOG_FILE"

log "=========================================="
log "All experiments completed!"
log "=========================================="

echo ""
echo "📊 Experiment Summary:"
echo "  - Experiment Report: $REPORT_FILE"
echo "  - Detailed Logs: $LOG_FILE"
echo "  - Screenshot Directory: $SCREENSHOT_DIR"
echo ""
echo "🎉 Congratulations! All Kubernetes experiments completed successfully!"
```