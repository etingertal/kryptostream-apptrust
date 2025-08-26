#!/bin/bash
set -e

echo "🧪 Testing E2E Setup Locally"
echo "=============================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"

# Check if we're in the right directory
if [ ! -f "e2e-tests/docker-compose.yml.template" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

echo "✅ Found E2E test files"

# Set environment variables for local testing
export QUOTE_IMAGE_TAG="latest"
export TRANSLATION_IMAGE_TAG="latest"

echo "📋 Test Configuration:"
echo "   QUOTE_IMAGE_TAG: $QUOTE_IMAGE_TAG"
echo "   TRANSLATION_IMAGE_TAG: $TRANSLATION_IMAGE_TAG"

# Generate Docker Compose file
echo "🔧 Generating Docker Compose file..."
envsubst < e2e-tests/docker-compose.yml.template > e2e-test-compose-local.yml

echo "📄 Generated e2e-test-compose-local.yml"

# Show the generated file
echo "📋 Docker Compose configuration:"
cat e2e-test-compose-local.yml

echo ""
echo "🚀 Starting E2E tests..."
echo "=============================="

# Run the tests (ignore .env file)
docker compose -f e2e-test-compose-local.yml --env-file /dev/null up --abort-on-container-exit

# Check results
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ E2E tests completed successfully!"
    
    # Check if results file exists
    if [ -f "e2e-tests/cypress/results/results.json" ]; then
        echo "📊 Test results found:"
        cat e2e-tests/cypress/results/results.json | jq '.runs[0].stats' 2>/dev/null || echo "   Results file exists but couldn't parse JSON"
    else
        echo "⚠️  No test results file found"
    fi
else
    echo ""
    echo "❌ E2E tests failed!"
    exit 1
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
docker compose -f e2e-test-compose-local.yml down -v
rm -f e2e-test-compose-local.yml

echo "✅ Local E2E test completed!"
