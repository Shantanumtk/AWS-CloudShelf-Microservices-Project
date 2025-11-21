#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Get PUBLIC_IP
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
if [ -z "$PUBLIC_IP" ]; then
    print_error "Failed to get PUBLIC_IP"
    exit 1
fi
print_info "Using PUBLIC_IP: $PUBLIC_IP"

# Create temp directory for ConfigMaps
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
cp -r kubernetes/* "$TEMP_DIR/"

# Replace PUBLIC_IP in ConfigMaps
print_info "Replacing \${PUBLIC_IP} in ConfigMaps..."
find "$TEMP_DIR/01-configmaps" -type f -name "*.yaml" -exec sed -i "s|\${PUBLIC_IP}|$PUBLIC_IP|g" {} \;

# Deploy namespace
print_info "Creating namespace..."
kubectl apply -f kubernetes/00-namespace/

# Deploy ConfigMaps (with replaced PUBLIC_IP)
print_info "Deploying ConfigMaps..."
kubectl apply -f "$TEMP_DIR/01-configmaps/"

# Deploy secrets
print_info "Deploying secrets..."
kubectl apply -f kubernetes/02-secrets/

# Deploy infrastructure
print_info "Deploying infrastructure..."
kubectl apply -f kubernetes/03-infrastructure/

print_info "Waiting for infrastructure..."
kubectl wait --for=condition=ready pod -l app=mongodb -n cloudshelf --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=postgres-order -n cloudshelf --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=postgres-author -n cloudshelf --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=postgres-stock -n cloudshelf --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=kafka -n cloudshelf --timeout=300s || true
sleep 10

# Deploy services
print_info "Deploying services..."
kubectl apply -f kubernetes/04-services/ -R
sleep 30

# Deploy Ingress
print_info "Deploying Ingress..."
kubectl apply -f kubernetes/05-ingress/

print_info "Waiting for Ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Deployment Complete!"
echo ""
echo "Access URLs:"
echo "  Frontend:    http://${PUBLIC_IP}:32250/"
echo "  API Gateway: http://${PUBLIC_IP}:32250/api/graphql"
echo "  Authors API: http://${PUBLIC_IP}:32250/api/authors"
echo ""
echo "Useful Commands:"
echo "  kubectl get pods -n cloudshelf"
echo "  kubectl get ingress -n cloudshelf"
echo "  kubectl logs -f deployment/frontend -n cloudshelf"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"