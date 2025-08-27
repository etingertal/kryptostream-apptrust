describe('Translation Service E2E Tests', () => {
  const translationServiceUrl = Cypress.env('translationServiceUrl')

  beforeEach(() => {
    // Wait for translation service to be ready
    cy.waitForService(translationServiceUrl, '/health')
  })

  it('should have healthy translation service', () => {
    cy.request('GET', `${translationServiceUrl}/health`)
      .then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body.status).to.eq('healthy')
        expect(response.body.model_loaded).to.be.true
      })
  })

  it('should return root endpoint', () => {
    cy.request('GET', `${translationServiceUrl}/`)
      .then((response) => {
        expect(response.status).to.eq(200)
      })
  })

  it('should translate text from English to French', () => {
    const testText = 'Hello, world!'
    const payload = {
      text: testText,
      source_lang: 'en',
      target_lang: 'fr'
    }

    cy.request({
      method: 'POST',
      url: `${translationServiceUrl}/translate`,
      body: payload,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.eq(200)
      expect(response.body.original_text).to.eq(testText)
      expect(response.body.translated_text).to.not.be.null
      expect(response.body.source_lang).to.eq('en')
      expect(response.body.target_lang).to.eq('fr')
    })
  })
})
