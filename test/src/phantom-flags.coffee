assert = require('assert')
fs = require('fs')
path = require('path')
describe 'Phantomjs browser', ->
  after ->
    fs.unlinkSync 'phantom.log'
    return
  it 'should allow to pass phantomjs start flags', (done) ->
    searchBox = undefined
    browser = @browser
    browser.get('http://www.google.com').then(->
      assert.ok fs.statSync('phantom.log').isFile()
      return
    ).nodeify done
    return
  return
