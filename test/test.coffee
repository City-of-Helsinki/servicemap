module.exports =

    'Test Typeahead': (test) ->
        console.log(test)
        searchFieldPath = '#search-region > div > form > span.twitter-typeahead > input'
        typeaheadResultPath = '#search-region .twitter-typeahead .tt-dropdown-menu .tt-suggestions .tt-suggestion .typeahead-suggestion'
        baseUrl = 'http://palvelukartta.hel.fi/'
        searchText = 'kallion kirjasto'
        searchResult = 'Kallion kirjasto'

        test.expect(1)
        test.open(baseUrl)
            .click(searchFieldPath)
            .type(searchFieldPath, searchText)
            .waitForElement(typeaheadResultPath, 10000)
            .assert(typeaheadResultPath).to.have.descendants('.suggestion-text').contain(searchResult)
            .done()
        return


    'Test Navigation Widget ': (test) ->
        browserContainerPath = '#browse-region > div > span.text'
        serviceTreeItemPath = '#service-tree-container ul li'
        baseUrl = 'http://palvelukartta.hel.fi/'
        pageTitle = 'Pääkaupunkiseudun palvelukartta'
        searchResult = 'Terveys'

        test.expect(1)
        test.open(baseUrl)
            .assert.title()
            .is(pageTitle, 'Page title ok')
            .click(browserContainerPath)
            .waitForElement(serviceTreeItemPath)
            .assert.chain()
                .query(serviceTreeItemPath)
                    .contain.text(searchResult, 'Service tree item found')
                    .end()
                .end()
            .done()
        return

    'Test Search': (test) ->

        searchFieldPath = '#search-region > div > form > span.twitter-typeahead > input'
        searchResultPath = '#navigation-contents .result-contents ul'
        searchButton = '#search-region > div > form > span.action-button.search-button > span'
        searchText = 'kallion kirjasto'
        baseUrl = 'http://palvelukartta.hel.fi/'
        searchResult = 'Kallion kirjasto'

        test.expect(1)
        test.open(baseUrl)
            .click(searchFieldPath)
            .type(searchFieldPath, searchText)
            .click(searchButton)
            .waitForElement(searchResultPath, 20000)
            .assert.chain()
                .query(searchResultPath)
                    .assert.contain.text(searchResult, "Search result found")
                .end()
            .end()
            .done()
        return
