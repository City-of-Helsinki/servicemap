module.exports = (grunt) ->
  return {
    options:
      timeout: 1000 * 60 * 3
    'phantom-test':
      src: ['<%= assets %>/test/promises-test.js']
      options:
        testName: 'service map phantom test'
        usePhantom: true
        usePromises: true
        reporter: 'spec'
    'chrome-test':
      src: ['<%= assets %>/test/promises-test.js']
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
      src: ['<%= assets %>/test/promises-test.js']
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
      src: ['<%= assets %>/test/promises-test.js']
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
