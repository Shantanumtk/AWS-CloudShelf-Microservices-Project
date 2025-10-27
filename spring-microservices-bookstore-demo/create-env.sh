#!/bin/bash
# scripts/create-env.sh

set -e

echo "🔍 Fetching public IP address from AWS..."

# Get public IP from AWS
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Failed to fetch public IP address"
    exit 1
fi

echo "✅ Public IP detected: $PUBLIC_IP"

# Create .env file
ENV_FILE=".env"
FRONTEND_ENV_FILE="frontend/.env"

echo "📝 Creating $ENV_FILE..."

cat > $ENV_FILE <<EOF
# Environment Variables
# Auto-generated on $(date)
# Public IP: $PUBLIC_IP

# Host Configuration
PUBLIC_HOST=$PUBLIC_IP
FRONTEND_PORT=3000
GATEWAY_PORT=8080

# Frontend API Endpoints
NEXT_PUBLIC_API_BASE=http://$PUBLIC_IP:8080
NEXT_PUBLIC_GRAPHQL_ENDPOINT=http://$PUBLIC_IP:8080/api/graphql
NEXT_PUBLIC_AUTHORS_ENDPOINT=http://$PUBLIC_IP:8080/api/authors

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://$PUBLIC_IP:3000

# Kafka Configuration
SPRING_KAFKA_BOOTSTRAP_SERVERS=broker:29092
SPRING_KAFKA_CONSUMER_GROUP_ID=message-consumers
EOF

echo "✅ Created $ENV_FILE"

# Copy to frontend folder
echo "📋 Copying .env to frontend folder..."

if [ -d "frontend" ]; then
    cp $ENV_FILE $FRONTEND_ENV_FILE
    echo "✅ Copied to $FRONTEND_ENV_FILE"
else
    echo "⚠️  Warning: frontend folder not found, skipping copy"
fi

# Display the created file
echo ""
echo "📄 Generated .env file contents:"
echo "================================"
cat $ENV_FILE
echo "================================"
echo ""
echo "✅ Done! .env file created successfully"

echo "Build Frontend Image..."
docker build -t microservices-bookstore/nextjs-frontend:latest ./frontend
echo "✅ Frontend Docker image built successfully"

