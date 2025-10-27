# Dockerfile for Discovery Server
# syntax=docker/dockerfile:1.7

# ---------- BUILD ----------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -q -B dependency:go-offline
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -q -B -DskipTests package

# ---------- RUNTIME ----------
FROM eclipse-temurin:17-jre
RUN apt-get update -y && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*
RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /app
COPY --from=build /workspace/target/*.jar /app/app.jar

# Optional healthcheck (enable if SERVER_PORT is set in compose)
# HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
#   CMD test -n "$SERVER_PORT" && curl -fsS http://localhost:${SERVER_PORT}/actuator/health \
#     | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -jar /app/app.jar"]
