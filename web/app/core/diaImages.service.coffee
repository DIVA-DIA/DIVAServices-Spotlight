do ->
  'use strict'

  diaImagesService = ($http, toastr) ->

    factory = ->
      fetch: fetch
      put: updateImage
      delete: deleteImage

    fetch = ->
      $http.get('/upload').then (res) ->
        angular.forEach res.data, (image) ->
          # add date to image urls so angularJS triggers change
          image.url = image.url + '?' + new Date().getTime()
          image.thumbUrl = image.thumbUrl + '?' + new Date().getTime()
        res

    updateImage = (file, name) ->
      if not name
        name = 'undefined.png'
        index = 0
      else
        values = name.split('_')
        index = values[values.length-1].split('.')[0]
      data =
        transformRequest: angular.identity
        headers:
          'Content-Type': undefined
          'X-Requested-With': 'XMLHttpRequest'
      formData = new FormData
      formData.append('filename', name)
      formData.append('file', file)
      formData.append('processType', 'crop')
      formData.append('index', index)
      $http.put('/upload', formData, data).then (res) ->
        res

    deleteImage = (serverName) ->
      $http.delete('/upload', params: serverName: serverName).then (res) ->
        res

    factory()

  angular.module('app.core')
    .factory 'diaImagesService', diaImagesService

  diaImagesService.$inject = [
    '$http'
    'toastr'
  ]
