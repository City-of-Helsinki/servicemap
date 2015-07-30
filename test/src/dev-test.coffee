chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
should = chai.should()

Q = require('q')

wd = undefined
browser = undefined
mochaOptions = undefined
asserters = undefined

describe 'Test navigation widget', ->

  before ->
    wd = @wd
    chaiAsPromised.transferPromiseness = wd.transferPromiseness;
    browser = wd.promiseChainRemote()
    mochaOptions = @mochaOptions
    asserters = wd.asserters

  it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
    browser
      .init(browserName: 'chrome')
      .get('http://localhost:9001')
      .title().should.become('Pääkaupunkiseudun palvelukartta')
      .then (title) ->
        console.log "Title is ", title
      .fin ->
        done()

  it 'Should contain button "Selaa palveluita"', (done)->
    browseButtonSelector = '//*[@id="browse-region"]'
    browser
      .elementByXPath(browseButtonSelector)
      .click()
      .fin ->
        done()

  it 'Should contain top-level category "Terveys"', (done) ->
    serviceTreeItemSelector = '//*[@id="service-tree-container"]/ul/li//span[text() = "Terv2eys"]'
    browser
      .waitForElementByXPath(serviceTreeItemSelector, 2000)
      .should.exist.notify(done)
