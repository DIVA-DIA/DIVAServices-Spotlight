do ->
  'use strict'

  polygonTool = ($sce, diaPaperManager) ->

    factory = ->
      initMouseEvents: initMouseEvents
      drawPath: drawPath
      setDescription: setDescription

    initMouseEvents = (vm) ->
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
                      vm.scope.$emit 'set-highlighter-status', true
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
              vm.scope.$emit 'set-highlighter-status', false
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
          diaPaperManager.set vm.path, 'rectangle'

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

    drawPath = (vm) ->
      vm.path = new Path
      vm.path.strokeColor = vm.strokeColor
      vm.path.strokeWidth = vm.strokeWidth
      vm.path.fillColor = vm.fillColor
      angular.forEach vm.selection.segments, (segment) ->
        x = segment[0]
        y = segment[1]
        @.add new Point x, y
      , vm.path
      vm.path.closed = true
      vm.path.fullySelected = true
      vm.path.scale vm.scale, [0, 0]
      vm.scope.$emit 'set-highlighter-status', true
      diaPaperManager.set vm.path, 'rectangle'

    setDescription = (vm) ->
      vm.description = $sce.trustAsHtml(
        """
        <p>Usage:</p>
        <p>- Click on image to add new points</p>
        <p>- Click and drag a point to move it</p>
        <p>- Click on the first point to close the polygon</p>
        <p>- Once the polygon is closed, you can move it by clicking and dragging on the inner part of it</p>
        <p>- Once the polygon is closed, you can add more points by clicking on its edges</p>
        <p>- Once the polygon is closed, you can remove it and draw a new one by clicking outside of the polygon</p>
        """
      )

    factory()

  angular.module('app.algorithm')
    .factory 'polygonTool', polygonTool

  polygonTool.$inject = [
    '$sce'
    'diaPaperManager'
  ]
