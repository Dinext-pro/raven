describe('Raven selected-release regression', () => {
  let fixture
  before(() => {
    const password = Cypress.env('adminPassword')
    expect(password, 'isolated site admin password').to.be.a('string').and.not.be.empty
    cy.loginUpgrade('Administrator', password)
    cy.callUpgrade('raven.tests.dinext_upgrade.prepare').then((response) => {
      fixture = response.body.message
    })
  })

  after(() => {
    cy.leaveUpgradeApp()
    cy.loginUpgrade('Administrator', Cypress.env('adminPassword'))
    cy.callUpgrade('raven.tests.dinext_upgrade.cleanup')
  })

  it('loads the Russian Raven interface', () => {
    cy.loginUpgrade(fixture.user, fixture.password)
    cy.visit('/raven')
    cy.get('#root').should('be.visible')
    cy.contains('#root', 'Главная').should('be.visible')
    cy.get('html').should('have.attr', 'lang', 'ru')
  })

  it('opens a linked document channel in Desk and sends a message', () => {
    const subject = 'Raven upgrade document ' + Date.now()
    const text = 'Message from the upgraded Desk widget'
    cy.loginUpgrade('Administrator', Cypress.env('adminPassword'))
    cy.callUpgrade('frappe.client.set_value', {
      doctype: 'Raven Settings', name: 'Raven Settings', fieldname: 'show_raven_on_desk', value: 1,
    })
    cy.loginUpgrade(fixture.user, fixture.password)
    cy.callUpgrade('frappe.client.insert', { doc: { doctype: 'Task', subject } }).then(({ body }) => {
      const task = body.message.name
      cy.callUpgrade('dinext_raven.document_channels.api.create_document_channel', {
        doctype: 'Task', name: task, channel_name: subject, channel_type: 'Private',
      }).then(({ body }) => {
        const channel = body.message
        cy.visit('/app/task/' + encodeURIComponent(task))
        cy.get('.dinext-raven-open-channel').should('be.visible').click()
        cy.get('.raven-channel-header-name').should('contain', channel.channel_name)
        cy.get('.raven-chat-input textarea').type(text + '{enter}')
        cy.contains('.raven-chat-view-container', text).should('be.visible')
        cy.callUpgrade('raven.api.raven_message.get_messages_with_dates', { channel_id: channel.name })
          .its('body.message')
          .should((blocks) => {
            expect(blocks.some((block) => block.block_type === 'message' && block.data.text.includes(text))).to.eq(true)
          })
      })
    })
  })
})
