#Dockerfile for Book Service
FROM eclipse-temurin:17-jre

# run as non-root
RUN useradd -ms /bin/bash app && mkdir -p /app && chown -R app:app /app
USER app
WORKDIR /app

# CI/local mvn must build: book-service/target/*.jar
COPY target/*.jar /app/app.jar

# honor JAVA_TOOL_OPTIONS from compose/K8s
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -Dserver.port=${SERVER_PORT} -jar /app/app.jar"]
