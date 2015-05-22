nconf       = require 'nconf'
loader      = require '../lib/loader'
mongoose    = require 'mongoose'
fs          = require 'fs-extra'
_           = require 'lodash'

api = exports = module.exports = (router) ->

  router.get '/api/settings', (req, res) ->
    params = req.query

    if params.type?
      settings = nconf.get "web:#{params.type}"
    else
      settings = nconf.get 'web'

    res.status(200).json settings

  router.get '/api/algorithms', (req, res) ->
    Algorithm = mongoose.model 'Algorithm'

    fields =
      name: true
      description: true
      url: true
      host: true

    Algorithm.find {}, fields, (err, algorithms) ->
      if err?
        res.status(404).json error: 'There was an error while loading the algorithms'
      else if algorithms.length is 0
        res.status(404).json error: 'Not found'
      else
        res.status(200).json algorithms

  router.get '/api/algorithm', (req, res) ->
    params = req.query
    return res.status(404).json 'error': 'Not found' if not params.id

    Algorithm = mongoose.model 'Algorithm'
    Algorithm.findById params.id, (err, algorithm) ->
      if err
        res.status(404).json error: 'Not found'
      else
        url = algorithm.url

        settings =
          options:
            uri: url
            timeout: nconf.get 'server:timeout'
            headers: {}
          retries: nconf.get 'poller:retries'

        loader.get settings, (err, resp) ->
          return res.status(404).json 'error': 'Algorithm could not be loaded' if err?
          res.status(200).json resp

  router.post '/api/algorithm', (req, res) ->
    return res.status(400).send() if not req.body.algorithm

    getImageAsBase64 = (path, callback) ->
      fs.readFile path, (err, image) ->
        if err?
          callback "could not base64 encode image"
        else
          callback null, image.toString('base64')

    processResponse = (result, callback) ->
      if result.image
        image = new Buffer result.image, 'base64'
        path = req.body.image.path.replace '.png', '_output.png'
        url = path.replace 'public', ''
        fs.writeFile path, image, (err) ->
          if err
            callback 500
          else
            result.image = url
            callback null, result
      else if result.highlighters
        result.image = req.body.image.url
        callback null, result
      else
        callback null, result

    Algorithm = mongoose.model 'Algorithm'
    Algorithm.findById req.body.algorithm.id, (err, algorithm) ->
      if err or not algorithm?
        res.status(404).send()
      else
        body =
          inputs: req.body.inputs
          highlighter: req.body.highlighter

        getImageAsBase64 req.body.image.path, (err, base64Image) ->
          if err
            res.status(500).json error: err
          else
            body.image = base64Image

            settings =
              options:
                uri: algorithm.url
                timeout: nconf.get 'server:timeout'
                headers: {}
                method: 'POST'
                json: true

            loader.post settings, body, (err, result) ->
              if err?
                if _.isNumber err
                  return res.status(err).send()
                else
                  return res.status(500).json err
              processResponse result, (err, resultProcessed) ->
                if err
                  res.status(err).send()
                else
                  res.status(200).json resultProcessed
