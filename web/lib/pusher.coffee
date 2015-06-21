# Pusher
# ======
#
# **Pusher** is responsible for realtime communication with clients. It makes
# use of [socket.io](http://socket.io/) to pass on notifications. Define your
# communication channels here.
#
# Copyright &copy; Michael Bärtschi, MIT Licensed.

# Module dependencies
logger       = require './logger'
cookieParser = require 'cookie-parser'
nconf        = require 'nconf'

# Expose pusher
pusher = exports = module.exports = class Pusher

  # ---
  # **constructor**</br>
  # Create Pusher and assign socket.io</br>
  # `params:`
  #   * *io* `<socket.io>` the socket.io instance
  constructor: (@io) ->
    logger.log 'info', 'initializing', 'Pusher'
    @clients = {}

    parseCookie = cookieParser nconf.get 'session:secret'
    @io.sockets.on 'connection', (socket) =>
      parseCookie socket.handshake, null, (err) =>
        if socket.handshake.signedCookies['connect.sid']?
          sessionID = socket.handshake.signedCookies['connect.sid']
          if not @clients[sessionID]?
            @clients[sessionID] = socket
            socket.on 'disconnect', =>
              delete @clients[sessionID]

  # ---
  # **update**</br>
  # Sends a notification to clients that algorithms have changed. All (updated) algorithms
  # are passed along with the message</br>
  # `params:`
  #   * *algorithms* `<Array>` of all (updated) algorithms
  update: (algorithms) =>
    logger.log 'info', 'pushing algorithm updates', 'Pusher'
    @io.emit 'update algorithms', algorithms

  # ---
  # **add**</br>
  # Sends a notification to clients that algorithms have been added. New algorithms
  # are passed along with the message</br>
  # `params:`
  #   * *algorithms* `<Array>` of new algorithms
  add: (algorithms) =>
    logger.log 'info', 'pushing new algorithms', 'Pusher'
    @io.emit 'add algorithms', algorithms

  # ---
  # **delete**</br>
  # Sends a notification to clients that one ore more algorithms have been deleted.
  # Deleted algorithms are passed along with the message so they can be removed
  # on client side</br>
  # `params:`
  #   * *algorithms* `<Array>` of algorithms to be removed
  delete: (algorithms) =>
    logger.log 'info', 'pushing algorithms to remove', 'Pusher'
    @io.emit 'delete algorithms', algorithms

  # ---
  # **sessionDestroy**</br>
  # Sends a notification to client with given sessionID that his session has expired</br>
  # `params:`
  #   * *id* `<String>` session id
  sessionDestroy: (id) =>
    logger.log 'debug', "session #{id} has expired", 'Pusher'
    if @clients[id]? then @clients[id].emit 'session_expired'
