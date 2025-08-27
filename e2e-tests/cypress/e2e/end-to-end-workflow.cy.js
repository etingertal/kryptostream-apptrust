describe('End-to-End Workflow Tests', () => {
  const quoteServiceUrl = Cypress.env('quoteServiceUrl')
  const translationServiceUrl = Cypress.env('translationServiceUrl')

  beforeEach(() => {
    // Wait for both services to be ready
    cy.waitForService(quoteServiceUrl, '/actuator/health')
    cy.waitForService(translationServiceUrl, '/health')
  })

  it('should get quote and translate it', () => {
    let originalQuote

    // Step 1: Get today's quote
    cy.request('GET', `${quoteServiceUrl}/api/quotes/today`)
      .then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.have.property('text')
        originalQuote = response.body.text
        cy.log(`📝 Original quote: ${originalQuote}`)
      })
      .then(() => {
        // Step 2: Translate the quote
        const payload = {
          text: originalQuote,
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
          expect(response.body.original_text).to.eq(originalQuote)
          expect(response.body.translated_text).to.not.be.null
          expect(response.body.source_lang).to.eq('en')
          expect(response.body.target_lang).to.eq('fr')
          
          cy.log(`🌍 Translated quote: ${response.body.translated_text}`)
        })
      })
  })
})
