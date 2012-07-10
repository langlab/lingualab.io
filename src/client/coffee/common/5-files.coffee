
module 'App.File', (exports,top)->

  class Model extends Backbone.Model

  class Collection extends Backbone.Collection
    model: Model
    url: '/t/files'

    initialize: ->
      @fetch()
    
    uploadFile: (file) ->
      
      onProgress = (e) ->
        per = Math.round((e.position / e.total) * 100)
        console.log 'progress: '+per

      onSuccess = ->
        console.log 'upload complete'

      $.upload "/upload", file, {upload: {progress: onProgress}, success: onSuccess}

  exports.Views = Views = {}

  class Views.DragOver extends Backbone.View

    dragOver: (e)->
      @$('.upload-place-holder').show()
      e.originalEvent.dataTransfer.dropEffect = "copy"
      e.stopPropagation()
      e.preventDefault()
      false

    dragEnter: (e)->
      console.log 'dragenter',$(e.target)
      if $(e.target).hasClass('fileList')
        @$('.upload-place-holder').show()
        e.stopPropagation()
        e.preventDefault()
      false

    dragLeave: (e)->
      console.log 'dragleave', $(e.target)
      if $(e.target).hasClass('fileList')
        @$('.upload-place-holder').hide()
        e.stopPropagation()
        e.preventDefault()
      false
        
    drop: (e)->
      e.stopPropagation()
      e.preventDefault()
      @$('.upload-place-holder').hide()
      files = e.originalEvent.dataTransfer.files
      i = 0
      for f in files
        console.log 'uploading ',f
        @collection.uploadFile f
      return false

  class Views.Browser extends Views.DragOver
    tagName: 'div'
    className: 'row'
    template: ->
      ul class:'thumbnails', ->
        for f in @files.models
          li class:'span3', ->
            a class:'thumbnail', ->
              img src:'http://placehold.it/600x400'
              h5 "#{ f.get('title') }"
              p "#{ f.get('localPath') }"

    render: ->
      @$el.html ck.render @template, {files: @collection}
      @

  class Views.List extends Views.DragOver
    tagName: 'div'
    className: 'fileList'
    id: 'fileList'

    initialize: ->
      @collection.on 'add', (f)->
        console.log 'added file: ',f

      @collection.on 'reset', => @render()
      

    events:
      'click': (e)-> console.log 'click'
      'dragenter table': 'dragEnter'
      #'dragover table': 'dragOver'
      'dragleave table': 'dragLeave'
      'drop table': 'drop'

    template: ->
      table class:'table', ->
        thead ->
          tr ->
            th 'Title'
            th 'uploaded'
            th 'description here...'
        tbody ->
          tr class:'upload-place-holder', ->
            td colspan:'3', 'drop to upload your file'
          for f in @files.models
            console.log f
            tr ->
              td f.get('title')
              td moment(f.get('created')).format("MMM D h:mm:ss a")
              td f.get('localPath')
          tr ->
            td colspan:'3', ->
              form action:'/upload', method:'post', enctype:"multipart/form-data", ->
                input type:'text', name: 'title'
                input type:'file', name:'upload'
                input type:'submit', value:'upload'
    
    render: ->
      @$el.html ck.render @template, {files: @collection}
      @delegateEvents()
      @

  [exports.Model, exports.Collection] = [Model,Collection]

