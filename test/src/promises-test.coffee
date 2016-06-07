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
unitNamePopup = '.leaflet-popup-content > .unit-name'
unitMarker = '.leaflet-marker-pane > .leaflet-marker-icon'
addressMarker = '.leaflet-overlay-pane svg path.leaflet-clickable'

describe 'Browser test', ->
  before ->
    wd = @wd
    chaiAsPromised.transferPromiseness = wd.transferPromiseness
    browser = @browser
    asserters = wd.asserters

  describe 'Test navigation widget', ->
    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        .get baseUrl
        .title().should.become pageTitle
        .should.notify done

    it 'Should contain button "Selaa palveluita"', (done) ->
      browser
        .waitForElementByCss browseButtonSelector, delay, pollFreq
        .click().should.be.fulfilled
        .should.notify done

    it 'Should contain list item "Terveys"', (done) ->
      browser
        .waitForElementByCss serviceTreeItemSelector, asserters.textInclude('Terveys'), delay, pollFreq
        .should.be.fulfilled
        .should.notify done

    # Sanity
    it 'Should not contain list item "Sairaus"', (done) ->
      browser
        .waitForElementByCss serviceTreeItemSelector, asserters.textInclude('Sairaus'), errorDelay, pollFreq
        .should.be.rejected
        .should.notify(done)


  describe 'Test look ahead', ->
    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        .get baseUrl
        .title().should.become pageTitle
        .should.notify done

    it 'Should find item "Kallion kirjasto"', (done) ->
      searchText = 'kallion kirjasto'
      browser
        .waitForElementByCss searchFieldPath, delay, pollFreq
        .click()
        .type searchText
        .waitForElementByCss typeaheadResultPath, asserters.textInclude("Kallion kirjasto"), delay, pollFreq
        .should.be.fulfilled
        .should.notify done

  describe 'Test search', ->
    it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
      browser
        .get baseUrl
        .title().should.become pageTitle
        .should.notify done

    it 'Should manage to input search text', (done) ->
      searchText = 'kallion kirjasto'
      browser
        .waitForElementByCss searchFieldPath, delay, pollFreq
        .click()
        .type searchText
        .should.be.fulfilled
        .should.notify done

    it 'Should manage to click search button', (done) ->
      browser
        .waitForElementByCss searchButton, delay, pollFreq
        .click().should.be.fulfilled
        .should.notify done

    it 'Should find item "Kallion kirjasto"', (done) ->
      browser
        .waitForElementByCss searchResultPath, asserters.textInclude("Kallion kirjasto"), delay, pollFreq
        .should.be.fulfilled
        .should.notify done

    it 'Should not find item "Kallio2n kirjasto"', (done) ->
      browser
        .waitForElementByCss searchResultPath, asserters.textInclude("Kallio2n kirjasto"), errorDelay, pollFreq
        .should.be.rejected
        .should.notify done
  describe 'Test embedding', ->
    embedUrl = baseUrl + '/embed'
    # Helper functions to get js string to be evaluated with
    # asserters.jsCondition
    isNearMapCenter = (location, delta = 1e-4) ->
      MAP_CENTER = 'app.getRegion("map").currentView.map.getCenter()'
      initialCenter =
        lat: MAP_CENTER + '.lat'
        lng: MAP_CENTER + '.lng'
      isNear = (x) =>
        'Math.abs(' + x + ') < ' + delta
      subLat = initialCenter.lat + ' - ' + location.lat
      latIsNear = isNear subLat
      subLng = initialCenter.lng + ' - ' + location.lng
      lngIsNear = isNear subLng
      return "#{latIsNear} && #{lngIsNear}"
    containsBbox = (bbox) ->
      MAP_BOUNDS = 'app.getRegion("map").currentView.map.getBounds()'
      BBOX_BOUNDS = "new L.LatLngBounds( new L.LatLng(#{bbox.sw}), new L.LatLng(#{bbox.ne}))"
      return "#{MAP_BOUNDS}.contains(#{BBOX_BOUNDS})"
    containsPoint = (point) ->
      MAP_BOUNDS = 'app.getRegion("map").currentView.map.getBounds()'
      POINT = "new L.LatLng(#{point.lat}, #{point.lng})"
      return "#{MAP_BOUNDS}.contains(#{POINT})"

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
              .get embedUrl + embed.path
              .title().should.become pageTitle
              .should.notify done

          it 'Should display popup with correct street address', (done) ->
            browser
            .get embedUrl + embed.path
            .waitForElementsByCssSelector unitNamePopup, asserters.isDisplayed, delay, pollFreq
            .then((els) ->
              should.equal els.length, 1
            )
            .text().should.become embed.name
            .should.notify done

          it 'Should display one marker for address', (done) ->
            browser
              .waitForElementsByCssSelector addressMarker, asserters.isDisplayed, delay, pollFreq
              .then (els) ->
                  should.equal els.length, 1
              .should.notify done

          it 'Should be centered to the address', (done) ->
            browser
              .waitFor asserters.jsCondition isNearMapCenter(embed.location), delay, pollFreq
              .should.notify done
        return
    describe 'Test embedded units', ->
      embeds = [
        {
          path: '/unit/41047'
          name: 'Uimastadion / Maauimala'
          location:
            lat: 60.188812
            lng: 24.930822
        },
        {
          path: '/unit/41047?bbox=60.18672,24.92038,60.19109,24.93742'
          name: 'Uimastadion / Maauimala'
          location:
            lat: 60.188812
            lng: 24.930822
          bbox:
            sw: '60.18672,24.92038'
            ne: '60.19109,24.93742'

        },
        {
          path: '/unit/40823'
          name: 'Kumpulan maauimala'
          location:
            lat: 60.208702
            lng: 24.958284
        },
        {
          path: '/unit/40823?bbox=60.20661,24.94783,60.21098,24.96489'
          name: 'Kumpulan maauimala'
          location:
            lat: 60.208702
            lng: 24.958284
          bbox:
            sw: '60.20661,24.94783'
            ne: '60.21098,24.96489'
        }
      ]
      embeds.map (embed) ->
        describe embed.path, ->
          it 'Should display one popup with the unit name', (done) ->
            browser
              .get embedUrl + embed.path
              .waitForElementsByCssSelector unitNamePopup, asserters.isDisplayed, delay, pollFreq
              .then (els) ->
                  should.equal els.length, 1
              .text().should.become embed.name
              .should.notify done
          it 'Should display one marker icon', (done) ->
            browser
              .waitForElementsByCssSelector unitMarker, asserters.isDisplayed, delay, pollFreq
              .then (els) ->
                should.equal els.length, 1
              .should.notify done
          unless embed.bbox
            it 'Should be centered to the unit', (done) ->
                browser
                  .waitFor asserters.jsCondition(isNearMapCenter(embed.location)), delay, pollFreq
                  .should.notify done
          else
            it 'Should contain unit location', (done) ->
              browser
              .waitFor asserters.jsCondition(containsPoint(embed.location)), delay, pollFreq
              .should.notify done
            it 'Should contain bbox', (done) ->
              browser
              .waitFor asserters.jsCondition(containsBbox(embed.bbox)), delay, pollFreq
              .should.notify done
        return
    describe 'Test embedded services', ->
      embeds = [
        {
          path: '/unit?service=25002&bbox=60.13744,24.77468,60.20935,25.04703&city=helsinki'
          bbox:
            sw: '60.13744,24.77468'
            ne: '60.20935,25.04703'
        },
        {
          path: '/unit?service=25010&bbox=60.13744,24.77468,60.20935,25.04703&city=helsinki'
          bbox:
            sw: '60.13744,24.77468'
            ne: '60.20935,25.04703'
        }
      ]
      embeds.map (embed) ->
        describe embed.path, ->
          it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
            browser
              .get embedUrl + embed.path
              .title().should.become pageTitle
              .should.notify done
          it 'Should have marker icons', (done) ->
            browser
              .waitForElementsByCssSelector unitMarker, delay, pollFreq
              .then (els) ->
                els.length.should.be.greaterThan 1
              .should.notify done
          it 'Should contain the bbox', (done) ->
            browser
            .waitFor asserters.jsCondition(containsBbox(embed.bbox)), delay, pollFreq
            .should.notify done
        return
