#!/bin/bash

echo "🔧 Setting up GitHub Actions runner environment..."
echo "================================================================"

# This script should be run as the user that runs the GitHub Actions runner
# It sets up the environment variables needed to fix SSL certificate issues

# Create a permanent certificate file
CERT_FILE="$HOME/macos_certs.pem"

echo "📋 Creating certificate file for runner..."
if [ ! -f "$CERT_FILE" ]; then
    echo "🔧 Extracting certificates from system keychain..."
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

# Create environment file for the runner
ENV_FILE="$HOME/.runner_env"

echo "📝 Creating runner environment file..."
cat > "$ENV_FILE" << EOF
# GitHub Actions Runner Environment Configuration
# Generated on: $(date)

# SSL Certificate Configuration
export SSL_CERT_FILE="$CERT_FILE"

# Java SSL Configuration
export JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false -Dcom.sun.net.ssl.checkServerName=false"

# Java Configuration
export JAVA_HOME=\$(/usr/libexec/java_home -v 21 2>/dev/null || echo "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home")
export PATH=\$JAVA_HOME/bin:\$PATH

# Maven Configuration
export MAVEN_HOME=\$(brew --prefix maven 2>/dev/null || echo "/opt/homebrew/Cellar/maven/*/libexec")
export PATH=\$MAVEN_HOME/bin:\$PATH

# Docker Configuration
export DOCKER_REGISTRY=evidencetrial.jfrog.io/commons-dev-docker-virtual

# Additional SSL Configuration
export CURL_CA_BUNDLE="$CERT_FILE"
export REQUESTS_CA_BUNDLE="$CERT_FILE"

# Display configuration
echo "🔧 Runner environment configured:"
echo "   SSL_CERT_FILE: \$SSL_CERT_FILE"
echo "   JAVA_HOME: \$JAVA_HOME"
echo "   MAVEN_HOME: \$MAVEN_HOME"
EOF

chmod 644 "$ENV_FILE"
echo "✅ Created environment file: $ENV_FILE"

# Create a startup script for the runner
STARTUP_SCRIPT="$HOME/start-runner.sh"

echo "📝 Creating runner startup script..."
cat > "$STARTUP_SCRIPT" << 'EOF'
#!/bin/bash

# GitHub Actions Runner Startup Script
# This script should be used to start the runner with proper environment

RUNNER_DIR="$HOME/actions-runner"
ENV_FILE="$HOME/.runner_env"

echo "🚀 Starting GitHub Actions runner..."

# Source the environment configuration
if [ -f "$ENV_FILE" ]; then
    echo "📋 Loading environment configuration..."
    source "$ENV_FILE"
else
    echo "❌ Environment file not found: $ENV_FILE"
    echo "   Run ./scripts/setup-runner-env.sh first"
    exit 1
fi

# Check if runner directory exists
if [ ! -d "$RUNNER_DIR" ]; then
    echo "❌ Runner directory not found: $RUNNER_DIR"
    echo "   Please install the GitHub Actions runner first"
    exit 1
fi

# Change to runner directory
cd "$RUNNER_DIR"

# Start the runner
echo "🔄 Starting runner..."
./run.sh
EOF

chmod +x "$STARTUP_SCRIPT"
echo "✅ Created startup script: $STARTUP_SCRIPT"

# Create a service configuration for the runner
SERVICE_FILE="$HOME/Library/LaunchAgents/com.github.actions.runner.plist"

echo "📝 Creating launch agent configuration..."
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.actions.runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$STARTUP_SCRIPT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/github-runner.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/github-runner-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>SSL_CERT_FILE</key>
        <string>$CERT_FILE</string>
        <key>JAVA_TOOL_OPTIONS</key>
        <string>-Dcom.sun.net.ssl.checkRevocation=false -Dcom.sun.net.ssl.checkServerName=false</string>
    </dict>
</dict>
</plist>
EOF

echo "✅ Created launch agent: $SERVICE_FILE"

# Instructions for the user
echo ""
echo "================================================================"
echo "✅ Runner environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Install the GitHub Actions runner if not already done:"
echo "   mkdir ~/actions-runner && cd ~/actions-runner"
echo "   curl -o actions-runner-osx-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz"
echo "   tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz"
echo ""
echo "2. Configure the runner with your repository:"
echo "   ./config.sh --url https://github.com/jfrog/evidence-integration --token YOUR_TOKEN"
echo ""
echo "3. Start the runner using the startup script:"
echo "   $STARTUP_SCRIPT"
echo ""
echo "4. Or load the launch agent to start automatically:"
echo "   launchctl load $SERVICE_FILE"
echo ""
echo "5. To stop the launch agent:"
echo "   launchctl unload $SERVICE_FILE"
echo ""
echo "📋 Environment files created:"
echo "   Certificate file: $CERT_FILE"
echo "   Environment config: $ENV_FILE"
echo "   Startup script: $STARTUP_SCRIPT"
echo "   Launch agent: $SERVICE_FILE"
echo ""
echo "🔧 To manually test the environment:"
echo "   source $ENV_FILE"
echo "   curl -v https://github.com"
echo "================================================================"
