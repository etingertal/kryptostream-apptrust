#!/bin/bash
set -e

echo "🚀 Starting E2E test setup..."

# Install dependencies
echo "📦 Installing npm dependencies..."
npm ci

# Debug: Check current directory and files
echo "🔍 Current directory: $(pwd)"
echo "🔍 Directory contents before running tests:"
ls -la

# Run tests with mochawesome reporter
echo "🧪 Running Cypress tests with mochawesome reporter..."
npx cypress run --spec 'cypress/e2e/**/*.cy.js'

# Debug: Check what files were created
echo "🔍 Directory contents after running tests:"
ls -la

# Check if the mochawesome results were created and merge them
echo "🔍 Checking for mochawesome results..."
if [ -d "cypress/results/mochawesome" ] && [ "$(ls -A cypress/results/mochawesome)" ]; then
  echo "✅ Mochawesome results found!"
  echo "📊 Number of result files: $(ls cypress/results/mochawesome/*.json 2>/dev/null | wc -l)"
  
  # Merge the JSON files
  echo "🔄 Merging JSON reports..."
  npx mochawesome-merge cypress/results/mochawesome/*.json > cypress/results/combined-report.json
  
  if [ -f "cypress/results/combined-report.json" ]; then
    echo "✅ Combined report created!"
    echo "📊 Combined report size: $(wc -c < cypress/results/combined-report.json) bytes"
    echo "📋 First 10 lines of combined report:"
    head -10 cypress/results/combined-report.json
  else
    echo "❌ Failed to create combined report"
  fi
else
  echo "❌ Mochawesome results not found"
  echo "🔍 Looking for any result files:"
  find . -name "*results*" -type f 2>/dev/null || echo "No result files found"
fi

echo "✅ E2E tests completed"
