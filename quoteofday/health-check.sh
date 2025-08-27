#!/bin/bash

# Health check script for Spring Boot application
# Uses wget (already available in eclipse-temurin base image)

set -e

# Configuration
HEALTH_ENDPOINT="http://localhost:8080/actuator/health"
TIMEOUT=10

# Function to check if port is listening (fallback)
check_port() {
    local port=$1
    local timeout=${2:-5}
    
    # Use /dev/tcp (bash built-in) to check if port is open
    timeout $timeout bash -c "</dev/tcp/localhost/$port" 2>/dev/null
    return $?
}

# Function to check HTTP health endpoint using wget
check_health_endpoint() {
    local url=$1
    local timeout=${2:-5}
    
    # Use wget to check health endpoint
    wget --no-verbose --tries=1 --timeout=$timeout --spider "$url" >/dev/null 2>&1
    return $?
}

# Main health check logic
main() {
    # First check if port is listening (quick check)
    if ! check_port 8080 3; then
        echo "Health check failed: Port 8080 not listening"
        exit 1
    fi
    
    # Then check health endpoint
    if check_health_endpoint "$HEALTH_ENDPOINT" 5; then
        echo "Health check passed"
        exit 0
    else
        echo "Health check failed: Health endpoint not responding"
        exit 1
    fi
}

# Run main function
main "$@"
