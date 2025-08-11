# Ultra-minimal Alpine-based runtime image
FROM eclipse-temurin:21-jre-alpine AS runtime

# Single layer for all setup operations
RUN addgroup -g 1001 -S spring && \
    adduser -u 1001 -S spring -G spring && \
    mkdir -p /app && \
    chown spring:spring /app

WORKDIR /app

# Copy JAR and set ownership in one operation
COPY --chown=spring:spring target/quote-of-day-service-*.jar app.jar

USER spring
EXPOSE 8080

# Simple health check using Java process check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD java -cp app.jar org.springframework.boot.loader.JarLauncher --help > /dev/null 2>&1 || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
