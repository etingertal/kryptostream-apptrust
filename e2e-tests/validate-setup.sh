#!/bin/bash

set -e

echo "🔍 Validating E2E Test Setup"
echo "============================="

# Check if we're in the right directory
if [ ! -f "docker-compose.local.yml" ]; then
    echo "❌ docker-compose.local.yml not found. Please run this from the local-run directory."
    exit 1
fi

# Check if all required files exist
echo "📁 Checking required files..."

REQUIRED_FILES=(
    "docker-compose.local.yml"
    "Dockerfile.e2e"
    "e2e-tests/requirements.txt"
    "e2e-tests/test_e2e.py"
    "e2e-tests/run-e2e-tests.sh"
    "e2e-tests/wait_for_services.py"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING"
        exit 1
    fi
done

# Check if parent directories exist
echo ""
echo "📁 Checking parent service directories..."

PARENT_DIRS=(
    "../quoteofday"
    "../translate"
)

for dir in "${PARENT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir"
    else
        echo "❌ $dir - MISSING"
        exit 1
    fi
done

# Check if Docker Compose configuration is valid
echo ""
echo "🔧 Validating Docker Compose configuration..."

if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose.local.yml config > /dev/null
    echo "✅ Docker Compose configuration is valid"
elif command -v podman-compose &> /dev/null; then
    podman-compose -f docker-compose.local.yml config > /dev/null
    echo "✅ Podman Compose configuration is valid"
else
    echo "⚠️  Neither docker-compose nor podman-compose found"
    echo "   Configuration validation skipped"
fi

# Check if Python test dependencies are valid
echo ""
echo "🐍 Validating Python test dependencies..."

if [ -f "e2e-tests/requirements.txt" ]; then
    echo "✅ requirements.txt found"
    echo "   Dependencies:"
    while IFS= read -r line; do
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
            echo "   - $line"
        fi
    done < "e2e-tests/requirements.txt"
else
    echo "❌ requirements.txt not found"
    exit 1
fi

echo ""
echo "🎉 E2E test setup validation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Run from project root: ./e2e-tests/run-e2e.sh"
echo "   2. Or run from this directory: ./run-e2e-local.sh"
echo "   3. Or manually: docker-compose -f docker-compose.local.yml up --build"
