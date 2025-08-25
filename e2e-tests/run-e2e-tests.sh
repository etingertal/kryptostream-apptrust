#!/bin/bash

set -e

echo "🚀 Starting End-to-End Tests"
echo "================================"

# Configuration
QUOTE_SERVICE_URL=${QUOTE_SERVICE_URL:-"http://quote-service:8080"}
TRANSLATION_SERVICE_URL=${TRANSLATION_SERVICE_URL:-"http://translation-service:8000"}
TEST_TIMEOUT=${TEST_TIMEOUT:-300}

echo "📋 Test Configuration:"
echo "  Quote Service URL: $QUOTE_SERVICE_URL"
echo "  Translation Service URL: $TRANSLATION_SERVICE_URL"
echo "  Test Timeout: ${TEST_TIMEOUT}s"
echo ""

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
python wait_for_services.py

# Run the tests
echo "🧪 Running E2E tests..."
python -m pytest test_e2e.py -v --timeout=$TEST_TIMEOUT

echo "✅ E2E tests completed successfully!"
