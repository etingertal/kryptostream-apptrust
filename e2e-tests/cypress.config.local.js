const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:8001',
    supportFile: 'cypress/support/e2e.js',
    specPattern: 'cypress/e2e/**/*.cy.js',
    video: false,
    screenshotOnRunFailure: false,
    reporter: 'json',
    reporterOptions: {
      outputFile: 'cypress-results.json'
    },
    env: {
      quoteServiceUrl: 'http://localhost:8001',
      translationServiceUrl: 'http://localhost:8002'
    },
    // Performance optimizations
    defaultCommandTimeout: 10000,
    requestTimeout: 10000,
    responseTimeout: 10000,
    pageLoadTimeout: 30000,
    // Disable unnecessary features for faster execution
    chromeWebSecurity: false,
    experimentalModifyObstructiveThirdPartyCode: false
  }
})
