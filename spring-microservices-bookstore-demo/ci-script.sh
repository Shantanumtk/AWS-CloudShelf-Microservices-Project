#!/bin/bash

# Build Microservices Images
echo "Building Microservices Images..."
mvn clean package -DskipTests | tee maven.log

echo "Build Frontend Image..."
docker build -t microservices-bookstore/nextjs-frontend:latest ./frontend

echo " Starting Microservices Bookstore Application..."
