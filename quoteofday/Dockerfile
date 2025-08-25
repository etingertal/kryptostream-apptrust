# Simple runtime image for Java application
FROM eclipse-temurin:21-jre AS runtime

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Single layer for all setup operations
RUN groupadd -g 1001 spring && \
    useradd -u 1001 -g spring -m spring && \
    mkdir -p /app && \
    chown spring:spring /app

WORKDIR /app

# Copy the pre-built JAR file
COPY --chown=spring:spring target/quote-of-day-service-*.jar app.jar

USER spring
EXPOSE 8080

# Health check using curl
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
