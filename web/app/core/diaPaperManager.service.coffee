###
Factory diaPaperManager

* common service for setting up paperJS for given scope (vm) and element
* handles image and canvas scaling based on currently selected image
* this must be called by every highlighter
###
do ->
  'use strict'

  diaPaperManager = ->
    image = canvas = raster = null
    initialized = false
    @path = null

    factory = ->
      setup: setup
      reset: reset
      get: get
      set: set
      resetPath: resetPath

    set = (path) ->
      @path = path

    get = ->
      @path

    resetPath = ->
      if @path
        @path.remove()
      @path = null

    initializeCanvas = (callback) ->
      img = new Image()
      img.src = image.url
      $(img).bind 'load', ->
        width = $('.canvas-wrapper')[0].clientWidth
        height = img.height * (width/img.width)
        canvas.width = width
        canvas.height = height
        callback()

    drawRaster = (vm) ->
      if project.layers[0]?
        project.layers[0].removeChildren()
      raster = new Raster
        source: image.url
        position: view.center
      raster.on 'load', ->
        scale = view.size.width / @.bounds.width
        inverseScale = @.bounds.width / view.size.width
        vm.strokeWidth = 5 * inverseScale
        view.zoom = scale
        view.update()

    initPaper = (tools) ->
      paper.install window
      paper.setup canvas
      if tools?
        tool = new Tool()
        tool.onMouseDown = tools.mouseDown
        tool.onMouseUp = tools.mouseUp
        tool.onMouseDrag = tools.mouseDrag
        tool.activate()
      else
        tool = null
      initialized = true

    setup = (vm) ->
      element = vm.element
      image = vm.selectedImage
      canvas = element[0]
      initializeCanvas ->
        if initialized
          view.viewSize = new Size canvas.width, canvas.height
          view.zoom = 1
          view.update()
        else
          initPaper vm.tools
        drawRaster vm

    reset = ->
      initialized = false

    factory()

  angular.module('app.core')
    .factory 'diaPaperManager', diaPaperManager
