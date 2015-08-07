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
