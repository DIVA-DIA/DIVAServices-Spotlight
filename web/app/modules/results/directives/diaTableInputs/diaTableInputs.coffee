angular.module('app.results').directive 'diaTableInputs', [
  '$timeout'

  ($timeout) ->
    restrict: 'A'
    scope:
      inputData: '='
    templateUrl: 'modules/results/directives/diaTableInputs/template.html'

    link: (scope, element, attrs) ->
      canvas = path = null
      strokeColor = 'red'
      strokeWidth = null
      scope.highlighter = scope.inputData?.input.highlighter
      scope.inputs = scope.inputData?.input.inputs
      scope.image = scope.inputData?.image

      initializeCanvas = (callback) ->
        img = new Image
        img.src = scope.image.path
        $(img).bind 'load', ->
          width = $('.table-inputs')[0].clientWidth
          height = img.height * (width/img.width)
          canvas.width = width
          canvas.height = height
          callback()

      drawPath = (callback) ->
        path = new Path
        path.strokeColor = strokeColor
        path.strokeWidth = scope.highlighter.strokeWidth
        angular.forEach scope.highlighter.segments, (segment) ->
          @.add new Point segment[0], segment[1]
        , path
        path.closed = true
        callback()

      asyncLoadCanvas = ->
        canvas = element.find('#input-canvas')
        if canvas.length
          paper.clear()
          canvas = canvas[0]
          initializeCanvas ->
            paper.install window
            paper.setup canvas
            if project.layers[0]?
              project.layers[0].removeChildren()
            raster = new Raster
              source: scope.image.path
              position: view.center
            raster.on 'load', ->
              scale = view.size.width / @.bounds.width
              drawPath ->
                view.zoom = scale
                view.update()


      # wait for elements to be loaded in dom
      $timeout asyncLoadCanvas

]
