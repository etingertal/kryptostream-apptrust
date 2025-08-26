#!/bin/bash
set -e

echo "🚀 Starting E2E test setup..."

# Install dependencies
echo "📦 Installing npm dependencies..."
npm ci --cache /root/.npm --prefer-offline

# Run tests
echo "🧪 Running Cypress tests..."
npm run test

echo "✅ E2E tests completed"
