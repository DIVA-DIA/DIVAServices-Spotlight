###
Directive diaBootstrapSlider

* handles slider elements on filter page
###
do ->
  'use strict'

  diaBootstrapSlider = ->

    directive = ->
      restrict: 'A'
      link: link

    link = (scope, element, attrs) ->
      scope.value = attrs.sliderValue
      element.removeAttr 'dia-bootstrap-slider data-dia-bootstrap-slider'

      attrs.$observe 'sliderMin', (value) ->
        element.slider
          tooltip: 'hide'
        $(element.data('slider').sliderElem).prepend attrs

      scope.reset = (filter) ->
        scope.safeApply ->
          defaultValue = scope.filters[filter].default
          scope.value = defaultValue
          element.slider 'setValue', defaultValue, true, true
          scope.filter filter, defaultValue

      $(element).on 'slideStop', (event) ->
        scope.safeApply -> scope.value = event.value
        scope.filter attrs.targetFilter, event.value

    directive()

  angular.module('app.images')
    .directive 'diaBootstrapSlider', diaBootstrapSlider
