#!/bin/bash
set -e

echo "🧪 Testing Cypress Setup Only"
echo "=============================="

cd e2e-tests

# Check if npm dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
else
    echo "✅ npm dependencies already installed"
fi

# Check if Cypress is available
if ! npx cypress --version > /dev/null 2>&1; then
    echo "❌ Cypress is not available. Please check the installation."
    exit 1
fi

echo "✅ Cypress is available"

# Test Cypress configuration
echo "🔧 Testing Cypress configuration..."
npx cypress verify

# Show Cypress info
echo "📋 Cypress information:"
npx cypress info

echo ""
echo "✅ Cypress setup test completed!"
echo ""
echo "To run tests against mock services, you can use:"
echo "  cd e2e-tests"
echo "  npx cypress open"
echo ""
echo "To run tests in headless mode:"
echo "  cd e2e-tests"
echo "  npm run test"
