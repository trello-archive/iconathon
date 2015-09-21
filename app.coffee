express = require 'express'
st = require 'st'

app = express()
http = require('http').Server(app)

mountOpts = {
  path: __dirname + '/build'
  url: '/'
  index: 'demo/demo.html'
  cache: false
}

mount = st mountOpts

console.log 'Running on 127.0.0.1:4004'

app.use(mount)
http.listen(4004)
