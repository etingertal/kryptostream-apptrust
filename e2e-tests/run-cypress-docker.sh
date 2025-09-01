#!/bin/bash

# Install dependencies
echo "Installing npm dependencies..."
npm ci

# Run Cypress with Docker configuration
echo "Running Cypress tests with Docker configuration..."
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la

echo "Checking if cypress.config.docker.js exists:"
if [ -f "cypress.config.docker.js" ]; then
    echo "✅ cypress.config.docker.js found"
    cat cypress.config.docker.js
else
    echo "❌ cypress.config.docker.js not found"
    exit 1
fi

npx cypress run --config-file cypress.config.docker.js
