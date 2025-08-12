# Self-Hosted GitHub Actions Runner Setup Guide

## Overview
This guide helps you set up a self-hosted GitHub Actions runner on macOS to run the Quote of Day Service CI workflow.

## Prerequisites

### 1. Required Tools
Make sure you have the following tools installed:

```bash
# Check if tools are installed
./scripts/check-environment.sh
```

### 2. Install Missing Tools

#### Java 21 (Temurin)
```bash
# Using Homebrew
brew install --cask temurin21

# Or download from Adoptium
# https://adoptium.net/temurin/releases/?version=21
```

#### Maven
```bash
# Using Homebrew
brew install maven
```

#### Docker
```bash
# Using Homebrew
brew install --cask docker
```

#### GitHub CLI
```bash
# Using Homebrew
brew install gh
```

#### Additional Tools
```bash
# Install additional dependencies
brew install jq xmllint curl

# Or install via package managers
# jq: JSON processor
# xmllint: XML processor (part of libxml2)
```

## SSL Certificate Issues

The "unable to get local issuer certificate" error is common with self-hosted runners. Here are solutions:

### Solution 1: Set SSL Certificate Path
Add to your runner environment (`.env` file or runner configuration):

```bash
# For macOS - extract certificates from system keychain
sudo security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > /tmp/macos_certs.pem
export SSL_CERT_FILE=/tmp/macos_certs.pem

# For Linux
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
```

### Solution 2: Disable SSL Verification (Less Secure)
```bash
export JAVA_TOOL_OPTIONS="-Dcom.sun.net.ssl.checkRevocation=false"
```

### Solution 3: Update CA Certificates
```bash
# Install/update CA certificates
brew install ca-certificates

# Or manually extract from system keychain (macOS)
sudo security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > ~/macos_certs.pem
export SSL_CERT_FILE=~/macos_certs.pem
```

## Runner Configuration

### 1. Environment Variables
Set these environment variables for your runner:

```bash
# Java
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH

# Maven
export MAVEN_HOME=/opt/homebrew/Cellar/maven/*/libexec
export PATH=$MAVEN_HOME/bin:$PATH

# Docker
export DOCKER_REGISTRY=evidencetrial.jfrog.io/commons-dev-docker-virtual

# SSL Certificates
export SSL_CERT_FILE=/tmp/macos_certs.pem
```

### 2. Runner Service Configuration
Create a `.env` file in your runner directory:

```bash
# Runner environment variables
JAVA_HOME=$(/usr/libexec/java_home -v 21)
MAVEN_HOME=/opt/homebrew/Cellar/maven/*/libexec
SSL_CERT_FILE=/System/Library/OpenSSL/cert.pem
DOCKER_REGISTRY=evidencetrial.jfrog.io/commons-dev-docker-virtual
```

### 3. Runner Labels
Configure your runner with appropriate labels:

```bash
# When setting up the runner, add these labels:
macos,self-hosted,java21,maven,docker
```

## Testing the Setup

### 1. Run Environment Check
```bash
./scripts/check-environment.sh
```

### 2. Test Local Build
```bash
cd quoteofday
mvn clean test
```

### 3. Test Script Execution
```bash
cd quoteofday
./scripts/convert-test-reports.sh target/surefire-reports test-evidence.json
```

## Troubleshooting

### Common Issues

#### 1. Certificate Errors
- **Error**: `unable to get local issuer certificate`
- **Solution**: Set `SSL_CERT_FILE` environment variable

#### 2. Java Not Found
- **Error**: `java: command not found`
- **Solution**: Set `JAVA_HOME` and add to `PATH`

#### 3. Maven Not Found
- **Error**: `mvn: command not found`
- **Solution**: Install Maven and set `MAVEN_HOME`

#### 4. Docker Permission Issues
- **Error**: `permission denied`
- **Solution**: Add user to docker group or run Docker Desktop

#### 5. Network Connectivity
- **Error**: Cannot reach external URLs
- **Solution**: Check firewall settings and proxy configuration

### Debug Commands

```bash
# Check Java installation
java -version
echo $JAVA_HOME

# Check Maven installation
mvn -version
echo $MAVEN_HOME

# Check Docker
docker --version
docker ps

# Check network connectivity
curl -v https://github.com
curl -v https://adoptium.net

# Check SSL certificates
openssl s_client -connect github.com:443 -servername github.com
```

## Security Considerations

1. **Runner Security**: Self-hosted runners run code from your repository
2. **Secrets**: Be careful with repository secrets
3. **Network Access**: Runner needs internet access for downloads
4. **Updates**: Keep the runner and tools updated

## Maintenance

### Regular Tasks
1. Update the runner software
2. Update Java, Maven, and other tools
3. Monitor disk space and performance
4. Check logs for errors

### Monitoring
```bash
# Check runner status
./run.sh status

# Check runner logs
tail -f .runner

# Monitor resource usage
top -pid $(pgrep -f "actions.runner")
```

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review GitHub Actions runner documentation
3. Check the runner logs for detailed error messages
4. Ensure all prerequisites are met
