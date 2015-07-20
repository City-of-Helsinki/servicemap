describe 'DOM Tests', ->
  el = document.createElement('div')
  el.id = 'myDiv'
  el.innerHTML = 'Hi there!'
  el.style.background = '#ccc'
  document.body.appendChild el
  myEl = document.getElementById('myDiv')
  it 'is in the DOM', ->
    expect(myEl).to.not.equal null
    return
  it 'is a child of the body', ->
    expect(myEl.parentElement).to.equal document.body
    return
  it 'has the right text', ->
    expect(myEl.innerHTML).to.equal 'Hi there!'
    return
  it 'has the right background', ->
    expect(myEl.style.background).to.equal 'rgb(204, 204, 204)'
    return
  return

describe 'Test Navigation Widget', ->
  browserContainerPath = '#browse-region > div > span.text'
  serviceTreeItemPath = '#service-tree-container ul li'
  baseUrl = 'http://palvelukartta.hel.fi/'
  pageTitle = 'Pääkaupunkiseudun palvelukartta'
  searchResult = 'Terveys'

  it 'page title ok', ->
    expect(document.title).to.equal(pageTitle)
    return

  it 'browser container dom available', ->
    expect($.)

    'Test Navigation Widget': (test) ->
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
