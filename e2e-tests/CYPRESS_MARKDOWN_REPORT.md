# Cypress to Markdown Report Conversion

This directory contains tools to convert Cypress JSON test reports into human-readable Markdown format.

## 📋 Overview

The conversion tools provide:
- **JSON to Markdown conversion** of Cypress test results
- **Comprehensive test reporting** with detailed statistics
- **Failure analysis** with error details and stack traces
- **CI/CD integration** for automated report generation

## 🛠️ Tools

### 1. Node.js Conversion Script
- **File:** `convert-cypress-to-markdown.js`
- **Purpose:** Core conversion logic from Cypress JSON to Markdown
- **Usage:** `node convert-cypress-to-markdown.js <input-file> [output-file]`

### 2. Shell Script Wrapper
- **File:** `convert-cypress-report.sh`
- **Purpose:** User-friendly wrapper with error handling
- **Usage:** `./convert-cypress-report.sh [input-file] [output-file]`

### 3. NPM Scripts
- **`npm run convert-to-markdown`** - Convert default `cypress-results.json` to `cypress-report.md`
- **`npm run test-and-report`** - Run tests and generate markdown report in one command

## 📊 Report Features

The generated Markdown report includes:

### Test Summary
- Total tests, passed, failed, pending counts
- Test duration and timing information
- Suite count and execution details

### Test Results Overview
- Visual status indicators (✅ ❌ ⏸️)
- Pass/fail ratios
- Overall test status

### Detailed Test Information
- **Passed Tests** - List of successful tests with timing
- **Failed Tests** - Detailed failure information including:
  - Error messages
  - Stack traces
  - Screenshot references
- **Pending Tests** - Tests that were skipped or pending

### Test Details by Suite
- Tests grouped by test suite
- Individual test timing and status
- Error details for failed tests

## 🚀 Usage Examples

### Local Development
```bash
# Run tests and generate markdown report
npm run test-and-report

# Convert existing results file
npm run convert-to-markdown

# Convert specific file
./convert-cypress-report.sh my-results.json my-report.md
```

### CI/CD Integration
The conversion is automatically integrated into the GitHub Actions workflow:
- Runs after E2E tests complete
- Generates `cypress-e2e-report.md`
- Uploads as downloadable artifact
- Available for 30 days

## 📁 File Structure

```
e2e-tests/
├── convert-cypress-to-markdown.js    # Core conversion script
├── convert-cypress-report.sh         # Shell wrapper
├── sample-cypress-results.json       # Sample input data
├── sample-cypress-results.md         # Sample output
└── cypress-results.json              # Default input file
```

## 🔧 Configuration

### Cypress Configuration
Ensure your `cypress.config.js` includes JSON reporter:

```javascript
module.exports = defineConfig({
  e2e: {
    reporter: 'json',
    reporterOptions: {
      outputFile: 'cypress-results.json'
    }
  }
})
```

### Package.json Scripts
```json
{
  "scripts": {
    "convert-to-markdown": "./convert-cypress-report.sh",
    "test-and-report": "npm run test:fast && npm run convert-to-markdown"
  }
}
```

## 📈 Sample Output

The generated markdown includes:

```markdown
# Cypress E2E Test Report

## 📊 Test Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | 9 |
| **Passed** | 8 |
| **Failed** | 1 |
| **Duration** | 300s |

## 📈 Test Results Overview

**Status:** 🔴 Some Tests Failed

- ✅ **8/9** tests passed
- ❌ **1/9** tests failed

## ✅ Passed Tests (8)

✅ **Simple Test** > should pass a simple test (1s)
✅ **Quote Service** > should return a quote (1s)

## ❌ Failed Tests (1)

❌ **Translation Service** > should translate text (1s)

### 🔍 Failure Details

### 1. Translation Service > should translate text

**Error:** `AssertionError: expected 500 to equal 200`

**Stack Trace:**
```
AssertionError: expected 500 to equal 200
    at Context.eval (webpack:///./cypress/e2e/translation-service.cy.js:8:8)
```
```

## 🔍 Troubleshooting

### Common Issues

1. **Input file not found**
   - Ensure Cypress generated the JSON report
   - Check file path and permissions

2. **Invalid JSON format**
   - Verify the JSON file is valid
   - Check for truncated or corrupted files

3. **Permission denied**
   - Make shell script executable: `chmod +x convert-cypress-report.sh`

### Debug Mode
Run with verbose output:
```bash
DEBUG=1 ./convert-cypress-report.sh input.json output.md
```

## 🤝 Contributing

To extend the conversion functionality:

1. **Add new report sections** - Modify `generateMarkdown()` function
2. **Customize formatting** - Update individual generator functions
3. **Add new data fields** - Extend the JSON parsing logic

## 📝 License

This tool is part of the evidence-integration project and follows the same licensing terms.
