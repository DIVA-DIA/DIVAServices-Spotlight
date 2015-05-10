_           = require 'lodash'
util        = require 'util'
nconf       = require 'nconf'
logger      = require './logger'
fs          = require 'fs-extra'
mongoose    = require 'mongoose'

stringifySerializationOptions =
  serialize: JSON.stringify
  unserialize: JSON.parse

module.exports = (connect) ->
  Store = connect.Store or connect.session.Store

  MongoStore = (options) ->
    options = _.defaults(options or {}, nconf.get 'mongoStore:defaultOptions')
    options = _.assign(options, stringifySerializationOptions)
    @options = options
    Store.call this, options
    self = this

    changeState = (newState) ->
      self.state = newState
      self.emit newState
      return

    removeImageFolder = (sessionId) ->
      dir = nconf.get('web:uploader:destination') + sessionId
      fs.exists dir, (exists) ->
        if exists
          fs.emptyDir dir, (err) ->
            if err
              logger.log 'warn', "the following directory was not removed: #{dir}. Please do it manually to keep the server clean", 'ConnectMongo'
            else
              logger.log 'debug', "removed directory #{dir}", 'ConnectMongo'
              fs.rmdir dir

    removeImagesFromDb = (sessionId) ->
      Image = mongoose.model 'Image'
      query =
        sessionId: sessionId
      Image.remove query, (err) ->
        if err? then logger.log 'warn', "images for session=#{sessionId} were not removed error=#{err}", 'ConnectMongo'

    connectionReady = (err) ->
      if err
        logger.log 'debug', 'not able to connect to the database', 'ConnectMongo'
        changeState 'disconnected'
        throw err

      self.collection = self.db.collection(options.collection)
      setInterval (->
        self.collection.find(expires: $lt: new Date).toArray (err, sessions) ->
          if err
            throw err
          for session in sessions
            removeImageFolder session._id
            removeImagesFromDb session._id
          self.collection.remove { expires: { $lt: new Date } }, w: 0
          return
        return
      ), options.autoRemoveInterval
      changeState 'connected'
      return

    initWithMongooseConnection = ->
      if options.mongooseConnection.readyState == 1
        self.db = options.mongooseConnection.db
        process.nextTick connectionReady
      else
        options.mongooseConnection.once 'open', ->
          self.db = options.mongooseConnection.db
          connectionReady()
          return
      return

    @getCollection = (done) ->
      switch self.state
        when 'connected'
          done null, self.collection
        when 'connecting'
          self.once 'connected', ->
            done null, self.collection
            return
        when 'disconnected'
          done new Error('Not connected')
      return

    @getSessionId = (sid) ->
      sid

    changeState 'init'
    initWithMongooseConnection()
    changeState 'connecting'
    return

  util.inherits MongoStore, Store

  MongoStore::get = (sid, callback) ->
    if !callback
      callback = _.noop
    sid = @getSessionId(sid)
    self = this
    query =
      _id: sid
      $or: [
        expires: $exists: false
        expires: $gt: new Date
      ]
    @getCollection (err, collection) ->
      if err
        return callback(err)
      collection.findOne query, (err, session) ->
        if err
          logger.log 'debug', "not able to execute `find` query for session: #{sid}", 'ConnectMongo'
          return callback(err)
        if session
          s = undefined
          try
            s = self.options.unserialize(session.session)
            if self.options.touchAfter > 0 and session.lastModified
              s.lastModified = session.lastModified
          catch err
            logger.log 'debug', 'unable to deserialize session', 'ConnectMongo'
            callback err
          callback null, s
        else
          callback()
        return
      return
    return

  MongoStore::set = (sid, session, callback) ->
    if !callback
      callback = _.noop
    sid = @getSessionId(sid)
    # removing the lastModified prop from the session object before update
    if @options.touchAfter > 0 and session and session.lastModified
      delete session.lastModified
    s = undefined
    try
      s =
        _id: sid
        session: @options.serialize(session)
    catch err
      logger.log 'debug', 'unable to serialize session', 'ConnectMongo'
      callback err
    if session and session.cookie and session.cookie.expires
      s.expires = new Date(session.cookie.expires)
    else
      s.expires = new Date(Date.now() + @options.ttl * 1000)
    if @options.touchAfter > 0
      s.lastModified = new Date
    @getCollection (err, collection) ->
      if err
        return callback(err)
      collection.update { _id: sid }, s, {
        upsert: true
        safe: true
      }, (err) ->
        if err
          logger.log 'debug', "not able to set/update session: #{sid}", 'ConnectMongo'
        callback err
        return
      return
    return

  MongoStore::touch = (sid, session, callback) ->
    updateFields = {}
    touchAfter = @options.touchAfter * 1000
    lastModified = if session.lastModified then session.lastModified.getTime() else 0
    currentDate = new Date
    sid = @getSessionId(sid)
    callback = if callback then callback else _.noop

    if touchAfter > 0 and lastModified > 0
      timeElapsed = currentDate.getTime() - session.lastModified
      if timeElapsed < touchAfter
        return callback()
      else
        updateFields.lastModified = currentDate
    if session and session.cookie and session.cookie.expires
      updateFields.expires = new Date(session.cookie.expires)
    else
      updateFields.expires = new Date(Date.now() + @options.ttl * 1000)
    @getCollection (err, collection) ->
      if err
        return callback(err)
      collection.update { _id: sid }, { $set: updateFields }, { safe: true }, (err, result) ->
        if err
          logger.log 'debug', "not able to touch session: #{sid} (error)", 'ConnectMongo'
          callback err
        else if result.nModified == 0
          logger.log 'debug', "not able to touch session: #{sid} (not found)", 'ConnectMongo'
          callback new Error('Unable to find the session to touch')
        callback()
        return
      return
    return

  MongoStore::destroy = (sid, callback) ->
    if !callback
      callback = _.noop
    sid = @getSessionId(sid)
    @getCollection (err, collection) ->
      if err
        return callback(err)
      collection.remove { _id: sid }, (err) ->
        if err
          logger.log 'debug', "not able to destroy session: #{sid}", 'ConnectMongo'
        callback err
        return
      return
    return

  MongoStore::length = (callback) ->
    if !callback
      callback = _.noop
    @getCollection (err, collection) ->
      if err
        return callback(err)
      collection.count {}, (err, count) ->
        if err
          logger.log 'debug', 'not able to count sessions', 'ConnectMongo'
        callback err, count
        return
      return
    return

  MongoStore::clear = (callback) ->
    if !callback
      callback = _.noop
    @getCollection (err, collection) ->
      if err
        return callback(err)
      collection.drop (err) ->
        if err
          logger.log 'debug', 'not able to clear sessions', 'ConnectMongo'
        callback err
        return
      return
    return

  MongoStore
