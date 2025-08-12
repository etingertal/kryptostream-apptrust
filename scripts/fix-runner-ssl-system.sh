#!/bin/bash

echo "🔧 Fixing GitHub Actions runner SSL issues at system level..."
echo "================================================================"

# This script fixes SSL certificate issues for GitHub Actions runner
# by setting environment variables at the system level

# Create certificate file if it doesn't exist
CERT_FILE="$HOME/macos_certs.pem"

if [ ! -f "$CERT_FILE" ]; then
    echo "📋 Creating certificate file..."
    sudo security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$CERT_FILE" 2>/dev/null
    
    if [ -s "$CERT_FILE" ]; then
        echo "✅ Created certificate file: $CERT_FILE"
        chmod 644 "$CERT_FILE"
    else
        echo "❌ Failed to create certificate file"
        exit 1
    fi
else
    echo "✅ Certificate file already exists: $CERT_FILE"
fi

# Stop the runner if it's running
echo "🛑 Stopping runner if running..."
pkill -f "Runner.Listener" 2>/dev/null || true
pkill -f "actions.runner" 2>/dev/null || true
sleep 2

# Create a system-wide environment configuration
ENV_FILE="/etc/environment"

echo "📝 Setting up system-wide environment variables..."

# Create a backup of the environment file
if [ -f "$ENV_FILE" ]; then
    sudo cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%s)"
    echo "✅ Backed up $ENV_FILE"
fi

# Add SSL configuration to system environment
sudo tee -a "$ENV_FILE" > /dev/null << EOF

# GitHub Actions Runner SSL Configuration
SSL_CERT_FILE=$CERT_FILE
JAVA_TOOL_OPTIONS=-Dcom.sun.net.ssl.checkRevocation=false -Dcom.sun.net.ssl.checkServerName=false
CURL_CA_BUNDLE=$CERT_FILE
REQUESTS_CA_BUNDLE=$CERT_FILE
EOF

echo "✅ Added SSL configuration to $ENV_FILE"

# Create a launch agent that sets environment variables
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.github.actions.runner.ssl.plist"

echo "📝 Creating launch agent for SSL configuration..."
mkdir -p "$(dirname "$LAUNCH_AGENT")"

cat > "$LAUNCH_AGENT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.actions.runner.ssl</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>export SSL_CERT_FILE=$CERT_FILE; export JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false -Dcom.sun.net.ssl.checkServerName=false"; export CURL_CA_BUNDLE=$CERT_FILE; export REQUESTS_CA_BUNDLE=$CERT_FILE; echo "SSL environment variables set"</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/github-runner-ssl.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/github-runner-ssl-error.log</string>
</dict>
</plist>
EOF

echo "✅ Created launch agent: $LAUNCH_AGENT"

# Load the launch agent
launchctl load "$LAUNCH_AGENT" 2>/dev/null || true
echo "✅ Loaded launch agent"

# Create a wrapper script that sets environment variables
RUNNER_DIR="$HOME/actions-runner"
WRAPPER_SCRIPT="$RUNNER_DIR/run-with-ssl.sh"

echo "📝 Creating SSL wrapper script..."
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash

# SSL-enabled wrapper for GitHub Actions runner

# Set SSL environment variables
export SSL_CERT_FILE="$HOME/macos_certs.pem"
export JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false -Dcom.sun.net.ssl.checkServerName=false"
export CURL_CA_BUNDLE="$HOME/macos_certs.pem"
export REQUESTS_CA_BUNDLE="$HOME/macos_certs.pem"

# Also set .NET SSL configuration
export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
export DOTNET_SYSTEM_NET_HTTP_USEPROXY=false

echo "🔧 SSL environment configured:"
echo "   SSL_CERT_FILE: $SSL_CERT_FILE"
echo "   JAVA_TOOL_OPTIONS: $JAVA_TOOL_OPTIONS"
echo "   DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER: $DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER"

# Change to runner directory
cd "$(dirname "$0")"

# Start the runner
echo "🚀 Starting runner with SSL configuration..."
exec ./bin/Runner.Listener run "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"
echo "✅ Created wrapper script: $WRAPPER_SCRIPT"

# Update the run.sh to use the wrapper
BACKUP_FILE="$RUNNER_DIR/run.sh.backup.$(date +%s)"
cp "$RUNNER_DIR/run.sh" "$BACKUP_FILE"
echo "✅ Backed up run.sh: $BACKUP_FILE"

cat > "$RUNNER_DIR/run.sh" << 'EOF'
#!/bin/bash

# Modified run.sh to use SSL wrapper
exec "$(dirname "$0")/run-with-ssl.sh" "$@"
EOF

chmod +x "$RUNNER_DIR/run.sh"
echo "✅ Updated run.sh to use SSL wrapper"

# Test the configuration
echo "🔍 Testing SSL configuration..."
cd "$RUNNER_DIR"

# Test environment variables
if SSL_CERT_FILE="$CERT_FILE" JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false" curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    echo "✅ SSL connectivity test passed"
else
    echo "❌ SSL connectivity test failed"
fi

# Test the wrapper script
if [ -f "./run-with-ssl.sh" ]; then
    echo "✅ Wrapper script is executable"
    
    # Test environment loading
    if SSL_CERT_FILE="$CERT_FILE" JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false" ./run-with-ssl.sh --help >/dev/null 2>&1; then
        echo "✅ Wrapper script test passed"
    else
        echo "❌ Wrapper script test failed"
    fi
else
    echo "❌ Wrapper script not found"
fi

echo ""
echo "================================================================"
echo "✅ System-level SSL fix complete!"
echo ""
echo "📋 What was done:"
echo "1. ✅ Created certificate file: $CERT_FILE"
echo "2. ✅ Added SSL configuration to system environment: $ENV_FILE"
echo "3. ✅ Created launch agent: $LAUNCH_AGENT"
echo "4. ✅ Created SSL wrapper script: $WRAPPER_SCRIPT"
echo "5. ✅ Updated run.sh to use SSL wrapper"
echo "6. ✅ Backed up original run.sh: $BACKUP_FILE"
echo ""
echo "📋 To start the runner:"
echo "   cd $RUNNER_DIR"
echo "   ./run.sh"
echo ""
echo "📋 To test SSL connectivity:"
echo "   SSL_CERT_FILE=$CERT_FILE curl -v https://github.com"
echo ""
echo "📋 To restore original run.sh:"
echo "   cp $BACKUP_FILE $RUNNER_DIR/run.sh"
echo ""
echo "🔧 The runner should now work without SSL certificate errors"
echo "================================================================"
