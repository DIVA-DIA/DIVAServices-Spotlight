###
Factory diaHighlighterManager

* keeps an internal state about currently selected highlighter
* exposes get method which prepares information about currently
  selected highlighter to be sent to server
###
angular.module('app.algorithm').factory 'diaHighlighterManager', [

  ->
    highlighterManager =
      type: null
      path: null

    highlighterManager.reset = ->
      @type = null
      @path = null

    # we want to send only certain information to server
    highlighterManager.get = ->
      if @path?.view?
        highlighter =
          strokeWidth: @path.strokeWidth
          strokeColor: @path.strokeColor
          position: @path.position
          scaling: @path.view.zoom
          closed: @path.closed
          pivot: @path.pivot
          segments: []
        inverse = 1 / highlighter.scaling
        angular.forEach @path.segments, (segment) ->
          x = segment.point.x * inverse
          y = segment.point.y * inverse
          @.push [x, y]
        , highlighter.segments
        highlighter
      else
        {}

    highlighterManager
]
