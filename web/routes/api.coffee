# API
# ===
#
# **API** exposes all routes belonging to `/api/`.
#
# Copyright &copy; Michael Bärtschi, MIT Licensed.

# Module dependencies
nconf       = require 'nconf'
loader      = require '../lib/loader'
mongoose    = require 'mongoose'
fs          = require 'fs-extra'
Validator   = require('jsonschema').Validator
validator   = new Validator
utils       = require './utils'
_           = require 'lodash'
gm          = require 'gm'
logger      = require '../lib/logger'

# Expose api routes
api = exports = module.exports = (router) ->

  # ---
  # **router.get** `/api/settings`
  #   * method: GET
  #   * params:
  #     * *type* `<String>` (optional) set type if you want to only fetch some parts of the
  #       client settings specified in `./web/conf/client.[dev/prod].json`
  #   * return: client side settings specified in `./web/conf/client.[dev/prod].json`
  router.get '/api/settings', (req, res) ->
    params = req.query

    if params.type?
      settings = nconf.get "web:#{params.type}"
    else
      settings = nconf.get 'web'

    res.status(200).json settings

  # ---
  # **router.get** `/api/algorithms`
  #   * method: GET
  #   * params: none
  #   * return: All algorithms currently stored in mongoDB
  router.get '/api/algorithms', (req, res) ->
    Algorithm = mongoose.model 'Algorithm'

    fields =
      name: true
      description: true
      url: true
      host: true
      _lastChange: true

    Algorithm.find {}, fields, (err, algorithms) ->
      if err?
        res.status(404).json error: 'There was an error while loading the algorithms'
      else
        res.status(200).json algorithms

  # ---
  # **router.get** `/api/algorithm`
  #   * method: GET
  #   * params:
  #     * *id* `<String>` the algorithms id
  #   * return: algorithm details for algorithm with _id == id
  #
  # This method will first fetch the algorithm from mongoDB and then
  # calls the algorithms url to fetch the details from the remote host.
  # Those details are validated against the algorithm schema defined
  # in in `./web/conf/schemas.json`
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
          try
            details = JSON.parse resp
            valid = true
          catch e
            valid = false
          finally
            if valid
              algorithmDetailsErrors = validator.validate(details, nconf.get('parser:details:algorithmSchema')).errors
              if algorithmDetailsErrors.length
                res.status(400).json error: 'invalid json structure'
              else
                res.status(200).json details
            else
              res.status(400).json error: 'invalid json structure'

  # ---
  # **router.post** `/api/algorithm`
  #   * method: POST
  #   * params:
  #     * *algorithm* `<Object>` the algorithm to use
  #     * *image* `<Object>` the image to process
  #     * *inputs* `<Object>` additional information for the algorithm
  #     * *highlighter* `<Object>` the selected region
  #   * return: the result of the algorithm applied on the image with the given additional information
  #
  # The algorithm and image objects must conform to the mongoDB schemas specified for them. The image will
  # be sent to the remote host as base64 encoded image along with the other information. The response from
  # the remote host must meet the JSON-Schema specification defined in `./web/conf/schemas.json`. If response
  # contains a base64 encoded image, this will be stored as .png image and passed on as result image. Otherwise
  # the origin image will be passed on (if highlighters are defined in response)
  router.post '/api/algorithm', (req, res) ->
    params = req.body
    return res.status(400).send() if not params.algorithm or not params.image or not params.inputs or not params.highlighter

    getImageAsBase64 = (path, callback) ->
      fs.readFile path, (err, image) ->
        if err?
          callback "could not base64 encode image"
        else
          callback null, image.toString('base64')

    processResponse = (result, callback) ->
      responseErrors = validator.validate(result, nconf.get('parser:details:responseSchema')).errors
      if responseErrors.length
        callback { status: 400, error: responseErrors[0].stack }
      else if result.image
        path = params.image.path.replace '.png', '_output_' + new Date().getTime() + '.png'
        values = path.split '/'
        serverName = values[values.length - 1]
        url = path.replace 'public', ''
        image =
          serverName: serverName
          clientName: params.algorithm.name.trim().replace(' ', '_') + '_' + new Date().getTime() + '.png'
          sessionId: req.sessionID
          extension: 'png'
          type: 'image/png'
          path: path
          url: url
        buffer = new Buffer result.image, 'base64'
        fs.writeFile path, buffer, (err) ->
          if err?
            logger.log 'warn', "fs could not write buffered image to disk error=#{err}", 'API'
            callback { status: 500, error: err}
          else
            image.size = utils.getFilesizeInBytes path
            utils.createThumbnail image, (err, thumbPath, thumbUrl) ->
              if err?
                callback { status: 500, error: err}
              else
                image.thumbPath = thumbPath
                image.thumbUrl = thumbUrl
                Image = mongoose.model 'Image'
                query =
                  sessionId: req.sessionID
                  serverName: serverName
                Image.update query, image, upsert: true, (err) ->
                  if err?
                    logger.log 'warn', 'could not save image', 'API'
                    callback { status: 500, error: err}
                  else
                    result.image = image
                    callback null, result
      else if result.highlighters
        # pass on input image as we want to display result highlighters on that image
        result.image = params.image
        callback null, result
      else
        callback null, result

    Algorithm = mongoose.model 'Algorithm'
    Algorithm.findById params.algorithm.id, (err, algorithm) ->
      if err or not algorithm?
        res.status(404).send()
      else
        body =
          inputs: params.inputs
          highlighter: params.highlighter

        getImageAsBase64 params.image.path, (err, base64Image) ->
          if err?
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
                  res.status(err).send()
                else
                  res.status(500).json err
              else if not result?
                res.status(500).json error: 'no response received'
              else
                if result?.image? then resPayloadHasImage = true
                processResponse result, (err, resultProcessed) ->
                  if err?
                    res.status(err.status).json err.error
                  else
                    resultProcessed.reqPayload = body
                    resultProcessed.resPayload =
                      output: result.output
                      highlighters: result.highlighters
                    if body.image? then body.image = 'Base64 encoded image'
                    if resPayloadHasImage then resultProcessed.resPayload.image = 'Base64 encoded image'
                    res.status(200).json resultProcessed
