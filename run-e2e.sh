#!/bin/bash

# Simple wrapper script to run E2E tests from the project root
# This script delegates to the actual E2E test runner in the local-run directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_SCRIPT="$SCRIPT_DIR/local-run/run-e2e-local.sh"

if [ ! -f "$E2E_SCRIPT" ]; then
    echo "❌ E2E test script not found at: $E2E_SCRIPT"
    echo "Please make sure you're running this from the project root directory"
    exit 1
fi

echo "🚀 Running E2E tests from project root..."
echo "📁 Using script: $E2E_SCRIPT"
echo ""

# Execute the E2E test script
exec "$E2E_SCRIPT"
