#!/bin/bash
set -e

echo "🚀 Starting E2E test setup..."

# Install dependencies
echo "📦 Installing npm dependencies..."
npm ci --cache /root/.npm --prefer-offline

# Run tests to generate JSON results
echo "🧪 Running Cypress tests..."
npm run test > cypress-results.json

echo "✅ E2E tests completed"
