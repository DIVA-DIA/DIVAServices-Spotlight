###
Directive diaSmartDropzone

* handles functionality for uploading images with Dropzone.js
* loads stored images from server (for active session) on page reload
* loads Dropzone settings from server
###
angular.module('app.images').directive 'diaSmartDropzone', [
  '$http'
  'diaSettings'
  'diaStateManager'
  'diaImagesService'
  'toastr'

  ($http, diaSettings, diaStateManager, diaImagesService, toastr) ->
    restrict: 'A'
    (scope, element, attrs) ->

      uploadedImages = []
      scope.safeApply ->
        dropzone = undefined

      diaSettings.fetch('dropzone').then (settings) ->
        max = (settings.maxFiles-1)
        availableIndexes = (index for index in [0..max])

        config =
          init: ->
            self = @
            # load images for active session if there are any
            diaImagesService.fetchUpload().then (res) ->
              scope.safeApply ->
                angular.forEach res.data, (image) ->
                  # add them as thumbnail
                  self.emit 'addedfile', image.mockFile
                  self.emit 'thumbnail', image.mockFile, image.thumbUrl
                  self.emit 'success', image.mockFile
                  # and handle index and maxFiles changes
                  index = availableIndexes.indexOf image.index
                  if index >= 0
                    availableIndexes.splice index, 1
                  self.options.maxFiles -= 1
          addRemoveLinks : settings.addRemoveLinks
          maxFilesize: settings.maxFilesize
          maxFiles: settings.maxFiles
          uploadMultiple: false
          acceptedFiles: 'image/*'
          dictDefaultMessage: '<span class="text-center"><span class="font-lg visible-xs-block visible-sm-block visible-lg-block"><span class="font-lg"><i class="fa fa-caret-right text-danger"></i> Drop files <span class="font-xs">to upload</span></span><span>&nbsp&nbsp<h4 class="display-inline"> (Or Click)</h4></span>'
          dictResponseError: 'Error uploading file!'

        eventHandlers =
          sending: (file, xhr, formData) ->
            scope.safeApply ->
              formData.append 'index', availableIndexes.shift()

          success: (file, res) ->
            if res
              # new uploaded image
              uploadedImages.push
                name: file.name
                serverName: res.serverName
                index: res.index
              image =
                src: res.url
                name: res.serverName
              @.emit 'thumbnail', file, res.thumbUrl + '?' + new Date().getTime()
            else
              # image was loaded from server after page refresh
              image =
                src: file.src
                name: file.name
            $(file.previewElement).on 'click', (event) ->
              diaStateManager.reset()
              diaStateManager.switchState 'cropping', image

          removedfile: (file) ->
            removeImage = null

            angular.forEach uploadedImages, (image) ->
              if image.name is file.name
                removeImage = image
                availableIndexes.push (parseInt image.index)

            # its an existing image loaded from the server
            if not removeImage? and not (file.status is 'error')
              removeImage = {}
              removeImage.serverName = file.name
              availableIndexes.push (parseInt file.index)

            if removeImage?
              diaImagesService.delete(removeImage.serverName).then (res) ->
                if res.status isnt 200
                  toastr.warning 'There was an error while removing this image on the server. Please reload the page and try again', 'Warning'
                else
                  dropzone.options.maxFiles += 1

        # create a Dropzone for the element with the given options
        dropzone = new Dropzone(element[0], config)

        # bind the given event handlers
        angular.forEach eventHandlers, (handler, event) ->
          dropzone.on event, handler
          return

        return
]