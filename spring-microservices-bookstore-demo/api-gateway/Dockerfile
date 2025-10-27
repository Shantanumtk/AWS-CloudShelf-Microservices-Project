# Dockerfile for API Gateway
# syntax=docker/dockerfile:1.7

########## BUILD (Maven + JDK 17) ##########
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace

# Cache dependencies for faster rebuilds
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -q -B dependency:go-offline

# Build fat jar
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -q -B -DskipTests package

########## RUNTIME (JRE 17) ##########
FROM eclipse-temurin:17-jre

# healthcheck helper
RUN apt-get update -y && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# run as non-root
RUN useradd -ms /bin/bash appuser
USER appuser

WORKDIR /app
COPY --from=build /workspace/target/*.jar /app/app.jar

# default in-container port
ENV SERVER_PORT=8080

# make port visible to tooling
EXPOSE 8080

# Healthcheck (requires Spring Boot Actuator). Comment out if not using Actuator.
HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD curl -fsS http://localhost:${SERVER_PORT}/actuator/health | grep -q '"status":"UP"' || exit 1

# Honor JAVA_TOOL_OPTIONS from compose
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -Dserver.port=${SERVER_PORT} -jar /app/app.jar"]
