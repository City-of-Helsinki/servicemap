#assert = require('assert')
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
      browser = wd.promiseRemote()

    it 'performs as expected', (done) ->

      #console.log "WD: ", wd
      #console.log "Browser: ", browser
      #console.log "Mocha opts: ", mochaOptions
      browser.init(browserName: 'chrome').then(->
        console.log "Go to test URL"
        browser.get 'http://admc.io/wd/test-pages/guinea-pig.html'
      ).then(->
        console.log "Get page title"
        browser.title()
      ).then((title) ->
        console.log "Page title is: ", title
        title.should.equal 'WD Tests'
        browser.elementById 'i am a link'
      ).then((el) ->
        console.log "Clicking element"
        browser.clickElement el
      ).then(->
        console.log "Check URL"
        ### jshint evil: true ###

        browser.eval 'window.location.href'
      ).then((href) ->
        console.log "Validate URL", href
        href.should.include 'guinea-pig2'
        return
      ).fin(->
        console.log "Closing browser"
        browser.quit()
        done()
      )
