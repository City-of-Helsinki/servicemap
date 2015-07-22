assert = require('assert')
async = require('async')

describe 'Test navigation widget', ->
  it 'Should contain top-level category "Terveys"', (done) ->
    wd = @wd
    mochaOptions = @mochaOptions
    browser = @browser
    asserters = wd.asserters
    browseButtonSelector = '//*[@id="browse-region"]'
    serviceTreeItemSelector = '//*[@id="service-tree-container"]/ul/li//span[text() = "Terveys"]'

    async.waterfall [
      (cb) ->
        browser.get 'http://localhost:9001', cb
        return
      (cb) ->
        browser.waitForElementByXPath browseButtonSelector, asserters.isDisplayed, 2000, 100, (err, el) ->
          console.log "Browse button visible"
          browser.clickElement el, (err) ->
            console.log "Clicked"
            cb()
          return
        return
      (cb) ->
        browser.waitForElementByXPath serviceTreeItemSelector, asserters.isDisplayed, 2000, 100, (err, el) ->
          console.log "Element sighted!"
          el.getAttribute 'innerHTML', (err, val) ->
            console.log "Text", val
            console.log "Err", err
            try
              assert.equal val, 'Terveys'
              cb()
            catch e
              cb e
            return
        return
    ], done
    return
  return
