# End-to-End Test Setup

This directory contains a complete end-to-end test setup for the Evidence Integration project, which includes:

- **Quote of Day Service** (Java/Spring Boot) - Provides random quotes
- **Translation Service** (Python/FastAPI) - Translates text using Hugging Face models
- **E2E Test Runner** - Tests the integration between both services

## Prerequisites

1. **Podman** installed and running on your system
2. **Docker Compose** or **Podman Compose** installed
3. **HF_TOKEN** environment variable set (optional, for Hugging Face model access)

## Quick Start

### Option 1: Using the automated script (Recommended)

```bash
# Make sure you're in the project root directory
cd /path/to/evidence-integration

# Run the E2E tests
./local-run/run-e2e-local.sh
```

### Option 2: Manual execution

```bash
# 1. Build and start the services
podman-compose -f local-run/docker-compose.local.yml up --build -d

# 2. Wait for services to be ready (check logs if needed)
podman-compose -f local-run/docker-compose.local.yml logs -f

# 3. Run the E2E tests
podman-compose -f local-run/docker-compose.local.yml --profile e2e-test up --build e2e-tests

# 4. Clean up
podman-compose -f local-run/docker-compose.local.yml down -v
```

## Service Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Quote Service │    │ Translation      │    │   E2E Test      │
│   (Port 8080)   │    │ Service          │    │   Runner        │
│                 │    │ (Port 8000)      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Docker        │
                    │   Network       │
                    │   (e2e-network) │
                    └─────────────────┘
```

## Test Coverage

The E2E tests cover:

1. **Service Health Checks**
   - Quote service actuator health endpoint
   - Translation service health endpoint

2. **Individual Service Functionality**
   - Quote service random quote endpoint
   - Translation service single and batch translation endpoints

3. **End-to-End Workflow**
   - Get a random quote from the quote service
   - Translate the quote using the translation service
   - Verify the complete workflow

4. **Error Handling**
   - Invalid requests
   - Service unavailability scenarios

## Configuration

### Environment Variables

- `HF_TOKEN`: Hugging Face API token for model access
- `QUOTE_SERVICE_URL`: Quote service URL (default: http://quote-service:8080)
- `TRANSLATION_SERVICE_URL`: Translation service URL (default: http://translation-service:8000)
- `TEST_TIMEOUT`: Test timeout in seconds (default: 300)

### Service Ports

- **Quote Service**: 8080
- **Translation Service**: 8000

## Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   # Check service logs
   podman-compose -f local-run/docker-compose.local.yml logs quote-service
   podman-compose -f local-run/docker-compose.local.yml logs translation-service
   ```

2. **Health checks failing**
   ```bash
   # Check if services are accessible
   curl http://localhost:8080/actuator/health
   curl http://localhost:8000/health
   ```

3. **Model download issues**
   - Ensure `HF_TOKEN` is set if using private models
   - Check network connectivity to Hugging Face

4. **Port conflicts**
   - Ensure ports 8080 and 8000 are available
   - Modify the local-run/docker-compose.local.yml file to use different ports

### Debug Mode

To run with more verbose output:

```bash
# Enable debug logging
export DEBUG=1
./run-e2e-local.sh
```

## Development

### Adding New Tests

1. Edit `e2e-tests/test_e2e.py` to add new test methods
2. Follow the existing test structure using pytest
3. Use the `self.quote_url` and `self.translation_url` properties

### Modifying Services

1. **Quote Service**: Edit files in `quoteofday/` directory
2. **Translation Service**: Edit files in `translate/` directory
3. Rebuild containers: `podman-compose -f local-run/docker-compose.local.yml build`

### Custom Test Scenarios

Create custom test scenarios by:

1. Adding new test methods to `TestEndToEnd` class
2. Using the existing service URLs and request patterns
3. Following the established assertion patterns

## Cleanup

To completely clean up the test environment:

```bash
# Stop and remove containers
podman-compose -f local-run/docker-compose.local.yml down -v

# Remove images (optional)
podman rmi evidence-integration-e2e-quote-service
podman rmi evidence-integration-e2e-translation-service
podman rmi evidence-integration-e2e-e2e-tests

# Remove volumes (optional)
podman volume rm evidence-integration-e2e_model-cache
```
