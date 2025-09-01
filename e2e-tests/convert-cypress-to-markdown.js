#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Convert Cypress JSON report to Markdown format
 * @param {string} inputFile - Path to the Cypress JSON report
 * @param {string} outputFile - Path to the output Markdown file
 */
function convertCypressToMarkdown(inputFile, outputFile) {
  try {
    // Read and parse the JSON file
    const jsonData = JSON.parse(fs.readFileSync(inputFile, 'utf8'));
    
    // Generate markdown content
    const markdown = generateMarkdown(jsonData);
    
    // Write to output file
    fs.writeFileSync(outputFile, markdown);
    
    console.log(`✅ Successfully converted ${inputFile} to ${outputFile}`);
    return true;
  } catch (error) {
    console.error(`❌ Error converting Cypress report: ${error.message}`);
    return false;
  }
}

/**
 * Generate Markdown content from Cypress JSON data
 * @param {Object} data - Parsed Cypress JSON data
 * @returns {string} Markdown content
 */
function generateMarkdown(data) {
  // Handle both Cypress and Mochawesome formats
  const { stats } = data;
  
  // Extract test data based on format
  let tests, passes, failures, pending;
  
  if (data.results) {
    // Mochawesome format
    tests = [];
    passes = [];
    failures = [];
    pending = [];
    
    // Create a map of suite UUIDs to suite names
    const suiteMap = new Map();
    data.results.forEach(result => {
      if (result.suites) {
        result.suites.forEach(suite => {
          suiteMap.set(suite.uuid, suite.title);
        });
      }
    });
    
    // Extract tests from mochawesome results structure
    data.results.forEach(result => {
      if (result.suites) {
        result.suites.forEach(suite => {
          if (suite.tests) {
            suite.tests.forEach(test => {
              // Add suite name to test object for easier processing
              test.suiteName = suite.title;
              tests.push(test);
              if (test.state === 'passed') {
                passes.push(test);
              } else if (test.state === 'failed') {
                failures.push(test);
              } else if (test.pending) {
                pending.push(test);
              }
            });
          }
        });
      }
    });
  } else {
    // Original Cypress format
    tests = data.tests || [];
    passes = data.passes || [];
    failures = data.failures || [];
    pending = data.pending || [];
  }
  
  // Calculate duration in seconds
  const duration = Math.round(stats.duration / 1000);
  
  // Format timestamps
  const startTime = new Date(stats.start).toLocaleString();
  const endTime = new Date(stats.end).toLocaleString();
  
  let markdown = `# Cypress E2E Test Report

## 📊 Test Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | ${stats.tests} |
| **Passed** | ${stats.passes} |
| **Failed** | ${stats.failures} |
| **Pending** | ${stats.pending} |
| **Suites** | ${stats.suites} |
| **Duration** | ${duration}s |
| **Start Time** | ${startTime} |
| **End Time** | ${endTime} |

## 📈 Test Results Overview

${generateStatusBadge(stats)}

## ✅ Passed Tests (${passes.length})

${passes.length > 0 ? generateTestList(passes, 'passed') : '*No tests passed*'}

`;

  if (failures.length > 0) {
    markdown += `## ❌ Failed Tests (${failures.length})

${generateTestList(failures, 'failed')}

### 🔍 Failure Details

${generateFailureDetails(failures)}

`;
  }

  if (pending.length > 0) {
    markdown += `## ⏸️ Pending Tests (${pending.length})

${generateTestList(pending, 'pending')}

`;
  }

  markdown += `## 📋 Test Details

${generateDetailedTestList(tests)}

---

*Report generated on ${new Date().toLocaleString()}*
`;

  return markdown;
}

/**
 * Generate status badge
 * @param {Object} stats - Test statistics
 * @returns {string} Status badge markdown
 */
function generateStatusBadge(stats) {
  const total = stats.tests;
  const passed = stats.passes;
  const failed = stats.failures;
  const pending = stats.pending;
  
  let status = '🟢 All Tests Passed';
  if (failed > 0) {
    status = '🔴 Some Tests Failed';
  } else if (pending > 0) {
    status = '🟡 Some Tests Pending';
  }
  
  return `**Status:** ${status}

- ✅ **${passed}/${total}** tests passed
- ❌ **${failed}/${total}** tests failed
- ⏸️ **${pending}/${total}** tests pending
`;
}

/**
 * Generate test list for a specific status
 * @param {Array} tests - Array of test objects
 * @param {string} status - Test status (passed, failed, pending)
 * @returns {string} Markdown list
 */
function generateTestList(tests, status) {
  if (tests.length === 0) return '*No tests found*';
  
  return tests.map(test => {
    let suiteName, testName, duration;
    
    // Handle different formats
    if (test.fullTitle) {
      // Mochawesome format - extract suite name from fullTitle
      const fullTitleParts = test.fullTitle.split(' ');
      const lastWord = fullTitleParts[fullTitleParts.length - 1];
      // Find the suite name by removing the test name from the full title
      const testTitleWords = test.title.split(' ');
      let suiteName = test.fullTitle;
      for (const word of testTitleWords) {
        suiteName = suiteName.replace(word, '').trim();
      }
      testName = test.title;
      duration = test.duration ? Math.round(test.duration / 1000) : 0;
    } else if (test.title && Array.isArray(test.title)) {
      // Original Cypress format
      suiteName = test.title[0];
      testName = test.title[1];
      duration = Math.round(test.wallClockDuration / 1000);
    } else {
      // Fallback
      suiteName = 'Unknown Suite';
      testName = test.title || 'Unknown Test';
      duration = test.duration ? Math.round(test.duration / 1000) : 0;
    }
    
    let icon = '✅';
    if (status === 'failed') icon = '❌';
    if (status === 'pending') icon = '⏸️';
    
    return `${icon} **${suiteName}** > ${testName} (${duration}s)`;
  }).join('\n');
}

/**
 * Generate detailed failure information
 * @param {Array} failures - Array of failed test objects
 * @returns {string} Markdown failure details
 */
function generateFailureDetails(failures) {
  return failures.map((test, index) => {
    let suiteName, testName;
    
    // Handle different formats
    if (test.fullTitle) {
      // Mochawesome format
      const fullTitleParts = test.fullTitle.split(' ');
      suiteName = fullTitleParts.slice(0, -1).join(' ');
      testName = test.title;
    } else if (test.title && Array.isArray(test.title)) {
      // Original Cypress format
      suiteName = test.title[0];
      testName = test.title[1];
    } else {
      // Fallback
      suiteName = 'Unknown Suite';
      testName = test.title || 'Unknown Test';
    }
    
    const error = test.err?.message || test.error || 'Unknown error';
    const stack = test.err?.stack || test.stack || 'No stack trace available';
    
    let details = `### ${index + 1}. ${suiteName} > ${testName}

**Error:** \`${error}\`

**Stack Trace:**
\`\`\`
${stack}
\`\`\`
`;

    if (test.screenshots && test.screenshots.length > 0) {
      details += `**Screenshots:**\n`;
      test.screenshots.forEach(screenshot => {
        details += `- ${screenshot.name}\n`;
      });
      details += '\n';
    }
    
    return details;
  }).join('\n');
}

/**
 * Generate detailed test list with all information
 * @param {Array} tests - Array of all test objects
 * @returns {string} Markdown detailed test list
 */
function generateDetailedTestList(tests) {
  if (tests.length === 0) return '*No tests found*';
  
  // Group tests by suite
  const suites = {};
  tests.forEach(test => {
    let suiteName;
    
    // Handle different formats
    if (test.fullTitle) {
      // Mochawesome format
      const fullTitleParts = test.fullTitle.split(' ');
      suiteName = fullTitleParts.slice(0, -1).join(' ');
    } else if (test.title && Array.isArray(test.title)) {
      // Original Cypress format
      suiteName = test.title[0];
    } else {
      // Fallback
      suiteName = 'Unknown Suite';
    }
    
    if (!suites[suiteName]) {
      suites[suiteName] = [];
    }
    suites[suiteName].push(test);
  });
  
  let details = '';
  
  Object.keys(suites).forEach(suiteName => {
    details += `### 📁 ${suiteName}\n\n`;
    
    suites[suiteName].forEach(test => {
      let testName, duration, startTime;
      
      // Handle different formats
      if (test.fullTitle) {
        // Mochawesome format
        testName = test.title;
        duration = Math.round(test.duration / 1000);
        startTime = 'N/A'; // Mochawesome doesn't provide start time
      } else if (test.title && Array.isArray(test.title)) {
        // Original Cypress format
        testName = test.title[1];
        duration = Math.round(test.wallClockDuration / 1000);
        startTime = new Date(test.wallClockStartedAt).toLocaleTimeString();
      } else {
        // Fallback
        testName = test.title || 'Unknown Test';
        duration = test.duration ? Math.round(test.duration / 1000) : 0;
        startTime = 'N/A';
      }
      
      let statusIcon = '✅';
      let statusText = 'PASSED';
      if (test.state === 'failed') {
        statusIcon = '❌';
        statusText = 'FAILED';
      } else if (test.state === 'pending') {
        statusIcon = '⏸️';
        statusText = 'PENDING';
      }
      
      details += `#### ${statusIcon} ${testName}

- **Status:** ${statusText}
- **Duration:** ${duration}s
- **Start Time:** ${startTime}
`;

      if (test.error) {
        details += `- **Error:** \`${test.error}\`\n`;
      }
      
      if (test.screenshots && test.screenshots.length > 0) {
        details += `- **Screenshots:** ${test.screenshots.length}\n`;
      }
      
      details += '\n';
    });
  });
  
  return details;
}

// Main execution
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.log('Usage: node convert-cypress-to-markdown.js <input-file> [output-file]');
    console.log('');
    console.log('Arguments:');
    console.log('  input-file   Path to Cypress JSON report file');
    console.log('  output-file  Path to output Markdown file (optional, defaults to input-file.md)');
    process.exit(1);
  }
  
  const inputFile = args[0];
  const outputFile = args[1] || inputFile.replace(/\.json$/, '.md');
  
  if (!fs.existsSync(inputFile)) {
    console.error(`❌ Input file not found: ${inputFile}`);
    process.exit(1);
  }
  
  const success = convertCypressToMarkdown(inputFile, outputFile);
  process.exit(success ? 0 : 1);
}

module.exports = { convertCypressToMarkdown, generateMarkdown };
