Q = require('q')
chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
should = chai.should()
helpers = require('./helper')

wd = undefined
browser = undefined
asserters = undefined

delay = 20000
errorDelay = 1000
pollFreq = 100

baseUrl = 'http://localhost:9001'
pageTitle = 'Pääkaupunkiseudun palvelukartta'
toggleColourBlind = '#personalisation .accessibility-personalisation ul.personalisations li[data-type="colour_blind"]'
personalisationButton = '#personalisation .personalisation-button'
unitNamePopup = '.leaflet-popup-content > .unit-name'
unitMarker = '.leaflet-marker-pane > .leaflet-marker-icon'
addressMarker = '.leaflet-overlay-pane svg path.leaflet-clickable'

resetSession = (browser) ->
    browser.quit()
    browser = browser.init
        browserName: browser.browserTitle

describe 'Test embedding', ->
    before ->
        wd = @wd
        chaiAsPromised.transferPromiseness = wd.transferPromiseness
        browser = @browser
        asserters = wd.asserters
        helpers.resetSession browser
    embedUrl = baseUrl + '/embed'


    startEmbedTest = (embed) ->
        embed.map = embed.map || 'servicemap'
        it 'Title should become "Pääkaupunkiseudun palvelukartta"', (done) ->
            browser
            .get embedUrl + embed.path
            .title().should.become pageTitle
            .should.notify done
        it 'Should display map', (done) ->
            browser
            .waitForElementByCssSelector '#map', asserters.isDisplayed, delay, pollFreq
            .should.notify done
        it 'Should use "' + embed.map + '" map layer', (done) ->
            browser
            .waitForElementByCssSelector '#app-container.' + embed.map, asserters.isDisplayed, delay, pollFreq
            .should.notify done
        it 'Should not display navigation region', (done) ->
            browser
            .waitForElementByCssSelector '#navigation-region', asserters.isNotDisplayed, delay, pollFreq
            .should.notify done
        it 'Should display zoom buttons', (done) ->
            browser
            .waitForElementByCssSelector '.leaflet-control-zoom', asserters.isDisplayed, delay, pollFreq
            .should.notify done
        it 'Should display logo', (done) ->
            browser
            .waitForElementByCssSelector '.bottom-logo', asserters.isDisplayed, delay, pollFreq
            .should.notify done

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
                startEmbedTest embed
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
                    .waitFor asserters.jsCondition helpers.isNearMapCenter(embed.location), delay, pollFreq
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
                startEmbedTest embed
                it 'Should display one marker icon', (done) ->
                    browser
                    .waitForElementsByCssSelector unitMarker, asserters.isDisplayed, delay, pollFreq
                    .then (els) ->
                        should.equal els.length, 1
                    .should.notify done
                unless embed.bbox
                    it 'Should be centered to the unit', (done) ->
                        browser
                        .waitFor asserters.jsCondition(helpers.isNearMapCenter(embed.location)), delay, pollFreq
                        .should.notify done
                else
                    it 'Should contain unit location', (done) ->
                        browser
                        .waitFor asserters.jsCondition(helpers.containsPoint(embed.location)), delay, pollFreq
                        .should.notify done
                    it 'Should contain bbox', (done) ->
                        browser
                        .waitFor asserters.jsCondition(helpers.containsBbox(embed.bbox)), delay, pollFreq
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
                startEmbedTest embed
                it 'Should have marker icons', (done) ->
                    browser
                    .waitForElementsByCssSelector unitMarker, delay, pollFreq
                    .then (els) ->
                        els.length.should.be.greaterThan 1
                    .should.notify done
                it 'Should contain the bbox', (done) ->
                    browser
                    .waitFor asserters.jsCondition(helpers.containsBbox(embed.bbox)), delay, pollFreq
                    .should.notify done
            return
    describe 'Test if personalisation choices affect embedded views', ->
        after ->
            resetSession browser
        embed =
            path: '/address/Espoo/Veräjäpellonkatu/15'
            location:
                lat: 60.2257708
                lng: 24.8041296
            name: 'Veräjäpellonkatu 15, Espoo'

        it 'Should click personalisation button', (done) ->
            browser.get baseUrl
            .waitForElementByCssSelector personalisationButton, delay, pollFreq
            .click().should.be.fulfilled
            .should.notify done
        it 'Should click accessibility personalisation "I have trouble distinguishing colours"', (done) ->
            browser.waitForElementByCssSelector toggleColourBlind, delay, pollFreq
            .click().should.be.fulfilled
            .should.notify done
        it 'Should change map layer to "accessible_map"', (done) ->
            browser
            .waitForElementByCssSelector '.maplayer-accessible_map', asserters.isDisplayed, delay, pollFreq
            .should.notify done
        startEmbedTest embed