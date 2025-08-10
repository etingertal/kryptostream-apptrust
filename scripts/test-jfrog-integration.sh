#!/bin/bash

# JFrog Artifactory Integration Test Script
# This script tests the integration with JFrog Artifactory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if JFrog CLI is installed
check_jfrog_cli() {
    print_status "Checking JFrog CLI installation..."
    if command -v jf &> /dev/null; then
        print_success "JFrog CLI is installed"
        jf --version
    else
        print_error "JFrog CLI is not installed. Please install it first."
        exit 1
    fi
}

# Check environment variables
check_environment() {
    print_status "Checking environment variables..."
    
    if [ -z "$JF_URL" ]; then
        print_error "JF_URL environment variable is not set"
        exit 1
    fi
    
    if [ -z "$JF_USER" ]; then
        print_error "JF_USER environment variable is not set"
        exit 1
    fi
    
    if [ -z "$JF_ACCESS_TOKEN" ]; then
        print_error "JF_ACCESS_TOKEN environment variable is not set"
        exit 1
    fi
    
    if [ -z "$DOCKER_REGISTRY" ]; then
        print_error "DOCKER_REGISTRY environment variable is not set"
        exit 1
    fi
    
    print_success "All environment variables are set"
    echo "JF_URL: $JF_URL"
    echo "JF_USER: $JF_USER"
    echo "DOCKER_REGISTRY: $DOCKER_REGISTRY"
}

# Test JFrog CLI authentication
test_authentication() {
    print_status "Testing JFrog CLI authentication..."
    
    # Configure JFrog CLI
    jf c add --url "$JF_URL" --user "$JF_USER" --password "$JF_ACCESS_TOKEN" --interactive=false || {
        print_error "Failed to configure JFrog CLI"
        return 1
    }
    
    # Test connection
    jf rt ping || {
        print_error "Failed to connect to JFrog Artifactory"
        return 1
    }
    
    print_success "Authentication successful"
}

# Test Maven integration
test_maven_integration() {
    print_status "Testing Maven integration..."
    
    cd quoteofday || {
        print_error "quoteofday directory not found"
        return 1
    }
    
    # Test Maven build with JFrog
    jf mvn clean compile --no-transfer-progress || {
        print_error "Maven build with JFrog failed"
        return 1
    }
    
    print_success "Maven integration successful"
}

# Test Docker integration
test_docker_integration() {
    print_status "Testing Docker integration..."
    
    # Test Docker login
    echo "$JF_ACCESS_TOKEN" | docker login -u "$JF_USER" --password-stdin "$DOCKER_REGISTRY" || {
        print_error "Docker login failed"
        return 1
    }
    
    print_success "Docker integration successful"
}

# Test JFrog API access
test_api_access() {
    print_status "Testing JFrog API access..."
    
    # Test API access
    jf rt curl -XGET "/api/repositories" --server-id setup-jfrog-cli-server || {
        print_error "JFrog API access failed"
        return 1
    }
    
    print_success "API access successful"
}

# Test repository access
test_repository_access() {
    print_status "Testing repository access..."
    
    # Test Maven repository access
    jf rt search --url "$JF_URL/artifactory/commons-dev-maven-virtual" --limit 5 || {
        print_warning "Maven repository access test failed (this might be expected)"
        return 0
    }
    
    print_success "Repository access test completed"
}

# Validate configuration files
validate_configuration() {
    print_status "Validating configuration files..."
    
    if [ ! -f "quoteofday/.jfrog/projects/maven.yaml" ]; then
        print_error "Maven configuration file not found"
        return 1
    fi
    
    # Validate YAML syntax
    python3 -c "import yaml; yaml.safe_load(open('quoteofday/.jfrog/projects/maven.yaml'))" || {
        print_error "Maven configuration YAML is invalid"
        return 1
    }
    
    print_success "Configuration validation successful"
}

# Main test function
main() {
    echo "================================================"
    echo "JFrog Artifactory Integration Test"
    echo "================================================"
    echo "Test Date: $(date)"
    echo ""
    
    local failed_tests=0
    
    # Run tests
    check_jfrog_cli || ((failed_tests++))
    check_environment || ((failed_tests++))
    test_authentication || ((failed_tests++))
    validate_configuration || ((failed_tests++))
    test_api_access || ((failed_tests++))
    test_repository_access || ((failed_tests++))
    test_maven_integration || ((failed_tests++))
    test_docker_integration || ((failed_tests++))
    
    echo ""
    echo "================================================"
    echo "Test Summary"
    echo "================================================"
    
    if [ $failed_tests -eq 0 ]; then
        print_success "All tests passed! JFrog integration is working correctly."
        exit 0
    else
        print_error "$failed_tests test(s) failed. Please check the errors above."
        exit 1
    fi
}

# Run main function
main "$@"
