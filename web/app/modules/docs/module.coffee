module = angular.module 'app.docs', [
  'ui.router'
]

module.config [
  '$stateProvider'

  ($stateProvider) ->
    $stateProvider.state 'docs',
      parent: 'main'
      abstract: true
      url: '/docs'
      data:
        title: 'Documents'

    $stateProvider.state 'docs.architecture',
      parent: 'main'
      url: '/docs/architecture'
      templateUrl: 'modules/docs/views/architecture.html'
      controller: 'ArchitecturePageController'
      data:
        title: 'Architecture'

    $stateProvider.state 'docs.api',
      parent: 'main'
      url: '/docs/api'
      templateUrl: 'modules/docs/views/api.html'
      controller: 'ApiPageController'
      data:
        title: 'API Documentation'
]
