do ->
  'use strict'

  DiaAlgorithmPolygonController = ($scope, diaPaperManager) ->
    vm = @
    vm.element = null
    vm.handle = null
    vm.path = null
    vm.segmentIndex = null
    vm.strokeWidth = null
    vm.strokeColor = 'red'
    vm.fillColor = new paper.Color 1, 0, 0, 0.1
    vm.tools = null

    @init = (element) ->
      vm.element = element

      # tell diaPaperManager to re-initialize paperJS. This is executed
      # everytime the algorithm changes (but not when selectedImage changes)
      diaPaperManager.reset()

      # init mouse event handlers
      setupMouseEvents()

      # update paper settings if selectedImage has changed
      $scope.$parent.$watch 'vm.selectedImage', ->
        if vm.path
          vm.path.remove()
        vm.path = null
        vm.setHighlighterStatus status: true
        diaPaperManager.setup vm

    setupMouseEvents = ->

      vm.tools =
        mouseDown: (event) ->
          vm.handle = null
          point = event.point
          if vm.path
            hitResult = vm.path.hitTest point,
              segments: true
              fill: true
              stroke: true
              tolerance: 10
            if hitResult
              switch hitResult.type
                when 'segment'
                  if (hitResult.segment.index is 0)
                    if vm.path.closed
                      vm.handle = hitResult.type
                      vm.segmentIndex = hitResult.segment.index
                    else
                      vm.path.closed = true
                      vm.path.fillColor = vm.fillColor
                      vm.setHighlighterStatus status: false
                  else
                    vm.handle = hitResult.type
                    vm.segmentIndex = hitResult.segment.index
                when 'fill' then vm.handle = hitResult.type
                when 'stroke'
                  if vm.path.closed then vm.path.insert hitResult.location.index + 1, point
                else null
            else if vm.path.closed
              vm.path.remove()
              vm.path = null
              diaPaperManager.resetPath()
              vm.setHighlighterStatus status: true
          else
            diaPaperManager.resetPath()

        mouseUp: (event) ->
          point = event.point
          unless vm.path
            vm.path = new Path()
            vm.path.strokeColor = vm.strokeColor
            vm.path.strokeWidth = vm.strokeWidth
            vm.path.fullySelected = true
          if not vm.path.closed and vm.handle isnt 'segment'
            vm.path.add point
          vm.segmentIndex = null
          diaPaperManager.set vm.path

        mouseDrag: (event) ->
          x = event.delta.x
          y = event.delta.y
          switch vm.handle
            when 'fill'
              # can only be true once the path is closed
              angular.forEach vm.path.segments, (segment) ->
                segment.point.x += x
                segment.point.y += y
            when 'segment'
              # can only be true once the path is closed
              vm.path.segments[vm.segmentIndex].point.x += x
              vm.path.segments[vm.segmentIndex].point.y += y

  angular.module('app.algorithm')
    .controller 'DiaAlgorithmPolygonController', DiaAlgorithmPolygonController

  DiaAlgorithmPolygonController.$inject = [
    '$scope'
    'diaPaperManager'
  ]
