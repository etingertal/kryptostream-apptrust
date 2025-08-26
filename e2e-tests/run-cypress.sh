#!/bin/bash
set -e

echo "🚀 Starting E2E test setup..."

# Install dependencies
echo "📦 Installing npm dependencies..."
npm ci --cache /root/.npm --prefer-offline

# Run tests with quiet output to ensure clean JSON
echo "🧪 Running Cypress tests..."
npm run test -- --quiet

echo "✅ E2E tests completed"
