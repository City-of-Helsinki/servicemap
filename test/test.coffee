browserContainerPath = '#browse-region > div > span.text'
serviceTreeItemPath = '#service-tree-container > ul > li:nth-child(8) > div > span'
searchFieldPath = '#search-region > div > form > span.twitter-typeahead > input'
typeaheadResultPath = '#search-region" span.twitter-typeahead span.tt-suggestions div.text'
pageTitle = 'Pääkaupunkiseudun palvelukartta'
searchText = 'kallion kirjasto'


module.exports =
    'Test Navigation Widget ': (test) ->
        test.open('http://palvelukartta.hel.fi/')
            .assert.title()
            .is(pageTitle, 'Page title ok')
            .click(browserContainerPath)
            .waitForElement(serviceTreeItemPath)
            .assert.text(serviceTreeItemPath)
            .is('Terveys')
            .done()
        return
    'Test Typeahead': (test) ->
        test.open('http://palvelukartta.hel.fi/')
            .assert.title()
            .is(pageTitle, 'Page title ok')
            .click(searchFieldPath)
            .type(searchFieldPath, searcText)
            .waitForElement(serviceTreeItemPath)
            .assert.text(serviceTreeItemPath)
            .is('Terveys')
            .done()
        return
