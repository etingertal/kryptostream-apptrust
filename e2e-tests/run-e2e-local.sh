#!/bin/bash

set -e

echo "🚀 Starting Local End-to-End Tests"
echo "=================================="

# Check if Podman is available
if ! command -v podman &> /dev/null; then
    echo "❌ Podman is not installed or not in PATH"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! command -v podman-compose &> /dev/null; then
    echo "❌ Neither docker-compose nor podman-compose is available"
    echo "Please install one of them to run the E2E tests"
    exit 1
fi

# Load environment variables from .env file
if [ -f ".env" ]; then
    echo "📄 Loading environment variables from .env file"
    # Only export specific variables we need, avoiding multi-line values
    export HF_TOKEN=$(grep '^HF_TOKEN=' .env | cut -d'=' -f2-)
    export HF_ENDPOINT=$(grep '^HF_ENDPOINT=' .env | cut -d'=' -f2-)
    export HF_HUB_ETAG_TIMEOUT=$(grep '^HF_HUB_ETAG_TIMEOUT=' .env | cut -d'=' -f2-)
    export HF_HUB_DOWNLOAD_TIMEOUT=$(grep '^HF_HUB_DOWNLOAD_TIMEOUT=' .env | cut -d'=' -f2-)
elif [ -f "../.env" ]; then
    echo "📄 Loading environment variables from .env file"
    # Only export specific variables we need, avoiding multi-line values
    export HF_TOKEN=$(grep '^HF_TOKEN=' ../.env | cut -d'=' -f2-)
    export HF_ENDPOINT=$(grep '^HF_ENDPOINT=' ../.env | cut -d'=' -f2-)
    export HF_HUB_ETAG_TIMEOUT=$(grep '^HF_HUB_ETAG_TIMEOUT=' ../.env | cut -d'=' -f2-)
    export HF_HUB_DOWNLOAD_TIMEOUT=$(grep '^HF_HUB_DOWNLOAD_TIMEOUT=' ../.env | cut -d'=' -f2-)
else
    echo "⚠️  .env file not found, using default values"
    export HF_TOKEN=${HF_TOKEN:-""}
fi

export COMPOSE_PROJECT_NAME="evidence-integration-e2e"

# Determine which compose command to use
if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
    echo "📦 Using podman-compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo "📦 Using docker-compose"
fi

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
$COMPOSE_CMD -f local-run/docker-compose.local.yml down -v --remove-orphans 2>/dev/null || true

# Build and start services
echo "🔨 Building and starting services..."
$COMPOSE_CMD -f local-run/docker-compose.local.yml up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🏥 Checking service health..."
if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ Quote service is healthy"
else
    echo "❌ Quote service is not healthy"
    $COMPOSE_CMD -f local-run/docker-compose.local.yml logs quote-service
    exit 1
fi

if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Translation service is healthy"
else
    echo "❌ Translation service is not healthy"
    $COMPOSE_CMD -f local-run/docker-compose.local.yml logs translation-service
    exit 1
fi

# Run E2E tests
echo "🧪 Running E2E tests..."
$COMPOSE_CMD -f local-run/docker-compose.local.yml --profile e2e-test up --build e2e-tests

# Get test results
TEST_EXIT_CODE=$?

# Show service logs if tests failed
if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo "❌ E2E tests failed. Showing service logs:"
    echo "=== Quote Service Logs ==="
    $COMPOSE_CMD -f local-run/docker-compose.local.yml logs quote-service
    echo "=== Translation Service Logs ==="
    $COMPOSE_CMD -f local-run/docker-compose.local.yml logs translation-service
    echo "=== E2E Test Logs ==="
    $COMPOSE_CMD -f local-run/docker-compose.local.yml logs e2e-tests
fi

# Clean up
echo "🧹 Cleaning up..."
$COMPOSE_CMD -f local-run/docker-compose.local.yml down -v

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ E2E tests completed successfully!"
else
    echo "❌ E2E tests failed with exit code $TEST_EXIT_CODE"
    exit $TEST_EXIT_CODE
fi
