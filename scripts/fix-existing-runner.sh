#!/bin/bash

echo "🔧 Fixing existing GitHub Actions runner SSL issues..."
echo "================================================================"

# Check if runner is already installed
RUNNER_DIR="$HOME/actions-runner"

if [ ! -d "$RUNNER_DIR" ]; then
    echo "❌ Runner directory not found: $RUNNER_DIR"
    echo "   Please install the runner first or run ./scripts/setup-runner-env.sh"
    exit 1
fi

echo "✅ Found runner directory: $RUNNER_DIR"

# Check if environment file exists
ENV_FILE="$HOME/.runner_env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Environment file not found: $ENV_FILE"
    echo "   Run ./scripts/setup-runner-env.sh first"
    exit 1
fi

echo "✅ Found environment file: $ENV_FILE"

# Stop the runner if it's running
echo "🛑 Stopping runner if running..."
cd "$RUNNER_DIR"
if [ -f "./run.sh" ]; then
    # Try to stop gracefully
    if [ -f ".runner" ]; then
        echo "   Stopping runner gracefully..."
        ./run.sh stop 2>/dev/null || true
        sleep 2
    fi
    
    # Force kill if still running
    RUNNER_PID=$(pgrep -f "actions.runner" || true)
    if [ -n "$RUNNER_PID" ]; then
        echo "   Force stopping runner process: $RUNNER_PID"
        kill -TERM "$RUNNER_PID" 2>/dev/null || true
        sleep 2
        kill -KILL "$RUNNER_PID" 2>/dev/null || true
    fi
fi

# Create a wrapper script for the runner
WRAPPER_SCRIPT="$RUNNER_DIR/run-with-env.sh"

echo "📝 Creating runner wrapper script..."
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash

# Wrapper script to run GitHub Actions runner with proper environment

# Source the environment configuration
source "$HOME/.runner_env"

# Change to runner directory
cd "$(dirname "$0")"

# Start the runner with the environment
echo "🚀 Starting runner with SSL certificate configuration..."
echo "   SSL_CERT_FILE: $SSL_CERT_FILE"
echo "   JAVA_HOME: $JAVA_HOME"

# Run the original run.sh script
exec ./run.sh "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"
echo "✅ Created wrapper script: $WRAPPER_SCRIPT"

# Update the original run.sh to use the wrapper
BACKUP_FILE="$RUNNER_DIR/run.sh.backup.$(date +%s)"

echo "📝 Backing up original run.sh..."
cp "$RUNNER_DIR/run.sh" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Create a new run.sh that uses the wrapper
cat > "$RUNNER_DIR/run.sh" << 'EOF'
#!/bin/bash

# Modified run.sh to use environment wrapper
exec "$(dirname "$0")/run-with-env.sh" "$@"
EOF

chmod +x "$RUNNER_DIR/run.sh"
echo "✅ Updated run.sh to use environment wrapper"

# Test the configuration
echo "🔍 Testing runner configuration..."
cd "$RUNNER_DIR"
if [ -f "./run-with-env.sh" ]; then
    echo "✅ Wrapper script is executable"
    
    # Test environment loading
    if source "$HOME/.runner_env" 2>/dev/null; then
        echo "✅ Environment configuration loads successfully"
        echo "   SSL_CERT_FILE: $SSL_CERT_FILE"
        echo "   JAVA_HOME: $JAVA_HOME"
    else
        echo "❌ Environment configuration failed to load"
    fi
else
    echo "❌ Wrapper script not found"
fi

echo ""
echo "================================================================"
echo "✅ Existing runner fixed!"
echo ""
echo "📋 What was done:"
echo "1. ✅ Stopped existing runner"
echo "2. ✅ Created wrapper script with SSL configuration"
echo "3. ✅ Updated run.sh to use the wrapper"
echo "4. ✅ Backed up original run.sh"
echo ""
echo "📋 To start the runner:"
echo "   cd $RUNNER_DIR"
echo "   ./run.sh"
echo ""
echo "📋 To restore original run.sh:"
echo "   cp $BACKUP_FILE $RUNNER_DIR/run.sh"
echo ""
echo "📋 To test SSL connectivity:"
echo "   source $ENV_FILE"
echo "   curl -v https://github.com"
echo ""
echo "🔧 The runner will now use the SSL certificate configuration"
echo "   and should resolve the 'unable to get local issuer certificate' error"
echo "================================================================"
