# JFrog Artifactory Integration Testing

This document describes how to test the integration with JFrog Artifactory for both local development and CI/CD pipelines.

## Overview

The integration testing suite includes:

1. **GitHub Actions Workflow**: Automated testing in CI/CD pipeline
2. **Local Test Script**: Manual testing on your local machine
3. **Configuration Validation**: Verification of setup and environment

## Prerequisites

### Environment Variables

Ensure the following environment variables are set:

```bash
export JF_URL="https://evidencetrial.jfrog.io"
export JF_USER="noam"
export JF_ACCESS_TOKEN="your-access-token"
export DOCKER_REGISTRY="evidencetrial.jfrog.io"
```

### Required Tools

- JFrog CLI (`jf`)
- Docker
- Maven
- Python 3 (for YAML validation)

## Testing Methods

### 1. GitHub Actions Workflow

The automated workflow runs when:
- Changes are pushed to main/master/develop branches
- Changes are made to JFrog configuration files
- Manually triggered via workflow dispatch

#### Workflow Jobs

1. **Test JFrog Authentication**
   - Verifies JFrog CLI setup
   - Tests connection to Artifactory

2. **Test Maven Integration**
   - Validates Maven repository access
   - Tests Maven build with JFrog integration
   - Tests Maven deploy (may fail due to permissions)

3. **Test Docker Integration**
   - Tests Docker registry login
   - Tests Docker build and push

4. **Test JFrog API Access**
   - Validates API connectivity
   - Tests repository listing

5. **Test Configuration Validation**
   - Validates environment variables
   - Checks configuration file syntax

6. **Generate Integration Report**
   - Creates a comprehensive test report
   - Uploads results as artifacts

#### Running the Workflow

1. **Automatic**: Push changes to trigger the workflow
2. **Manual**: Go to Actions → JFrog Artifactory Integration Test → Run workflow

### 2. Local Test Script

Run the local test script to verify integration on your machine:

```bash
# Make sure environment variables are set
source .env

# Run the test script
./scripts/test-jfrog-integration.sh
```

#### Test Script Features

- **Colored Output**: Easy-to-read status messages
- **Comprehensive Testing**: Covers all integration points
- **Error Handling**: Graceful failure with detailed error messages
- **Summary Report**: Final status with pass/fail counts

#### Test Categories

1. **JFrog CLI Installation**: Verifies CLI is available
2. **Environment Variables**: Checks all required variables
3. **Authentication**: Tests JFrog CLI configuration and connection
4. **Configuration Validation**: Validates YAML files
5. **API Access**: Tests REST API connectivity
6. **Repository Access**: Tests Maven repository access
7. **Maven Integration**: Tests Maven build with JFrog
8. **Docker Integration**: Tests Docker registry access

## Configuration Files

### JFrog Maven Configuration

File: `quoteofday/.jfrog/projects/maven.yaml`

```yaml
version: 1
type: maven
resolver:
    serverId: setup-jfrog-cli-server
    snapshotRepo: commons-dev-maven-virtual
    releaseRepo: commons-dev-maven-virtual
deployer:
    serverId: setup-jfrog-cli-server
    snapshotRepo: commons-dev-maven-virtual
    releaseRepo: commons-dev-maven-virtual
useWrapper: true
```

### Environment Variables

Required variables in GitHub repository settings:

- `JF_URL`: JFrog Artifactory URL
- `JF_USER`: JFrog username
- `JF_ACCESS_TOKEN`: JFrog access token (secret)
- `DOCKER_REGISTRY`: Docker registry URL

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify access token is valid
   - Check user permissions in JFrog
   - Ensure URL is correct

2. **Repository Access Issues**
   - Verify repository exists
   - Check user permissions for the repository
   - Validate repository configuration

3. **Docker Login Failures**
   - Verify Docker registry URL
   - Check Docker registry permissions
   - Ensure access token has Docker registry access

4. **Maven Build Failures**
   - Check Maven configuration
   - Verify repository settings
   - Ensure dependencies are available

### Debug Steps

1. **Check Environment Variables**
   ```bash
   echo "JF_URL: $JF_URL"
   echo "JF_USER: $JF_USER"
   echo "DOCKER_REGISTRY: $DOCKER_REGISTRY"
   ```

2. **Test JFrog CLI Connection**
   ```bash
   jf rt ping
   ```

3. **Test API Access**
   ```bash
   jf rt curl -XGET "/api/repositories"
   ```

4. **Test Docker Login**
   ```bash
   echo "$JF_ACCESS_TOKEN" | docker login -u "$JF_USER" --password-stdin "$DOCKER_REGISTRY"
   ```

## Test Results

### Success Indicators

- All tests pass with green status
- No authentication errors
- Successful API calls
- Docker login successful
- Maven build completes

### Failure Indicators

- Red error messages
- Authentication failures
- Connection timeouts
- Permission denied errors
- Configuration validation failures

## Continuous Monitoring

The integration tests are designed to run:

- **On every push**: Automatic validation
- **Before deployments**: Manual verification
- **After configuration changes**: Immediate feedback

## Security Considerations

- Access tokens are stored as GitHub secrets
- Local testing uses environment variables
- No sensitive data is logged in test outputs
- Authentication failures are handled gracefully

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the test logs for specific error messages
3. Verify your JFrog Artifactory configuration
4. Contact your JFrog administrator for permission issues
