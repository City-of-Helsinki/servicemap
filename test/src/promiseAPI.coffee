assert = require('assert')
describe 'Promise-enabled WebDriver', ->
  describe 'injected browser executing a Google Search', ->
    it 'performs as expected', (done) ->
      searchBox = undefined
      browser = @browser
      browser.get('http://google.com').elementByName('q').then((el) ->
        searchBox = el
        searchBox.type 'webdriver'
      ).then(->
        searchBox.getAttribute 'value'
      ).then((val) ->
        assert.equal val, 'webdriver'
      ).then done, done
      return
    return
  return
