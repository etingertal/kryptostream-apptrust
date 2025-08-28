#!/bin/bash

# Install dependencies
echo "Installing npm dependencies..."
npm ci

# Run Cypress with Docker configuration
echo "Running Cypress tests with Docker configuration..."
npx cypress run --config-file cypress.config.docker.js
