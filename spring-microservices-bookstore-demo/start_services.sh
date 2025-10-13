#!/bin/bash

echo " Starting Microservices Bookstore Application..."

# Stop all services first
echo "Stopping existing services..."
docker compose down

# Step 1: Infrastructure
echo "Starting infrastructure services..."
docker compose up -d zookeeper broker mongo postgres-order postgres-author postgres-stock-check
sleep 15

# Step 2: Config Server
echo "Starting config-server..."
docker compose up -d config-server
sleep 20

# Step 3: Discovery Server
echo "Starting discovery-server..."
docker compose up -d discovery-server
sleep 30

# Step 4: Microservices
echo "Starting business microservices..."
docker compose up -d book-service author-service order-service stock-check-service message-service
sleep 40

# Step 5: API Gateway
echo "Starting API Gateway..."
docker compose up -d api-gateway
sleep 30

# Step 6: Frontend & Monitoring
echo "Starting frontend and monitoring..."
docker compose up -d nextjs-frontend zipkin prometheus grafana

echo ""
echo "✅ All services started!"
echo ""
echo "=== Service URLs ==="
echo "Frontend:    http://54.211.3.26:3000"
echo "Eureka:      http://54.211.3.26:8761"
echo "API Gateway: http://54.211.3.26:8080"
echo "Zipkin:      http://54.211.3.26:9411"
echo "Prometheus:  http://54.211.3.26:9090"
echo "Grafana:     http://54.211.3.26:3001"
echo ""
echo "Check status: docker compose ps"
echo "Check logs:   docker compose logs -f [service-name]"
