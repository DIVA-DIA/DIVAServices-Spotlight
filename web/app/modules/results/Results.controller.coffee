###
Controller ResultsPageController

* loads finished algorithms from diaProcessingQueue
* setups the diaDatatable directive
###
do ->
  'use strict'

  ResultsPageController = (diaProcessingQueue) ->
    vm = @
    vm.results = diaProcessingQueue.getResults()

    vm.tableOptions =
      data: vm.results
      iDisplayLength: 15,
      columns: [
        {
          class: 'details-control'
          orderable: false
          data: null
          defaultContent: ''
        }
        {
          data: 'algorithm.name'
          render: (data, type, row) ->
            if type is 'display'
              '<span class="text-capitalize">' + data + '</span>'
            else
              data
        }
        { data: 'algorithm.description' }
        {
          data: 'input.image'
          render: (data, type, row) ->
            if type is 'display'
              '<div class="project-members"><img src=\"' + data.thumbPath + '\"></div>'
            else
              data.thumbPath
        }
        { data: 'submit.start' }
        { data: 'submit.end' }
        { data: 'submit.duration' }
      ]
      order: [[5, 'dsc']]

    vm

  angular.module('app.results')
    .controller 'ResultsPageController', ResultsPageController

  ResultsPageController.$inject = [
    'diaProcessingQueue'
  ]
