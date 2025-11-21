#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "CloudShelf Infrastructure Destroy"
echo "=========================================="
echo ""

read -p "Are you sure you want to destroy all resources? (yes/no): " -r
echo

if [[ $REPLY == "yes" ]]; then
    cd "$SCRIPT_DIR/terraform"
    terraform destroy -auto-approve
    print_success "Infrastructure destroyed!"
else
    print_error "Destroy cancelled"
    exit 0
fi