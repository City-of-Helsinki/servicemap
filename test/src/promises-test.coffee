Q = require('q')
chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
should = chai.should()

wd = undefined
browser = undefined
asserters = undefined

delay = 20000
errorDelay = 1000
pollFreq = 100

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
        .waitForElementByCss(browseButtonSelector, delay, pollFreq)
        .click().should.be.fulfilled
        .should.notify(done)

    it 'Should contain list item "Terveys"', (done) ->
      browser
        .waitForElementByCss(serviceTreeItemSelector,
          asserters.textInclude('Terveys'), delay, pollFreq)
        .should.be.fulfilled
        .should.notify(done)

    # Sanity
    it 'Should not contain list item "Sairaus"', (done) ->
      browser
        .waitForElementByCss(serviceTreeItemSelector,
          asserters.textInclude('Sairaus'), errorDelay, pollFreq)
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
        .waitForElementByCss(searchFieldPath, delay, pollFreq)
        .click()
        .type(searchText)
        .waitForElementByCss(typeaheadResultPath, asserters.textInclude("Kallion kirjasto"), delay, pollFreq)
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
        .waitForElementByCss(searchFieldPath, delay, pollFreq)
        .click()
        .type(searchText)
        .should.be.fulfilled
        .should.notify(done)

    it 'Should manage to click search button', (done) ->
      browser
        .waitForElementByCss(searchButton, delay, pollFreq)
        .click().should.be.fulfilled
        .should.notify(done)

    it 'Should find item "Kallion kirjasto"', (done) ->
      browser
        .waitForElementByCss(searchResultPath, asserters.textInclude("Kallion kirjasto"), delay, pollFreq)
        .should.be.fulfilled
        .should.notify(done)

    it 'Should not find item "Kallio2n kirjasto"', (done) ->
      browser
        .waitForElementByCss(searchResultPath, asserters.textInclude("Kallio2n kirjasto"), errorDelay, pollFreq)
        .should.be.rejected
        .should.notify(done)
  describe 'Test embedding', ->
    embedUrl = baseUrl + '/embed'
    describe 'Test embedded addresses', ->
      embeds = [
        {
          path: '/address/Espoo/Veräjäpellonkatu/15'
          location:
            lat: 60.2257708
            lng: 24.8041296
          name: 'Veräjäpellonkatu 15, Espoo'

        },
        {
          path: '/address/Espoo/Kamreerintie/3'
          location:
            lat: 60.2042426
            lng: 24.6560127
          name: 'Kamreerintie 3, Espoo'
        }
      ]
      embeds.map (embed) ->
        describe embed.path, ->
          it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
            browser
              .get(embedUrl + embed.path)
              .title().should.become(pageTitle)
              .should.notify(done)

          it 'Should display popup with correct street address', (done) ->
            browser
            .get(embedUrl + embed.path)
            .waitForElementByCssSelector(
                '.leaflet-popup-content > .unit-name',
                asserters.isDisplayed,
                delay,
                pollFreq,
              (err, el) ->
                el.text (err, text) -> text.should.equal(embed.name)
            )
            .should.notify done

          it 'Should display marker for address', (done) ->
            browser
              .waitForElementByCssSelector(
                '.leaflet-overlay-pane svg path.leaflet-clickable',
                asserters.isDisplayed,
                delay,
                pollFreq
              )
              .should.notify(done)

        return

    describe 'Test embedded units', ->
      embeds = [
        {
          path: '/unit/41047'#?bbox=60.18672,24.92038,60.19109,24.93742,
          name: 'Uimastadion / Maauimala'
        }
      ]

      embeds.map (embed) ->
        describe embed.path, ->
          it 'Should display popup with the unit name', (done) ->
            browser
              .get(embedUrl + embed.path)
              .waitForElementByCssSelector(
                '.leaflet-popup-content > .unit-name',
                asserters.isDisplayed,
                delay,
                pollFreq,
                (err, el) ->
                  el.text (err, text) -> text.should.equal(embed.name)
              )
              .should.notify done
          it 'Should display marker icon', (done) ->
            browser
              .waitForElementsByCssSelector('.leaflet-marker-pane > .leaflet-marker-icon', asserters.isDisplayed, delay, pollFreq)
              .should.notify done
