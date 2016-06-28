module.exports = (grunt) ->
  tests = [
    'promises-test.js',
    'embed-test.js'
  ]
  tests.map (testFile, i, arr) ->
    arr[i] ='<%= assets %>/test/' + testFile
    return
  return {
    options:
      timeout: 1000 * 60 * 3
    'phantom-test':
      src: tests
      options:
        testName: 'service map phantom test'
        usePhantom: true
        usePromises: true
        reporter: 'spec'
    'chrome-test':
      src: tests
      options:
        testName: 'selenium test'
        concurrency: 1
        usePromises: true
        autoInstall: true
        hostname: '127.0.0.1'
        port: '4444'
        browsers: [
          { browserName: 'chrome' }
        ]
    'firefox-test':
      src: tests
      options:
        testName: 'selenium test'
        concurrency: 1
        usePromises: true
        # Firefox seems to be defunct with selenium 2.44.0
        # if the server is run manually the tests succeed.
        # Tested with selenium 2.47.1.
        autoInstall: false
        hostname: '127.0.0.1'
        port: '4444'
        browsers: [
          { browserName: 'firefox' }
        ]
    sauce:
      src: tests
      options:
        testName: 'sauce usage test'
        usePromises: true
        reporter: 'spec'
        concurrency: 1
        secureCommands : true
        tunneled: true
        username: process.env.SAUCE_USERNAME
        key: process.env.SAUCE_ACCESS_KEY
        browsers: [
          {browserName: 'chrome', platform: 'Windows 7', version: '44'}
        ]
  }
