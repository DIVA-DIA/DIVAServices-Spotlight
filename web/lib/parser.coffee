logger      = require './logger'
async       = require 'async'
fse         = require 'fs-extra'
nconf       = require 'nconf'
_           = require 'lodash'

parser = exports = module.exports = {}

parser.parse = (structure, callback) ->
  async.waterfall [
    (next) ->
      _checkValidStructure structure, (err, validStructure) ->
        return next err if err?
        next null, validStructure
    ,
    (validStructure, next) ->
      _compareStructures validStructure, (err, hasChanged) ->
        return next err if err?
        next null, hasChanged, validStructure
  ], (err, hasChanged, validStructure) ->
    return callback err if err?
    if hasChanged
      _storeNewStructure validStructure, (err) ->
        return callback err if err?
        logger.log 'info', 'save new structure status=succeeded', 'Parser'
        callback null, validStructure
    else
      logger.log 'info', 'no changes to apply', 'Parser'
      callback()

_checkValidStructure = (structure, callback) ->
  try
    structure = JSON.parse structure
    valid = true
  catch e
    valid = false
  finally
    if valid
      _structure =
        records: []
      i = 0
      _.forIn structure, (algorithm, key) ->
        skip = false
        _.each nconf.get('parser:mandatoryFields'), (field) ->
          if not (field in _.keys algorithm)
            logger.log 'info', "skipping algorithm #{algorithm.name} because field #{field} is missing", 'Parser'
            skip = true
          else
            skip = false
            algorithm.index = i++
        if not skip then _structure.records.push algorithm
      callback null, _structure
    else
      callback 'Not a valid JSON format'

_compareStructures = (newStructure, callback) ->
  _loadStructure (err, oldStructure) ->
    return callback err if err?
    isEqual = _.isEqual oldStructure, newStructure
    callback null, !isEqual

_loadStructure = (callback) ->
  dir = nconf.get 'parser:fileLocation'
  fse.readJson dir, (err, oldStructure) ->
    # if file does not yet exist, just callback empty object -> new structure will then be stored
    return callback null, {} if err?
    callback null, oldStructure

_storeNewStructure = (newStructure, callback) ->
  dir = nconf.get 'parser:fileLocation'
  fse.ensureFile dir, (err) ->
    return callback err if err?
    fse.writeFile dir, JSON.stringify(newStructure, null, 4), (err) ->
      callback err
