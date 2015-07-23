assert = require('assert')
fs = require('fs')
path = require('path')
describe 'Phantomjs browser', ->
  it 'should allow to pass phantomjs capabilities', (done) ->
    searchBox = undefined
    browser = @browser
    browser.get('http://beta.saadtazi.com/api/echo/headers.html').elementsByCssSelector('.grunt-mocha-webdriver-header').then((elts) ->
      assert.equal elts.length, 1
      return
    ).then done, done
    return
  return
