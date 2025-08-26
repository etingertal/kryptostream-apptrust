# Local Run Directory Structure

This directory contains all files related to local end-to-end testing of the Evidence Integration project.

## Directory Structure

```
local-run/
├── docker-compose.local.yml    # Main orchestration file for local testing
├── Dockerfile.e2e              # Dockerfile for the E2E test runner
├── run-e2e-local.sh            # Main E2E test execution script
├── validate-setup.sh           # Setup validation script
├── E2E_TEST_README.md          # Comprehensive documentation
├── STRUCTURE.md                # This file
└── e2e-tests/                  # E2E test files
    ├── requirements.txt        # Python test dependencies
    ├── test_e2e.py            # Main test suite
    ├── run-e2e-tests.sh       # Test orchestration script
    └── wait_for_services.py   # Service readiness checker
```

## File Descriptions

### Core Files

- **`docker-compose.local.yml`**: Defines the services (quote-service, translation-service, e2e-tests) and their configuration for local testing
- **`Dockerfile.e2e`**: Creates the test runner container with Python dependencies and test scripts
- **`run-e2e-local.sh`**: Main script that orchestrates the entire E2E test process

### Test Files

- **`e2e-tests/requirements.txt`**: Python packages needed for testing (requests, pytest, etc.)
- **`e2e-tests/test_e2e.py`**: Comprehensive test suite covering service health, functionality, and end-to-end workflows
- **`e2e-tests/run-e2e-tests.sh`**: Script that runs within the test container to execute tests
- **`e2e-tests/wait_for_services.py`**: Python script that waits for both services to be healthy before running tests

### Documentation & Validation

- **`E2E_TEST_README.md`**: Complete documentation with usage instructions, troubleshooting, and development guidelines
- **`validate-setup.sh`**: Script to validate that all required files and dependencies are in place
- **`STRUCTURE.md`**: This file explaining the directory organization

## Usage

### From Project Root
```bash
./run-e2e.sh
```

### From This Directory
```bash
./run-e2e-local.sh
```

### Manual Execution
```bash
docker-compose -f docker-compose.local.yml up --build
```

### Validation
```bash
./validate-setup.sh
```

## Service Dependencies

The setup references the following parent directories:
- `../quoteofday/` - Java Spring Boot quote service
- `../translate/` - Python FastAPI translation service

These directories contain the actual service code and Dockerfiles that are built and tested.
