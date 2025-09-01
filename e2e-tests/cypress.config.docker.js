const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://quote-service:8080',
    supportFile: 'cypress/support/e2e.js',
    specPattern: 'cypress/e2e/**/*.cy.js',
    video: false,
    screenshotOnRunFailure: false,
    reporter: 'mocha-multi-reporters',
    reporterOptions: {
      configFile: 'reporter-config.json'
    },
    env: {
      quoteServiceUrl: 'http://quote-service:8080',
      translationServiceUrl: 'http://translation-service:8000'
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
