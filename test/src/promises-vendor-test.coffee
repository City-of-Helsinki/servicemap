chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
chai.should()

wd = undefined
browser = undefined
mochaOptions = undefined

describe 'Promise-enabled WebDriver', ->
  describe 'injected browser executing a Google Search', ->
    before ->
      wd = @wd
      chaiAsPromised.transferPromiseness = wd.transferPromiseness;
      browser = wd.promiseChainRemote()

    it 'performs as expected', (done) ->

      #console.log "WD: ", wd
      #console.log "Browser: ", browser
      #console.log "Mocha opts: ", mochaOptions
      browser
        .init(browserName: 'chrome')
        .get('http://admc.io/wd/test-pages/guinea-pig.html')
        .title().should.become('WD Tests')
        .elementById('i am a link')
        .click()
        .eval('window.location.href')
        .should.eventually.include('guinea-pig2')
        .back()
        .elementByCss('#comments')
        .type('Bonjour!')
        .getValue()
        .should.become('Bonjour!')
        .fin(->
          browser.quit()
          done()
        ).done()
