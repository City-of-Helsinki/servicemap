chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
should = chai.should()

Q = require('q')

wd = undefined
browser = undefined
asserters = undefined

baseUrl = 'http://localhost:9001'

describe 'Test navigation widget', ->

  before ->
    wd = @wd
    chaiAsPromised.transferPromiseness = wd.transferPromiseness;
    browser = wd.promiseChainRemote()

  it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
    browser
      .init(browserName: 'chrome')
      .get(baseUrl)
      .title().should.become('Pääkaupunkiseudun palvelukartta')
      .then (title) ->
        #console.log "Title is ", title
        return
      .fin ->
        done()

  it 'Should contain button "Selaa palveluita"', (done)->
    browseButtonSelector = '//*[@id="browse-region"]'
    browser
      .elementByXPath(browseButtonSelector)
      .click()
      .fin ->
        done()

  it 'Should contain list item "Terveys"', (done) ->
    serviceTreeItemSelector = '//*[@id="service-tree-container"]/ul/li//span[text() = "Terveys"]'
    browser
      .waitForElementByXPath(serviceTreeItemSelector, 2000)
      .should.exist.notify(done)

  # Sanity
  it 'Should not contain list item "Sairaus"', (done) =>
    serviceTreeItemSelector = '//*[@id="service-tree-container"]/ul/li//span[text() = "Sairaus"]'
    browser
      .waitForElementByXPath(serviceTreeItemSelector, 2000)
      .should.be.rejected.notify(done)


describe 'Test look ahead', ->

  before ->
    wd = @wd
    chaiAsPromised.transferPromiseness = wd.transferPromiseness;
    browser = wd.promiseChainRemote()
    asserters = wd.asserters

  it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
    browser
      .init(browserName: 'chrome')
      .get(baseUrl)
      .title().should.become('Pääkaupunkiseudun palvelukartta')
      .then (title) ->
        #console.log "Title is ", title
        return
      .fin ->
        done()

  it 'Should find item "Kallion kirjasto"', (done) ->

    searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
    typeaheadResultPath = '//*[@id="search-region"]//span[@class="twitter-typeahead"]//span[@class="tt-suggestions"]//div[text() = "Kallion kirjasto"]'
    searchText = 'kallion kirjasto'

    browser
      .elementByXPath(searchFieldPath)
      .type(searchText)
      .waitForElementByXPath(typeaheadResultPath, 2000)
      .should.exist.notify(done)

describe 'Test search', ->

  before ->
    wd = @wd
    chaiAsPromised.transferPromiseness = wd.transferPromiseness;
    browser = wd.promiseChainRemote()
    asserters = wd.asserters

  it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
    browser
      .init(browserName: 'chrome')
      .get(baseUrl)
      .title().should.become('Pääkaupunkiseudun palvelukartta')
      .then (title) ->
        #console.log "Title is ", title
        return
      .fin ->
        done()

  it 'Should manage to click search text field', (done) ->
    searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
    browser
      .waitForElementByXPath(searchFieldPath, 2000, asserters.isDisplayed)
      .click().should.be.fulfilled.notify(done)

  it 'Should manage to input search text', (done) ->
    searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
    searchText = 'kallion kirjasto'
    browser
      .elementByXPath(searchFieldPath)
      .type(searchText).should.be.fulfilled.notify(done)

  it 'Should manage to click search button', (done) ->
    searchButton = '#search-region > div > form > span.action-button.search-button > span'
    browser
      .waitForElementByCss(searchButton, 2000, asserters.isDisplayed)
      .click().should.be.fulfilled.notify(done)

  it 'Should find item "Kallion kirjasto"', (done) ->
    searchResultPath = '//*[@id="navigation-contents"]//li//*[contains(.,"Kallion kirjasto")]'
    browser
      .waitForElementByXPath(searchResultPath, 2000, asserters.isDisplayed)
      .should.be.fulfilled.notify(done)

  it 'Should not find item "Kallio2n kirjasto"', (done) ->
    searchResultPath = '//*[@id="navigation-contents"]//li//*[contains(.,"Kallio2n kirjasto")]'
    browser
      .waitForElementByXPath(searchResultPath, 2000, asserters.isDisplayed)
      .should.be.rejected.notify(done)
