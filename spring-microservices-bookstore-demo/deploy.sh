#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_info "Creating .env from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_warn "Please update PUBLIC_IP in .env file"
        exit 1
    else
        print_error ".env.example not found. Please create .env manually"
        exit 1
    fi
fi

export $(grep -v '^#' .env | xargs)

if [ -z "${PUBLIC_IP:-}" ]; then
    print_error "PUBLIC_IP not set in .env!"
    exit 1
fi

print_info "Using PUBLIC_IP: $PUBLIC_IP"

# Generate ConfigMaps from templates
if [ -f "kubernetes/01-configmaps/frontend-config.yaml.template" ]; then
    print_info "Generating frontend-config.yaml from template..."
    envsubst < "kubernetes/01-configmaps/frontend-config.yaml.template" > "kubernetes/01-configmaps/frontend-config.yaml"
fi

if [ -f "kubernetes/01-configmaps/api-gateway-config.yaml.template" ]; then
    print_info "Generating api-gateway-config.yaml from template..."
    envsubst < "kubernetes/01-configmaps/api-gateway-config.yaml.template" > "kubernetes/01-configmaps/api-gateway-config.yaml"
fi

# Enable Ingress addon
print_info "Enabling Ingress addon..."
minikube addons enable ingress

# Clean existing deployment
print_info "Cleaning existing deployment..."
kubectl delete namespace cloudshelf --ignore-not-found=true --wait=false

print_info "Waiting for namespace cleanup..."
while kubectl get namespace cloudshelf 2>/dev/null; do
    sleep 2
done

# Deploy namespace
print_info "Creating namespace..."
kubectl apply -f kubernetes/00-namespace/

# Deploy secrets
print_info "Deploying secrets..."
kubectl apply -f kubernetes/02-secrets/ --recursive

# Deploy configmaps
print_info "Deploying ConfigMaps..."
kubectl apply -f kubernetes/01-configmaps/ --recursive

# Deploy infrastructure
print_info "Deploying infrastructure..."
kubectl apply -f kubernetes/03-infrastructure/ --recursive

print_info "Waiting for infrastructure (60s)..."
sleep 60

# Deploy services
print_info "Deploying services..."
kubectl apply -f kubernetes/04-services/ --recursive

print_info "Waiting for services (120s)..."
sleep 120

# Wait for Ingress controller
print_info "Waiting for Ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s || print_warn "Ingress controller wait timed out"

# Deploy Ingress
print_info "Deploying Ingress..."
kubectl apply -f kubernetes/05-ingress/

sleep 15

# Get Ingress NodePort
INGRESS_NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
print_info "Ingress NodePort: $INGRESS_NODEPORT"

# Setup port-forward
print_info "Setting up port-forward..."
pkill -f "kubectl port-forward.*ingress-nginx-controller.*$INGRESS_NODEPORT" || true
sleep 2

kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller $INGRESS_NODEPORT:80 --address=0.0.0.0 > /tmp/ingress-$INGRESS_NODEPORT.log 2>&1 &
PF_PID=$!
echo $PF_PID > /tmp/ingress-$INGRESS_NODEPORT.pid

sleep 5

if ps -p $PF_PID > /dev/null; then
    print_info "✅ Port-forward started (PID: $PF_PID)"
else
    print_warn "Port-forward may have failed. Check /tmp/ingress-$INGRESS_NODEPORT.log"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Deployment Complete!${NC}"
echo ""
echo "Access URLs:"
echo "  Frontend:    http://${PUBLIC_IP}:${INGRESS_NODEPORT}/"
echo "  API Gateway: http://${PUBLIC_IP}:${INGRESS_NODEPORT}/api/graphql"
echo "  Authors API: http://${PUBLIC_IP}:${INGRESS_NODEPORT}/api/authors"
echo ""
echo "Direct NodePort (Fallback):"
echo "  Frontend:    http://${PUBLIC_IP}:30000/"
echo ""
echo "⚠️  Ensure port ${INGRESS_NODEPORT} is open in AWS Security Group!"
echo ""
echo "Useful Commands:"
echo "  kubectl get pods -n cloudshelf"
echo "  kubectl get ingress -n cloudshelf"
echo "  kubectl logs -f deployment/api-gateway -n cloudshelf"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"