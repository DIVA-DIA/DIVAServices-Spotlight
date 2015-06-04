###
Controller AlgorithmsPageController

* displays information about all available algorithms
* handles socket.io messages if any algorithms have changed
###
do ->
  'use strict'

  AlgorithmsPageController = ($scope, $state, diaSocket, diaSettings, diaAlgorithmsService, toastr) ->
    vm = @
    vm.algorithms = []

    retrieveAlgorithms = ->
      diaAlgorithmsService.fetch().then (res) ->
        vm.algorithms = res.data
      , (err) -> toastr.error err.statusText, 'Request failed'

    retrieveAlgorithms()

    # switch to algorithm page for this algorithm
    vm.thisAlgorithm = (algorithm) ->
      $state.go 'algorithm', {id: algorithm._id}

    diaSettings.fetch('socket').then (socket) ->
      if socket.run?
        $scope.$on 'socket:update algorithms', (ev, algorithms) ->
          angular.forEach algorithms, (algorithm) ->
            available = false
            angular.forEach vm.algorithms, (scopeAlgorithm, index) ->
              if algorithm.url is scopeAlgorithm.url
                vm.algorithms[index] = algorithm
          toastr.info 'Algorithms have changed', 'Updated'

        $scope.$on 'socket:add algorithms', (ev, algorithms) ->
          angular.forEach algorithms, (algorithm) ->
            vm.algorithms.push algorithm
          toastr.info 'Added new algorithms', 'Added'

        $scope.$on 'socket:delete algorithms', (ev, algorithms) ->
          angular.forEach algorithms, (algorithm) ->
            angular.forEach vm.algorithms, (scopeAlgorithm, index) ->
              if algorithm.url is scopeAlgorithm.url
                vm.algorithms.splice index, 1
          toastr.info 'Deleted one or more algorithms', 'Delete'

        $scope.$on 'socket:error', (ev, data) ->
          toastr.error 'There was an error while fetching algorithms', 'Error'

  AlgorithmsPageController.$inject = ['$scope','$state', 'diaSocket', 'diaSettings', 'diaAlgorithmsService', 'toastr']
  angular.module('app.algorithms')
    .controller 'AlgorithmsPageController', AlgorithmsPageController
