browserContainerPath = '#browse-region > div > span.text'
serviceTreeItemPath = '#service-tree-container > ul > li:nth-child(8) > div > span'
searchFieldPath = '#search-region > div > form > span.twitter-typeahead > input'
#typeaheadResultPath = '#search-region" span.twitter-typeahead span.tt-suggestions div.text'
typeaheadResultPath = '#navigation-contents > div > div.unit-region > div > div.result-contents > ul > li > a :contains("Kallion kirjasto")'
pageTitle = 'Pääkaupunkiseudun palvelukartta'
searchText = 'kallion kirjasto'
typeaheadResultText = 'Kallion kirjasto'

module.exports =
    'Test Search': (test) ->
        test.open('http://palvelukartta.hel.fi/')
            .assert.title()
            .is(pageTitle, 'Page title ok')
            #.done()
            test.click(searchFieldPath)
            test.type(searchFieldPath, searchText)
            test.click('#search-region > div > form > span.action-button.search-button > span')
            test.waitForElement(typeaheadResultPath)
            test.assert.text(typeaheadResultPath).is(typeaheadResultText, "Typeahead result found")
            test.screenshot("foobar.png")
            .done()


    # 'Test Typeahead': (test) ->
    #     test.open('http://palvelukartta.hel.fi/')
    #         .assert.title()
    #         .is(pageTitle, 'Page title ok')
    #         #.done()
    #     test.click(searchFieldPath)
    #     test.type(searchFieldPath, searchText)
    #     test.waitForElement(typeaheadResultPath)
    #     #test.wait(10000)
    #     test.assert.text(typeaheadResultPath).is(typeaheadResultText, "Typeahead result found")
    #     test.screenshot("foobar.png")
    #     .done()
        #     .done()
        # return
    # 'Test Navigation Widget ': (test) ->
    #     test.open('http://palvelukartta.hel.fi/')
    #         .assert.title()
    #         .is(pageTitle, 'Page title ok')
    #         .click(browserContainerPath)
    #         .waitForElement(serviceTreeItemPath)
    #         .assert.text(serviceTreeItemPath)
    #         .is('Terveys', 'Service tree item found')
    #         .done()
    #     return
