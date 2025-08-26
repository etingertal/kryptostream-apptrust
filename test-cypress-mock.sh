#!/bin/bash
set -e

echo "🧪 Testing Cypress with Mock Services"
echo "====================================="

cd e2e-tests

# Check if npm dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
fi

echo "✅ npm dependencies ready"

# Create a simple mock server for testing
echo "🔧 Creating mock services..."
cat > mock-server.js << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Mock quote service endpoints
app.get('/actuator/health', (req, res) => {
  res.json({ status: 'UP' });
});

app.get('/api/quotes/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.get('/api/quotes/today', (req, res) => {
  res.json({
    text: "The only way to do great work is to love what you do.",
    author: "Steve Jobs"
  });
});

// Mock translation service endpoints
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    model_loaded: true 
  });
});

app.get('/', (req, res) => {
  res.json({ message: 'Translation service is running' });
});

app.post('/translate', (req, res) => {
  const { text, source_lang, target_lang } = req.body;
  res.json({
    original_text: text,
    translated_text: `[Translated to ${target_lang}] ${text}`,
    source_lang,
    target_lang
  });
});

app.listen(port, () => {
  console.log(`Mock server running on port ${port}`);
});
EOF

# Install express for mock server
if ! npm list express > /dev/null 2>&1; then
    echo "📦 Installing express for mock server..."
    npm install express
fi

# Start mock server in background
echo "🚀 Starting mock server..."
node mock-server.js &
MOCK_PID=$!

# Wait for server to start
sleep 3

# Update Cypress config to use mock server
echo "🔧 Updating Cypress configuration for mock server..."
cat > cypress.config.mock.js << 'EOF'
const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    supportFile: 'cypress/support/e2e.js',
    specPattern: 'cypress/e2e/**/*.cy.js',
    video: false,
    screenshotOnRunFailure: false,
    reporter: 'json',
    reporterOptions: {
      outputFile: 'cypress/results/results.json'
    },
    env: {
      quoteServiceUrl: 'http://localhost:3000',
      translationServiceUrl: 'http://localhost:3000'
    },
    defaultCommandTimeout: 10000,
    requestTimeout: 10000,
    responseTimeout: 10000,
    pageLoadTimeout: 30000,
    chromeWebSecurity: false,
    experimentalModifyObstructiveThirdPartyCode: false
  },
  reporter: 'json',
  reporterOptions: {
    outputFile: 'cypress/results/results.json'
  }
})
EOF

# Run Cypress tests against mock server
echo "🧪 Running Cypress tests against mock server..."
npx cypress run --config-file cypress.config.mock.js

# Check results
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Cypress tests completed successfully!"
    
    if [ -f "cypress/results/results.json" ]; then
        echo "📊 Test results:"
        cat cypress/results/results.json | jq '.runs[0].stats' 2>/dev/null || echo "   Results file exists but couldn't parse JSON"
    fi
else
    echo ""
    echo "❌ Cypress tests failed!"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
kill $MOCK_PID 2>/dev/null || true
rm -f mock-server.js cypress.config.mock.js

echo "✅ Mock service test completed!"
