#!/bin/bash
# cd-script.sh — simple, sequential bring-up with short, chatty waits
set -euo pipefail

dot_sleep() {  # sleep N seconds but print a dot each second
  local secs="${1:-5}"
  for ((i=1;i<=secs;i++)); do printf "."; sleep 1; done
  echo
}

echo "Stopping existing services..."
docker compose down || true

# 1) Infrastructure
echo "Starting infrastructure services..."
docker compose up -d zookeeper broker mongo postgres-order postgres-author postgres-stock-check
dot_sleep 20

# 2) Discovery Server
echo "Starting discovery-server..."
docker compose up -d discovery-server
dot_sleep 20

# 3) Config Server
echo "Starting config-server..."
docker compose up -d config-server
dot_sleep 15

# 4) Microservices
echo "Starting business microservices..."
docker compose up -d book-service author-service order-service stock-check-service message-service
dot_sleep 25

# 5) API Gateway
echo "Starting API Gateway..."
docker compose up -d api-gateway
dot_sleep 25

# 6) Frontend & Monitoring
echo "Starting frontend and monitoring..."
docker compose up -d nextjs-frontend zipkin prometheus grafana

echo
echo "Current containers:"
docker compose ps

echo
echo "✅ All services started!"
