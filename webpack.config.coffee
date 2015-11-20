webpack = require "webpack"
path = require "path"

module.exports =
  context: __dirname
  entry: "file?name=index.html!jade-html!./views/base.jade"
  output:
    path: path.join __dirname, "dist"
    filename: "bundle.js"
    publicPath: "/static/"
  resolve:
    root: __dirname
    modulesDirectories: ["src", "node_modules"]
  module:
    loaders: [
      {
        test: /\.coffee$/
        loader: "coffee"
      }
      {
        test: /\.jade$/
        loader: "jade-html"
      }
      {
        test: /\.less$/
        loader: 'style!css!less'
      }
    ]
