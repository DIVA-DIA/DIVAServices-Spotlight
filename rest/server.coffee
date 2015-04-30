express     = require 'express'
http        = require 'http'
sysPath     = require 'path'

app = express()

# Root will respond with the REST url structure
app.get '/', (req, res) ->
  records = [
    {
      name: 'histogramenhancement'
      description: 'this will apply the histogramenhancement algorithm on your image. lets make a damn long description to test bootstrap behaviour'
      url: 'http://localhost:8081/histogramenhancement'
    }
    {
      name: 'multiscaleipd'
      description: 'this will apply the multiscaleipd algorithm on your image'
      url: 'http://localhost:8081/multiscaleipd'
    }
    {
      name: 'noise'
      description: 'this will apply the noise algorithm on your image'
      url: 'http://localhost:8081/noise'
    }
    {
      name: 'otsubinazrization'
      description: 'this will apply the otsubinazrization algorithm on your image'
      url: 'http://localhost:8081/otsubinazrization'
    }
    {
      name: 'sauvalabinarization'
      description: 'this will apply the sauvalabinarization algorithm on your image'
      url: 'http://localhost:8081/sauvalabinarization'
    }
  ]

  res.send records

app.get '/histogramenhancement', (req, res) ->
  records =
    name: 'histogramenhancement'
    description: 'this will apply the histogramenhancement algorithm on your image'
    url: 'http://localhost:8081/histogramenhancement'
    input: {}

  res.send records

app.get '/multiscaleipd', (req, res) ->
  records =
    name: 'multiscaleipd'
    description: 'this will apply the multiscaleipd algorithm on your image'
    url: 'http://localhost:8081/multiscaleipd'
    input:
      highlighter: 'polygon'
      select:
        name: 'detector'
        options:
          values: [
            'Harris'
          ]
      number:
        name: 'blurSigma'
        options:
          min: 0
          max: 5
          steps: 1
      number:
        name: 'numScales'
        options: {}
      number:
        name: 'numOctaves'
        options: {}
      number:
        name: 'threshold'
        options:
          steps: 0.000001
      number:
        name: 'maxFeaturesPerScale'
        options: {}
      text:
        name: 'textInputTest'
        options: {}
      checkbox:
        name: 'testCheckbox'
        options:
          values: [
            'Option 1'
            'Option 2'
          ]
          selected: 0

  res.send records

app.get '/noise', (req, res) ->
  records =
    name: 'noise'
    description: 'this will apply the noise algorithm on your image'
    url: 'http://localhost:8081/noise'
    input: {}

  res.send records

app.get '/otsubinazrization', (req, res) ->
  records =
    name: 'otsubinazrization'
    description: 'this will apply the otsubinazrization algorithm on your image'
    url: 'http://localhost:8081/otsubinazrization'
    input: {}

  res.send records

app.get '/sauvalabinarization', (req, res) ->
  records =
    name: 'sauvalabinarization'
    description: 'this will apply the sauvalabinarization algorithm on your image'
    url: 'http://localhost:8081/sauvalabinarization'
    input: {}

  res.send records

app.use (err, req, res, next) ->
  res.status err.status or 500
  res.render 'error',
    message: err.message
    error: err
  return

# Wrap express app with node.js server in order to have stuff like server.stop() etc.
server = http.createServer(app)
server.timeout = 2000

server.listen 8081, ->
  console.log 'Server listening on port 8081'
