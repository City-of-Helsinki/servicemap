Q = require('q')
chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
should = chai.should()

wd = undefined
browser = undefined
asserters = undefined

delay = 4000
errorDelay = 1000

baseUrl = 'http://localhost:9001'

describe 'Browser test', ->
  before ->
    wd = @wd
    chaiAsPromised.transferPromiseness = wd.transferPromiseness
    browser = @browser
    asserters = wd.asserters

  describe 'Test navigation widget', ->

    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        .get(baseUrl)
        .title().should.become('Pääkaupunkiseudun palvelukartta')
        .should.notify(done)

    it 'Should contain button "Selaa palveluita"', (done) ->
      browseButtonSelector = '//*[@id="browse-region"]'
      browser
        .waitForElementByXPath(browseButtonSelector, delay)
        .click().should.be.fulfilled
        .should.notify(done)


    it 'Should contain list item "Terveys"', (done) ->
      serviceTreeItemSelector = '//*[@id="service-tree-container"]/ul/li//' +
                                'span[text() = "Terveys"]'
      browser
        .waitForElementByXPath(serviceTreeItemSelector, delay,
          asserters.isDisplayed)
        .should.be.fulfilled
        .should.notify(done)

    # Sanity
    it 'Should not contain list item "Sairaus"', (done) ->
      serviceTreeItemSelector = '//*[@id="service-tree-container"]/ul/li//' +
                                'span[text() = "Sairaus"]'
      browser
        .waitForElementByXPath(serviceTreeItemSelector, errorDelay,
          asserters.isDisplayed)
        .should.be.rejected
        .should.notify(done)


  describe 'Test look ahead', ->

    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        #.init(browserName: 'chrome')
        .get(baseUrl)
        .title().should.become('Pääkaupunkiseudun palvelukartta')
        .should.notify(done)

    it 'Should find item "Kallion kirjasto"', (done) ->

      searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
      typeaheadResultPath = '//*[@id="search-region"]//span[@class="twitter-' +
                            'typeahead"]//span[@class="tt-suggestions"]' +
                            '//div[text() = "Kallion kirjasto"]'
      searchText = 'kallion kirjasto'

      browser
        .waitForElementByXPath(searchFieldPath, delay)
        .type(searchText)
        .waitForElementByXPath(typeaheadResultPath, delay)
        .should.be.fulfilled
        .should.notify(done)

  describe 'Test search', ->

    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        #.init(browserName: 'chrome')
        .get(baseUrl)
        .title().should.become('Pääkaupunkiseudun palvelukartta')
        .should.notify(done)

    it 'Should manage to click search text field', (done) ->
      searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
      browser
        .waitForElementByXPath(searchFieldPath, delay, asserters.isDisplayed)
        .click().should.be.fulfilled
        .should.notify(done)

    it 'Should manage to input search text', (done) ->
      searchFieldPath = '//*[@id="search-region"]/div/form/span[1]/input'
      searchText = 'kallion kirjasto'
      browser
        .elementByXPath(searchFieldPath)
        .type(searchText).should.be.fulfilled
        .should.notify(done)

    it 'Should manage to click search button', (done) ->
      searchButton =  '#search-region > div > form > span.action-button.' +
                      'search-button > span'
      browser
        .waitForElementByCss(searchButton, delay, asserters.isDisplayed)
        .click().should.be.fulfilled
        .should.notify(done)

    it 'Should find item "Kallion kirjasto"', (done) ->
      searchResultPath =  '//*[@id="navigation-contents"]//li//' +
                          '*[contains(.,"Kallion kirjasto")]'
      browser
        .waitForElementByXPath(searchResultPath, delay, asserters.isDisplayed)
        .should.be.fulfilled
        .should.notify(done)

    it 'Should not find item "Kallio2n kirjasto"', (done) ->
      searchResultPath =  '//*[@id="navigation-contents"]//li//*[contains' +
                          '(.,"Kallio2n kirjasto")]'
      browser
        .waitForElementByXPath(searchResultPath, errorDelay,
          asserters.isDisplayed)
        .should.be.rejected
        .should.notify(done)
