express     = require 'express'
http        = require 'http'
sysPath     = require 'path'
bodyParser  = require 'body-parser'

app = express()

# enable body parser for json
app.use bodyParser.json()

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
    input: []

  res.send records

app.post '/histogramenhancement', (req, res) ->
  # set a random timeout before sendin response
  # timeout should be between 1 and server.timeout
  random = Math.floor Math.random() * 11 + 1
  setTimeout (-> res.send req.body), random * 1000


app.get '/multiscaleipd', (req, res) ->
  records =
    name: 'multiscaleipd'
    description: 'this will apply the multiscaleipd algorithm on your image'
    url: 'http://localhost:8081/multiscaleipd'
    input: [
      {
        highlighter: 'polygon'
      }
      {
        select:
          name: 'detector'
          description: 'this is just a test description for a select'
          options:
            required: true
            values: [
              'Harris'
              'Narris'
            ]
            default: 0
      }
      {
        number:
          name: 'blurSigma'
          description: 'this is just a test description for blugSigma'
          options:
            required: true
            min: 0
            max: 5
            steps: 1
            default: 2
      }
      {
        number:
          name: 'numScales'
          options:
            required: true
            default: 1
      }
      {
        number:
          name: 'numOctaves'
          options:
            required: true
            default: 2
      }
      {
        number:
          name: 'threshold'
          options:
            required: false
            steps: 0.000001
            default: 0.000001
      }
      {
        number:
          name: 'maxFeaturesPerScale'
          options:
            required: true
            default: 3
      }
      {
        text:
          name: 'textInputTest'
          description: 'this is just a test description for a text input'
          options:
            required: true
            min: 3
            max: 10
            default: 'test text'
      }
      {
        checkbox:
          name: 'testCheckbox'
          description: 'this is just a test description for a checkbox'
          options:
            required: true
            default: 1
      }
    ]

  res.send records

app.post '/multiscaleipd', (req, res) ->
  # set a random timeout before sendin response
  # timeout should be between 1 and server.timeout
  random = Math.floor Math.random() * 11 + 1
  setTimeout (-> res.send req.body), random * 1000

app.get '/noise', (req, res) ->
  records =
    name: 'noise'
    description: 'this will apply the noise algorithm on your image'
    url: 'http://localhost:8081/noise'
    input: [
      {
        highlighter: 'rectangle'
      }
    ]

  res.send records

app.post '/noise', (req, res) ->
  # set a random timeout before sendin response
  # timeout should be between 1 and server.timeout
  random = Math.floor Math.random() * 11 + 1
  setTimeout (-> res.send req.body), random * 1000

app.get '/otsubinazrization', (req, res) ->
  records =
    name: 'otsubinazrization'
    description: 'this will apply the otsubinazrization algorithm on your image'
    url: 'http://localhost:8081/otsubinazrization'
    input: []

  res.send records

app.post '/otsubinazrization', (req, res) ->
  # set a random timeout before sendin response
  # timeout should be between 1 and server.timeout
  random = Math.floor Math.random() * 11 + 1
  setTimeout (-> res.send req.body), random * 1000

app.get '/sauvalabinarization', (req, res) ->
  records =
    name: 'sauvalabinarization'
    description: 'this will apply the sauvalabinarization algorithm on your image'
    url: 'http://localhost:8081/sauvalabinarization'
    input: []

  res.send records

app.post '/sauvalabinarization', (req, res) ->
  # set a random timeout before sendin response
  # timeout should be between 1 and server.timeout
  random = Math.floor Math.random() * 11 + 1
  setTimeout (-> res.send req.body), random * 1000

app.use (err, req, res, next) ->
  res.status err.status or 500
  res.json err.statusText

# Wrap express app with node.js server in order to have stuff like server.stop() etc.
server = http.createServer(app)
server.timeout = 12000

server.listen 8081, ->
  console.log 'Server listening on port 8081'
