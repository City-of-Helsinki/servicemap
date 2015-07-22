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
          #console.log "Browse button visible"
          browser.clickElement el, (err) ->
            #console.log "Clicked"
            cb()
          return
        return
      (cb) ->
        browser.waitForElementByXPath serviceTreeItemSelector, asserters.isDisplayed, 2000, 100, (err, el) ->
          #console.log "Element sighted!"
          el.getAttribute 'innerHTML', (err, val) ->
            #console.log "Text", val
            #console.log "Err", err
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


describe 'Test look ahead', ->
  it 'Should find item "Kallion kirjasto"', (done) ->
    wd = @wd
    mochaOptions = @mochaOptions
    browser = @browser
    asserters = wd.asserters

    baseUrl = 'http://localhost:9001'
    searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
    typeaheadResultPath = '//*[@id="search-region"]//span[@class="twitter-typeahead"]//span[@class="tt-suggestions"]//div[text() = "Kallion kirjasto"]'

    #searchResultPath = '#navigation-contents .result-contents ul'
    #searchButton = '#search-region > div > form > span.action-button.search-button > span'

    searchText = 'kallion kirjasto'
    searchResult = 'Kallion kirjasto'

    async.waterfall [
      (cb) ->
        browser.get baseUrl, cb
        return
      (cb) ->
        browser.waitForElementByXPath searchFieldPath, asserters.isDisplayed, 2000, 100, (err, el) ->
          #console.log "Search field visible"
          browser.clickElement el, (err) ->
            #console.log "Search field clicked"
            el.type searchText, (err) ->
              #console.log "Search text in"
              cb()
              return
          return
        return
      (cb) ->
        browser.waitForElementByXPath typeaheadResultPath, asserters.isDisplayed, 2000, 100, (err, el) ->
          #console.log "Element sighted!"
          el.getAttribute 'innerHTML', (err, val) ->
            #console.log "Text", val
            #console.log "Err", err
            try
              assert.equal val, searchResult
              cb()
            catch e
              cb e
            return
        return
    ], done
    return
  return

describe 'Test search', ->
  it 'Should find item "Kallion kirjasto"', (done) ->
    wd = @wd
    mochaOptions = @mochaOptions
    browser = @browser
    asserters = wd.asserters

    baseUrl = 'http://localhost:9001'
    searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
    typeaheadResultPath = '//*[@id="search-region"]//span[@class="twitter-typeahead"]//span[@class="tt-suggestions"]//div[text() = "Kallion kirjasto"]'

    searchResultPath = '//*[@id="navigation-contents"]//li//*[contains(.,"Kallion kirjasto")]'

    #searchResultPath = '#navigation-contents .result-contents ul'
    searchButton = '#search-region > div > form > span.action-button.search-button > span'

    searchText = 'kallion kirjasto'
    searchResult = 'Kallion kirjasto'

    async.waterfall [
      (cb) ->
        browser.get baseUrl, cb
        return
      (cb) ->
        browser.waitForElementByXPath searchFieldPath, asserters.isDisplayed, 2000, 100, (err, el) ->
          #console.log "Search field visible"
          browser.clickElement el, (err) ->
            #console.log "Search field clicked"
            el.type searchText, (err) ->
              #console.log "Search text in"
              cb()
              return
          return
        return
      (cb) ->
        browser.waitForElementByCssSelector searchButton, asserters.isDisplayed, 2000, 100, (err, el) ->
          browser.clickElement el, (err) ->
            #console.log "Search button clicked"
            cb()
      (cb) ->
        browser.waitForElementByXPath searchResultPath, 20000, 100, (err, el) ->
          #console.log "Result element sighted!"
          #console.log "Error: ", err
          #console.log "Element: ", el
          el.getAttribute 'innerHTML', (err, val) ->
            console.log "Text", val
            console.log "Err", err
            try
              assert.ok val
              cb()
            catch e
              cb e
            return
        return
    ], done
    return
  return
