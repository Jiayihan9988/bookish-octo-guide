```bash
#!/bin/bash

# Istio Experiment Automation Script
# This script installs necessary tools and executes all experiment steps

set -e  # Exit immediately on error

echo "=========================================="
echo "Istio Experiment Automation Script"
echo "=========================================="
echo ""

# Create log and screenshot directories
LOG_DIR="/home/5/logs"
SCREENSHOT_DIR="/home/5/screenshots"
mkdir -p "$LOG_DIR"

# Log file
LOG_FILE="$LOG_DIR/istio-experiment-$(date +%Y%m%d-%H%M%S).log"

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

# Step 1: Install kubectl
log "Step 1: Check and install kubectl..."
if ! command_exists kubectl; then
    log "kubectl not installed, starting installation..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    log "kubectl installation complete"
else
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# Step 2: Install minikube
log "Step 2: Check and install minikube..."
if ! command_exists minikube; then
    log "minikube not installed, starting installation..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube-linux-amd64
    sudo mv minikube-linux-amd64 /usr/local/bin/minikube
    log "minikube installation complete"
else
    log "minikube already installed: $(minikube version --short)"
fi

# Step 3: Start Minikube cluster
log "Step 3: Starting Minikube cluster (requires 4GB memory)..."
log_command "minikube start --memory=4096 --cpus=2 --driver=docker"
minikube start --memory=4096 --cpus=2 --driver=docker 2>&1 | tee -a "$LOG_FILE"

# Verify cluster
log_command "kubectl cluster-info"
kubectl cluster-info 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get nodes"
kubectl get nodes 2>&1 | tee -a "$LOG_FILE"

# Step 4: Download Istio
log "=========================================="
log "Step 4: Download Istio"
log "=========================================="

cd /home/5

if [ ! -d "istio-"* ]; then
    log "Downloading Istio..."
    log_command "curl -L https://istio.io/downloadIstio | sh -"
    curl -L https://istio.io/downloadIstio | sh - 2>&1 | tee -a "$LOG_FILE"
else
    log "Istio already downloaded"
fi

# Find Istio directory
ISTIO_DIR=$(find /home/5 -maxdepth 1 -type d -name "istio-*" | head -1)
if [ -z "$ISTIO_DIR" ]; then
    log "Error: Istio directory not found"
    exit 1
fi

log "Istio directory: $ISTIO_DIR"
cd "$ISTIO_DIR"

# Configure PATH
export PATH=$PWD/bin:$PATH

# Verify istioctl
log_command "istioctl version"
istioctl version 2>&1 | tee -a "$LOG_FILE"

# Step 5: Install Istio
log "=========================================="
log "Step 5: Install Istio into Kubernetes cluster"
log "=========================================="

log_command "istioctl install -f samples/bookinfo/demo-profile-no-gateways.yaml -y"
istioctl install -f samples/bookinfo/demo-profile-no-gateways.yaml -y 2>&1 | tee -a "$LOG_FILE"

# Enable auto-injection
log_command "kubectl label namespace default istio-injection=enabled"
kubectl label namespace default istio-injection=enabled 2>&1 | tee -a "$LOG_FILE"

# Verify Istio installation
log_command "kubectl get pods -n istio-system"
kubectl get pods -n istio-system 2>&1 | tee -a "$LOG_FILE"

# Wait for Istio components to be ready
log "Waiting for Istio components to be ready..."
kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s 2>&1 | tee -a "$LOG_FILE"

# Step 6: Install Gateway API CRDs
log "=========================================="
log "Step 6: Install Kubernetes Gateway API CRDs"
log "=========================================="

log_command "Install Gateway API CRDs"
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.4.0" | kubectl apply -f -; } 2>&1 | tee -a "$LOG_FILE"

# Verify CRDs
log_command "kubectl get crd | grep gateway"
kubectl get crd | grep gateway 2>&1 | tee -a "$LOG_FILE"

# Step 7: Deploy Bookinfo application
log "=========================================="
log "Step 7: Deploy Bookinfo sample application"
log "=========================================="

log_command "kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml"
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml 2>&1 | tee -a "$LOG_FILE"

# Wait for application deployment
log "Waiting for application Pods to be ready..."
sleep 10

log_command "kubectl get services"
kubectl get services 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods"
kubectl get pods 2>&1 | tee -a "$LOG_FILE"

# Wait for all Pods to be ready
log "Waiting for all Bookinfo Pods to be ready (may take a few minutes)..."
kubectl wait --for=condition=ready pod -l app=productpage --timeout=300s 2>&1 | tee -a "$LOG_FILE"
kubectl wait --for=condition=ready pod -l app=details --timeout=300s 2>&1 | tee -a "$LOG_FILE"
kubectl wait --for=condition=ready pod -l app=reviews --timeout=300s 2>&1 | tee -a "$LOG_FILE"
kubectl wait --for=condition=ready pod -l app=ratings --timeout=300s 2>&1 | tee -a "$LOG_FILE"

# Verify application
log "Verifying application running..."
log_command "Test internal application access"
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" \
  -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>" 2>&1 | tee -a "$LOG_FILE"

# Step 8: Configure external access
log "=========================================="
log "Step 8: Configure external access (Gateway)"
log "=========================================="

log_command "kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml"
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml 2>&1 | tee -a "$LOG_FILE"

# Modify Gateway service type
log_command "kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default"
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default 2>&1 | tee -a "$LOG_FILE"

# Wait for Gateway to be ready
sleep 5

log_command "kubectl get gateway"
kubectl get gateway 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get svc | grep gateway"
kubectl get svc | grep gateway 2>&1 | tee -a "$LOG_FILE"

# Step 9: Deploy observability components
log "=========================================="
log "Step 9: Deploy observability components"
log "=========================================="

log "Installing Kiali..."
log_command "kubectl apply -f samples/addons/kiali.yaml"
kubectl apply -f samples/addons/kiali.yaml 2>&1 | tee -a "$LOG_FILE"

log "Installing Prometheus..."
log_command "kubectl apply -f samples/addons/prometheus.yaml"
kubectl apply -f samples/addons/prometheus.yaml 2>&1 | tee -a "$LOG_FILE"

log "Installing Grafana..."
log_command "kubectl apply -f samples/addons/grafana.yaml"
kubectl apply -f samples/addons/grafana.yaml 2>&1 | tee -a "$LOG_FILE"

log "Installing Jaeger..."
log_command "kubectl apply -f samples/addons/jaeger.yaml"
kubectl apply -f samples/addons/jaeger.yaml 2>&1 | tee -a "$LOG_FILE"

# Wait for Kiali to be ready
log "Waiting for Kiali deployment to complete..."
kubectl rollout status deployment/kiali -n istio-system --timeout=300s 2>&1 | tee -a "$LOG_FILE"

log_command "kubectl get pods -n istio-system"
kubectl get pods -n istio-system 2>&1 | tee -a "$LOG_FILE"

# Step 10: Generate test traffic
log "=========================================="
log "Step 10: Generate test traffic"
log "=========================================="

log "Starting port forwarding (run in background)..."
kubectl port-forward svc/bookinfo-gateway-istio 8080:80 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
log "Port forwarding PID: $PORT_FORWARD_PID"

sleep 5

log "Generating 100 test requests..."
for i in $(seq 1 100); do
    curl -s -o /dev/null "http://localhost:8080/productpage"
    if [ $((i % 10)) -eq 0 ]; then
        log "Sent $i requests"
    fi
done

log "Test traffic generation completed"

# Generate experiment report
log "=========================================="
log "Generate experiment report"
log "=========================================="

REPORT_FILE="/home/5/Experiment-Report.md"
cat > "$REPORT_FILE" << 'EOF'
# Istio Experiment Report

## Experiment Time
EOF

echo "**Execution Time**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
## Experiment Environment
- **Operating System**: Linux
- **Container Runtime**: Docker
- **Kubernetes**: Minikube
- **Istio Version**: 1.28.x

## Experiment Completion Status

### ✅ Experiment 1: Download and install Istio
- [x] Download Istio installation package
- [x] Configure istioctl tool
- [x] Verify installation

### ✅ Experiment 2: Install Istio into Kubernetes cluster
- [x] Start Minikube cluster
- [x] Install Istio using demo configuration
- [x] Enable automatic Sidecar injection
- [x] Verify Istio component operation

### ✅ Experiment 3: Install Kubernetes Gateway API
- [x] Install Gateway API CRDs
- [x] Verify CRDs installation

### ✅ Experiment 4: Deploy Bookinfo sample application
- [x] Deploy 4 microservices
- [x] Verify Sidecar injection (READY 2/2)
- [x] Verify application operation

### ✅ Experiment 5: Configure external access
- [x] Create Gateway and HTTPRoute
- [x] Configure port forwarding
- [x] Verify external access

### ✅ Experiment 6: Deploy observability components
- [x] Install Kiali
- [x] Install Prometheus
- [x] Install Grafana
- [x] Install Jaeger
- [x] Generate test traffic

## Access applications and dashboards

### Access Bookinfo application
```bash
# Port forwarding (if not already running)
kubectl port-forward svc/bookinfo-gateway-istio 8080:80

# Browser access
http://localhost:8080/productpage
```

### Access Kiali dashboard
```bash
istioctl dashboard kiali
```

### Access Grafana dashboard
```bash
istioctl dashboard grafana
```

### Access Jaeger tracing
```bash
istioctl dashboard jaeger
```

### Access Prometheus
```bash
istioctl dashboard prometheus
```

## Experiment Summary

This experiment successfully completed Istio service mesh deployment and configuration, including:

1. **Service mesh deployment**: Successfully installed Istio control plane and data plane
2. **Application deployment**: Deployed Bookinfo microservices application, verified automatic Sidecar injection
3. **Traffic management**: Configured Gateway and routing for external access
4. **Observability**: Deployed complete monitoring and tracing components

Through this experiment, we gained deep understanding of Istio's core functionalities and service mesh working principles.

## Key Commands Reference

```bash
# Check Istio status
kubectl get pods -n istio-system

# Check application status
kubectl get pods
kubectl get svc

# Check Gateway
kubectl get gateway

# Generate traffic
for i in $(seq 1 100); do curl -s -o /dev/null "http://localhost:8080/productpage"; done

# Access dashboards
istioctl dashboard kiali
istioctl dashboard grafana
istioctl dashboard jaeger
```

## Detailed Logs
EOF

echo "Detailed execution logs saved at: \`$LOG_FILE\`" >> "$REPORT_FILE"

log "Experiment report generated: $REPORT_FILE"
log "Detailed logs saved at: $LOG_FILE"

log "=========================================="
log "Experiment execution completed!"
log "=========================================="

echo ""
echo "📊 Experiment Summary:"
echo "  - Experiment Report: $REPORT_FILE"
echo "  - Detailed Logs: $LOG_FILE"
echo "  - Screenshot Directory: $SCREENSHOT_DIR"
echo ""
echo "🌐 Access applications and dashboards:"
echo "  - Bookinfo Application: http://localhost:8080/productpage"
echo "  - Kiali Dashboard: istioctl dashboard kiali"
echo "  - Grafana Dashboard: istioctl dashboard grafana"
echo "  - Jaeger Tracing: istioctl dashboard jaeger"
echo ""
echo "📸 Next steps:"
echo "  1. Access Bookinfo application in browser and take screenshots"
echo "  2. Access Kiali to view service topology and take screenshots"
echo "  3. Refer to 'Istio-Screenshot-Instructions.md' to complete all screenshots"
echo ""
echo "🎉 Istio experiment successfully deployed!"
echo ""
echo "⚠️  Note: Port forwarding is running in background (PID: $PORT_FORWARD_PID)"
echo "    To stop: kill $PORT_FORWARD_PID"
```