# syntax=docker/dockerfile:1.7
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY ./pom.xml /workspace/pom.xml
COPY ./api-gateway/pom.xml /workspace/api-gateway/pom.xml
COPY ./api-gateway/src /workspace/api-gateway/src
RUN --mount=type=cache,target=/root/.m2 mvn -q -B -f /workspace/api-gateway/pom.xml -DskipTests package
FROM eclipse-temurin:17-jre
RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /app
COPY --from=build /workspace/api-gateway/target/*.jar /app/app.jar
ENV SERVER_PORT=8080
EXPOSE 8080
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -Dserver.port=${SERVER_PORT} -jar /app/app.jar"]
