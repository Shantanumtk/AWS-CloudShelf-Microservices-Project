# syntax=docker/dockerfile:1.7
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY ./pom.xml /workspace/pom.xml
COPY ./discovery-server/pom.xml /workspace/discovery-server/pom.xml
COPY ./discovery-server/src /workspace/discovery-server/src
RUN --mount=type=cache,target=/root/.m2 mvn -q -B -f /workspace/discovery-server/pom.xml -DskipTests package
FROM eclipse-temurin:17-jre
RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /app
COPY --from=build /workspace/discovery-server/target/*.jar /app/app.jar
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -jar /app/app.jar"]
