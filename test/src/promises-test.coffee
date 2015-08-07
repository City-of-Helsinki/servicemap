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
pageTitle = 'Pääkaupunkiseudun palvelukartta'
serviceTreeItemSelector = '#service-tree-container > ul > li'
browseButtonSelector = '#browse-region'
searchResultPath = '#navigation-contents li'
searchButton =  '#search-region > div > form > span.action-button.search-button > span'
searchFieldPath = '#search-region > div > form > span:nth-of-type(1) > input'
typeaheadResultPath = '#search-region span.twitter-typeahead span.tt-suggestions'

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
        .title().should.become(pageTitle)
        .should.notify(done)

    it 'Should contain button "Selaa palveluita"', (done) ->
      browser
        .waitForElementByCss(browseButtonSelector, delay)
        .click().should.be.fulfilled
        .should.notify(done)

    it 'Should contain list item "Terveys"', (done) ->
      browser
        .waitForElementByCss(serviceTreeItemSelector,
          asserters.textInclude('Terveys'), delay)
        .should.be.fulfilled
        .should.notify(done)

    # Sanity
    it 'Should not contain list item "Sairaus"', (done) ->
      browser
        .waitForElementByCss(serviceTreeItemSelector,
          asserters.textInclude('Sairaus'), errorDelay)
        .should.be.rejected
        .should.notify(done)


  describe 'Test look ahead', ->
    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        .get(baseUrl)
        .title().should.become(pageTitle)
        .should.notify(done)

    it 'Should find item "Kallion kirjasto"', (done) ->
      searchText = 'kallion kirjasto'
      browser
        .waitForElementByCss(searchFieldPath, delay)
        .click()
        .type(searchText)
        .waitForElementByCss(typeaheadResultPath, asserters.textInclude("Kallion kirjasto"), delay)
        .should.be.fulfilled
        .should.notify(done)

  describe 'Test search', ->
    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        .get(baseUrl)
        .title().should.become(pageTitle)
        .should.notify(done)

    it 'Should manage to input search text', (done) ->
      searchText = 'kallion kirjasto'
      browser
        .waitForElementByCss(searchFieldPath, delay)
        .click()
        .type(searchText)
        .should.be.fulfilled
        .should.notify(done)

    it 'Should manage to click search button', (done) ->
      browser
        .waitForElementByCss(searchButton, delay)
        .click().should.be.fulfilled
        .should.notify(done)

    it 'Should find item "Kallion kirjasto"', (done) ->
      browser
        .waitForElementByCss(searchResultPath, asserters.textInclude("Kallion kirjasto"), delay)
        .should.be.fulfilled
        .should.notify(done)

    it 'Should not find item "Kallio2n kirjasto"', (done) ->
      browser
        .waitForElementByCss(searchResultPath, asserters.textInclude("Kallio2n kirjasto"), errorDelay)
        .should.be.rejected
        .should.notify(done)
