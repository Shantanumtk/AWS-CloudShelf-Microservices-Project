#!/bin/bash

echo "Build Frontend Image..."
docker build -t microservices-bookstore/nextjs-frontend:latest ./frontend

echo " Starting Microservices Bookstore Application..."

# Stop all services first
echo "Stopping existing services..."
docker compose down

# Step 1: Infrastructure
echo "Starting infrastructure services..."
docker compose up -d zookeeper broker mongo postgres-order postgres-author postgres-stock-check
sleep 30

# Step 2: Config Server
echo "Starting config-server..."
docker compose up -d config-server
sleep 30        

# Step 3: Discovery Server
echo "Starting discovery-server..."
docker compose up -d discovery-server
sleep 50

# Step 4: Microservices
echo "Starting business microservices..."
docker compose up -d book-service author-service order-service stock-check-service message-service
sleep 40

# Step 5: API Gateway
echo "Starting API Gateway..."
docker compose up -d api-gateway
sleep 60

# Step 6: Frontend & Monitoring
echo "Starting frontend and monitoring..."
docker compose up -d nextjs-frontend zipkin prometheus grafana

echo ""
echo "✅ All services started!"
