assert = require('assert')
async = require('async')
describe 'A Mocha test run by grunt-mocha-webdriver', ->
  it 'has a browser injected into it', ->
    assert.ok @browser
    return
  it 'has wd injected into it for customizing', ->
    assert.equal @wd, require('wd')
    return
  it 'has mochaOptions injected into it for reuse', ->
    assert.equal @mochaOptions.timeout, 1000 * 60 * 3
    return
  return
describe 'A basic Webdriver example', ->
  describe 'injected browser executing a Google Search', ->
    it 'performs as expected', (done) ->
      searchBox = undefined
      browser = @browser
      async.waterfall [
        (cb) ->
          browser.get 'http://google.com', cb
          return
        (cb) ->
          browser.elementByName 'q', cb
          return
        (el, cb) ->
          searchBox = el
          searchBox.type 'webdriver', cb
          return
        (cb) ->
          searchBox.getAttribute 'value', cb
          return
        (val, cb) ->
          try
            assert.equal val, 'webdriver'
            cb()
          catch e
            cb e
          return
      ], done
      return
    return
  return
