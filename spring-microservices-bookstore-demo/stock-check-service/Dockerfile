# syntax=docker/dockerfile:1.7
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY ./pom.xml /workspace/pom.xml
COPY ./stock-check-service/pom.xml /workspace/stock-check-service/pom.xml
COPY ./stock-check-service/src /workspace/stock-check-service/src
RUN --mount=type=cache,target=/root/.m2 mvn -q -B -f /workspace/stock-check-service/pom.xml -DskipTests package
FROM eclipse-temurin:17-jre
RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /app
COPY --from=build /workspace/stock-check-service/target/*.jar /app/app.jar
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -jar /app/app.jar"]
