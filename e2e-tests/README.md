# E2E Tests

This folder contains all E2E (End-to-End) testing configuration, scripts, and documentation.

## Files

### Core Test Files
- `test_e2e.py` - Main E2E test suite
- `run-ci-tests.py` - CI test runner script
- `wait_for_services.py` - Service health check utility
- `requirements.txt` - Python dependencies
- `run-e2e-tests.sh` - Test execution script

### Docker Configuration
- `docker-compose.yml.template` - Template for E2E test Docker Compose configuration
- `docker-compose.local.yml` - Local development Docker Compose file
- `Dockerfile.e2e` - Docker image for E2E tests

### Scripts
- `run-e2e.sh` - Main E2E test runner
- `run-e2e-local.sh` - Local E2E test runner
- `validate-setup.sh` - Environment validation script

### Documentation
- `README.md` - This documentation file
- `E2E_TEST_README.md` - Detailed E2E testing guide
- `E2E_CI_INTEGRATION.md` - CI integration documentation
- `STRUCTURE.md` - Project structure documentation

## Docker Compose Template

The `docker-compose.yml.template` file is a template that gets processed by the GitHub Actions workflow to substitute variables:

- `${QUOTE_IMAGE_TAG}` - The version tag for the quote-of-day-service image
- `${TRANSLATION_IMAGE_TAG}` - The version tag for the ai-translate image

## Services

The Docker Compose configuration includes three services:

1. **quote-service** - The Java Spring Boot quote service
2. **translation-service** - The AI translation service
3. **e2e-tests** - The Python test runner that executes the E2E tests

## Usage

The template is processed by the GitHub Actions workflow using `envsubst` to substitute the environment variables with actual values before running the tests.

## Health Checks

Both services include health checks to ensure they are ready before the E2E tests start running.
