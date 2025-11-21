#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_DIR="$SCRIPT_DIR/.ssh"
SSH_KEY="$SSH_DIR/cloudshelf-key"
AWS_REGION="us-east-1"
KEY_NAME="cloudshelf-key"

echo "=========================================="
echo "CloudShelf Infrastructure Setup"
echo "=========================================="
echo ""

# Create .ssh directory if not exists
print_info "Checking SSH directory..."
mkdir -p "$SSH_DIR"

# Check if SSH key exists locally
if [ -f "$SSH_KEY" ]; then
    print_success "SSH key found locally: $SSH_KEY"
else
    print_info "SSH key not found. Generating new key..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -C "cloudshelf-key"
    print_success "SSH key generated: $SSH_KEY"
fi

# Set proper permissions
chmod 400 "$SSH_KEY"
chmod 644 "$SSH_KEY.pub"

# Check if key exists in AWS
print_info "Checking if key exists in AWS..."
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" &>/dev/null; then
    print_warn "Key '$KEY_NAME' already exists in AWS"
    read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting existing key from AWS..."
        aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$AWS_REGION"
        print_success "Key deleted from AWS"
        
        print_info "Importing new key to AWS..."
        aws ec2 import-key-pair \
            --key-name "$KEY_NAME" \
            --public-key-material fileb://"$SSH_KEY.pub" \
            --region "$AWS_REGION"
        print_success "Key imported to AWS"
    else
        print_info "Using existing AWS key"
    fi
else
    print_info "Importing SSH key to AWS..."
    aws ec2 import-key-pair \
        --key-name "$KEY_NAME" \
        --public-key-material fileb://"$SSH_KEY.pub" \
        --region "$AWS_REGION"
    print_success "Key imported to AWS"
fi

# Run Terraform
print_info "Initializing Terraform..."
cd "$SCRIPT_DIR/terraform"
terraform init

print_info "Planning Terraform deployment..."
terraform plan

echo ""
read -p "Do you want to proceed with deployment? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Applying Terraform configuration..."
    terraform apply -auto-approve
    
    echo ""
    echo "=========================================="
    print_success "Deployment Complete!"
    echo "=========================================="
    echo ""
    
    # Get outputs
    PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "unknown")
    
    echo "Public IP: $PUBLIC_IP"
    echo ""
    echo "SSH Command:"
    echo "  ssh -i $SSH_KEY ubuntu@$PUBLIC_IP"
    echo ""
    echo "Check deployment status:"
    echo "  ssh -i $SSH_KEY ubuntu@$PUBLIC_IP 'tail -f /var/log/user-data.log'"
    echo ""
    echo "=========================================="
else
    print_warn "Deployment cancelled"
    exit 0
fi