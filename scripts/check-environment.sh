#!/bin/bash

echo "🔍 Checking environment for GitHub Actions self-hosted runner..."
echo "================================================================"

# Check Java
echo "📋 Java:"
if command -v java >/dev/null 2>&1; then
    java -version 2>&1 | head -1
    echo "✅ Java is installed"
else
    echo "❌ Java is not installed"
fi

# Check Maven
echo -e "\n📋 Maven:"
if command -v mvn >/dev/null 2>&1; then
    mvn -version 2>&1 | head -1
    echo "✅ Maven is installed"
else
    echo "❌ Maven is not installed"
fi

# Check Docker
echo -e "\n📋 Docker:"
if command -v docker >/dev/null 2>&1; then
    docker --version 2>&1 | head -1
    echo "✅ Docker is installed"
else
    echo "❌ Docker is not installed"
fi

# Check Git
echo -e "\n📋 Git:"
if command -v git >/dev/null 2>&1; then
    git --version 2>&1 | head -1
    echo "✅ Git is installed"
else
    echo "❌ Git is not installed"
fi

# Check GitHub CLI
echo -e "\n📋 GitHub CLI:"
if command -v gh >/dev/null 2>&1; then
    gh --version 2>&1 | head -1
    echo "✅ GitHub CLI is installed"
else
    echo "❌ GitHub CLI is not installed"
fi

# Check required tools for the script
echo -e "\n📋 Script Dependencies:"
if command -v xmllint >/dev/null 2>&1; then
    echo "✅ xmllint is available"
else
    echo "❌ xmllint is not available (will use grep fallback)"
fi

if command -v jq >/dev/null 2>&1; then
    echo "✅ jq is available"
else
    echo "❌ jq is not available (will use python fallback)"
fi

if command -v python3 >/dev/null 2>&1; then
    echo "✅ python3 is available"
else
    echo "❌ python3 is not available"
fi

# Check SSL certificates
echo -e "\n📋 SSL Certificates:"
if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
    echo "✅ Linux CA certificates found"
elif [ -f "/System/Library/OpenSSL/cert.pem" ]; then
    echo "✅ macOS CA certificates found"
else
    echo "❌ CA certificates not found in standard locations"
fi

# Check environment variables
echo -e "\n📋 Environment Variables:"
if [ -n "$JAVA_HOME" ]; then
    echo "✅ JAVA_HOME is set: $JAVA_HOME"
else
    echo "❌ JAVA_HOME is not set"
fi

if [ -n "$MAVEN_HOME" ]; then
    echo "✅ MAVEN_HOME is set: $MAVEN_HOME"
else
    echo "❌ MAVEN_HOME is not set"
fi

# Check network connectivity
echo -e "\n📋 Network Connectivity:"
if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    echo "✅ Can reach GitHub"
else
    echo "❌ Cannot reach GitHub"
fi

if curl -s --connect-timeout 5 https://adoptium.net >/dev/null 2>&1; then
    echo "✅ Can reach Adoptium (Java downloads)"
else
    echo "❌ Cannot reach Adoptium"
fi

echo -e "\n================================================================"
echo "🔍 Environment check complete!"
