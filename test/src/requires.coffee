###global globalVar:false###

assert = require('assert')
describe 'A Mocha test run by grunt-mocha-sauce', ->
  it 'can reference globals provided in a pre-require', ->
    assert.ok globalVar
    return
  return
