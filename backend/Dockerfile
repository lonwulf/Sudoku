# ---- Build stage ---
FROM eclipse-temurin:17-jdk AS build
LABEL authors="lonwulf"
WORKDIR /app

# Copy gradle wrapper and build files for caching
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Download dependencies (cached until the build files change)
RUN ./gradlew dependencies --no-daemon > /dev/null || true

# Copy the sources only
COPY src src

# Build springboot jar
RUN ./gradlew bootJar --no-daemon

# -----------Runtime stage-----------
FROM eclipse-temurin:17-jre
WORKDIR /app

# Don't run the app as root
RUN groupadd --system spring && useradd --system --gid spring spring

# Copy only the built jar from build stage
COPY --from=build --chown=spring:spring /app/build/libs/*.jar app.jar
USER spring
EXPOSE 8080

# Run the application, sizing the heap from the container's memory limit
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]
