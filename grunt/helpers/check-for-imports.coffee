module.exports = (details, shouldIncludeCallback) ->
  fs = require 'fs'
  path = require 'path'
  async = require 'async'

  checkFileForModifiedImports = async.memoize (filepath, fileCheckCallback) ->
    fs.readFile filepath, 'utf8', (error, data) ->
      checkNextImport = ->
        if (match = regex.exec(data)) is null # all @import files has been checked.
          return fileCheckCallback(false)
        importFilePath = path.join(directoryPath, match[1] + '.less')
        fs.exists importFilePath, (exists) ->
          # @import file does not exists.
          return checkNextImport() unless exists # skip to next
          fs.stat importFilePath, (error, stats) ->
            if stats.mtime > details.time
              # @import file has been modified, -> include it.
              fileCheckCallback true
            else
              # @import file has not been modified but, lets check the @import's of this file.
              checkFileForModifiedImports importFilePath, (hasModifiedImport) ->
                if hasModifiedImport
                  fileCheckCallback true
                else
                  checkNextImport()

      directoryPath = path.dirname(filepath)
      regex = /@import (?:\([^)]+\) )?"(.+?)(\.less)?"/g
      match = undefined
      checkNextImport()

  # only add override behavior to less tasks.
  if details.task is 'less'
    checkFileForModifiedImports details.path, (found) ->
      shouldIncludeCallback found
      return null
  else
    shouldIncludeCallback false
  return null
