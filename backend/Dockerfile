# ---- Build stage ---
FROM eclipse-temurin:17-jdk AS build
LABEL authors="lonwulf"
WORKDIR /app

# Copy gradle wrapper and build files for caching
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Download dependencies
RUN ./gradlew dependencies --no-daemon || return 0

# Copy rest of the source
COPY . .

# Build springboot jar
RUN ./gradlew bootJar --no-daemon

# -----------Runtime stage-----------
FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy only the built jar from build stage
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]