#Dockerfile for Config Server

FROM eclipse-temurin:17-jre

# run as non-root
RUN useradd -ms /bin/bash app && mkdir -p /app && chown -R app:app /app
USER app
WORKDIR /app

# CI/local mvn must build: config-server/target/*.jar
COPY target/*.jar /app/app.jar

# Honor JAVA_TOOL_OPTIONS (set via compose/K8s)
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -Dserver.port=${SERVER_PORT} -jar /app/app.jar"]
