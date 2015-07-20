(function() {
  describe('DOM Tests', function() {
    var el, myEl;
    el = document.createElement('div');
    el.id = 'myDiv';
    el.innerHTML = 'Hi there!';
    el.style.background = '#ccc';
    document.body.appendChild(el);
    myEl = document.getElementById('myDiv');
    it('is in the DOM', function() {
      expect(myEl).to.not.equal(null);
    });
    it('is a child of the body', function() {
      expect(myEl.parentElement).to.equal(document.body);
    });
    it('has the right text', function() {
      expect(myEl.innerHTML).to.equal('Hi there!');
    });
    it('has the right background', function() {
      expect(myEl.style.background).to.equal('rgb(204, 204, 204)');
    });
  });

  describe('Test Navigation Widget', function() {
    var baseUrl, browserContainerPath, pageTitle, searchResult, serviceTreeItemPath;
    browserContainerPath = '#browse-region > div > span.text';
    serviceTreeItemPath = '#service-tree-container ul li';
    baseUrl = 'http://palvelukartta.hel.fi/';
    pageTitle = 'Pääkaupunkiseudun palvelukartta';
    searchResult = 'Terveys';
    return it('page title ok', function() {
      expect(document.title).to.equal(pageTitle);
    });
  });

}).call(this);
