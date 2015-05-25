angular.module('app.algorithm').factory 'diaAlgorithmService', [
  '$http'

  ($http) ->

    fetch: (id) ->
      $http.get('/api/algorithm', params:
        id: id).then (res) ->
          res

    fetchImages: ->
      $http.get('/upload').then (res) ->
        angular.forEach res.data, (image) ->
          image.thumbUrl = image.thumbUrl + '?' + new Date().getTime()
          image.url = image.url + '?' + new Date().getTime()
        res

    checkCaptcha: (params) ->
      data = {}
      data[params.name] = params.value
      name: data.value
      $http.post('/captcha/try/', data).then (res) ->
        res
]
