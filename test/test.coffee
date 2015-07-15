module.exports =
    'Test Search': (test) ->
        browserContainerPath = '#browse-region > div > span.text'
        serviceTreeItemPath = '#service-tree-container > ul > li:nth-child(8) > div > span'
        searchFieldPath = '#search-region > div > form > span.twitter-typeahead > input'
        searchResultPath = '#navigation-contents .result-contents ul'
        searchButton = '#search-region > div > form > span.action-button.search-button > span'
        #typeaheadResultPath = '#search-region" span.twitter-typeahead span.tt-suggestions div.text'
        typeaheadResultPath = '#navigation-contents > div > div.unit-region > div > div.result-contents > ul '
        pageTitle = 'Pääkaupunkiseudun palvelukartta'
        searchText = 'kallion kirjasto'
        typeaheadResultText = 'Kallion kirjasto'
        baseUrl = 'http://palvelukartta.hel.fi/'
        searchResult = 'Kallion kirjasto'
        test.expect(1)
        test.open(baseUrl)
            .waitForElement(searchFieldPath, 1000)
            .click(searchFieldPath)
            .type(searchFieldPath, searchText)
            .click(searchButton)
            #.screenshot("foobar.png")
            #.waitForElement(searchResultPath, 100000)
            #.screenshot("foobar2.png")
            .waitForElement(searchResult, 1000)
            .query(searchResultPath)
                .assert.text().to.contain(searchResult, "Search result found")
            .end()
            .done()
        test.screenshot("test-search.png")
        return
