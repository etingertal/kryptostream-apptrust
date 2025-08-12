#!/bin/bash

echo "🔧 Fixing SSL certificate issues for self-hosted runner..."
echo "================================================================"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 Detected macOS"
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Detected Linux"
    OS="linux"
else
    echo "❓ Unknown OS: $OSTYPE"
    exit 1
fi

# Function to check if a certificate file exists and is valid
check_cert_file() {
    local cert_file="$1"
    if [ -f "$cert_file" ]; then
        echo "✅ Found: $cert_file"
        return 0
    else
        echo "❌ Not found: $cert_file"
        return 1
    fi
}

# Function to test SSL connectivity
test_ssl_connectivity() {
    echo "🔍 Testing SSL connectivity..."
    
    # Test GitHub
    if curl -s --connect-timeout 10 https://github.com >/dev/null 2>&1; then
        echo "✅ Can reach GitHub"
    else
        echo "❌ Cannot reach GitHub"
        return 1
    fi
    
    # Test Adoptium
    if curl -s --connect-timeout 10 https://adoptium.net >/dev/null 2>&1; then
        echo "✅ Can reach Adoptium"
    else
        echo "❌ Cannot reach Adoptium"
        return 1
    fi
    
    return 0
}

# Check current SSL certificate configuration
echo "📋 Current SSL Configuration:"
if [ -n "$SSL_CERT_FILE" ]; then
    echo "SSL_CERT_FILE: $SSL_CERT_FILE"
    check_cert_file "$SSL_CERT_FILE"
else
    echo "SSL_CERT_FILE: Not set"
fi

if [ -n "$JAVA_TOOL_OPTIONS" ]; then
    echo "JAVA_TOOL_OPTIONS: $JAVA_TOOL_OPTIONS"
else
    echo "JAVA_TOOL_OPTIONS: Not set"
fi

echo ""

# Test current connectivity
if test_ssl_connectivity; then
    echo "✅ SSL connectivity is working!"
    exit 0
fi

echo "❌ SSL connectivity issues detected. Attempting fixes..."

# Fix 1: Set SSL_CERT_FILE for macOS
if [ "$OS" = "macos" ]; then
    echo "🔧 Fix 1: Setting SSL_CERT_FILE for macOS..."
    
    # Try different certificate locations
    CERT_LOCATIONS=(
        "/opt/homebrew/opt/openssl@3/etc/ssl/cert.pem"
        "/opt/homebrew/etc/openssl/cert.pem"
        "/usr/local/etc/openssl/cert.pem"
        "/etc/ssl/certs/ca-certificates.crt"
    )
    
    for cert_file in "${CERT_LOCATIONS[@]}"; do
        if check_cert_file "$cert_file"; then
            export SSL_CERT_FILE="$cert_file"
            echo "✅ Set SSL_CERT_FILE to: $cert_file"
            break
        fi
    done
    
    # If no certificate file found, create one from system keychain
    if [ -z "$SSL_CERT_FILE" ]; then
        echo "🔧 Creating certificate file from system keychain..."
        
        # Create a temporary certificate file
        TEMP_CERT_FILE="/tmp/macos_certs_$(date +%s).pem"
        
        # Extract certificates from system keychain
        if sudo security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$TEMP_CERT_FILE" 2>/dev/null; then
            if [ -s "$TEMP_CERT_FILE" ]; then
                export SSL_CERT_FILE="$TEMP_CERT_FILE"
                echo "✅ Created certificate file: $TEMP_CERT_FILE"
                echo "📋 Note: This is a temporary file. Consider creating a permanent one."
            else
                rm -f "$TEMP_CERT_FILE"
                echo "❌ Failed to extract certificates from keychain"
            fi
        else
            echo "❌ Failed to access system keychain"
        fi
    fi

# Fix 1: Set SSL_CERT_FILE for Linux
elif [ "$OS" = "linux" ]; then
    echo "🔧 Fix 1: Setting SSL_CERT_FILE for Linux..."
    
    CERT_LOCATIONS=(
        "/etc/ssl/certs/ca-certificates.crt"
        "/etc/pki/tls/certs/ca-bundle.crt"
        "/usr/share/ssl/certs/ca-bundle.crt"
    )
    
    for cert_file in "${CERT_LOCATIONS[@]}"; do
        if check_cert_file "$cert_file"; then
            export SSL_CERT_FILE="$cert_file"
            echo "✅ Set SSL_CERT_FILE to: $cert_file"
            break
        fi
    done
fi

# Fix 2: Disable SSL verification for Java (less secure but effective)
echo "🔧 Fix 2: Setting Java SSL options..."
export JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false -Dcom.sun.net.ssl.checkServerName=false"
echo "✅ Set JAVA_TOOL_OPTIONS: $JAVA_TOOL_OPTIONS"

# Fix 3: Update CA certificates if possible
echo "🔧 Fix 3: Attempting to update CA certificates..."
if command -v brew >/dev/null 2>&1; then
    echo "📦 Using Homebrew to update certificates..."
    brew install ca-certificates 2>/dev/null || echo "⚠️ Could not install ca-certificates via Homebrew"
elif command -v apt-get >/dev/null 2>&1; then
    echo "📦 Using apt-get to update certificates..."
    sudo apt-get update && sudo apt-get install -y ca-certificates 2>/dev/null || echo "⚠️ Could not install ca-certificates via apt-get"
elif command -v yum >/dev/null 2>&1; then
    echo "📦 Using yum to update certificates..."
    sudo yum install -y ca-certificates 2>/dev/null || echo "⚠️ Could not install ca-certificates via yum"
else
    echo "⚠️ No package manager found for certificate updates"
fi

# Test connectivity again
echo ""
echo "🔍 Testing SSL connectivity after fixes..."
if test_ssl_connectivity; then
    echo "✅ SSL connectivity is now working!"
    
    # Create environment file for runner
    echo "📝 Creating environment file for runner..."
    cat > .env.runner << EOF
# SSL Certificate Configuration
SSL_CERT_FILE=$SSL_CERT_FILE
JAVA_TOOL_OPTIONS=$JAVA_TOOL_OPTIONS

# Additional environment variables
export SSL_CERT_FILE
export JAVA_TOOL_OPTIONS
EOF
    
    echo "✅ Created .env.runner file with SSL configuration"
    echo "📋 To use this configuration:"
    echo "   source .env.runner"
    echo "   # or add to your runner startup script"
    
else
    echo "❌ SSL connectivity still not working after fixes"
    echo "📋 Manual steps to try:"
    echo "   1. Check your network/firewall settings"
    echo "   2. Try using a VPN or different network"
    echo "   3. Contact your network administrator"
    echo "   4. Consider using a different runner or GitHub-hosted runners"
fi

echo ""
echo "================================================================"
echo "🔧 SSL certificate fix attempt complete!"
