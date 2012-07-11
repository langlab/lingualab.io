
module 'App.File', (exports,top)->

  class Model extends Backbone.Model
    idAttribute: '_id'

  class Collection extends Backbone.Collection
    model: Model
    url: '/t/files'

    initialize: ->
      @fetch()

    comparator: ->
      0 - @get 'created'

    fromDB: (data)->
      {method, model, options} = data
      console.log 'updating ',model
      switch method
        when 'create'
          @add model
        when 'status'
          @get(model._id).set(model)
    
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
    className: 'row file-browser'
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


  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'file-list-item'

    template: ->
      console.log @
      td @get('title')
      td @get('status')
      td moment(@get('created')).format("MMM D h:mm:ss a")
      td @get('localPath')




  class Views.List extends Views.DragOver
    tagName: 'div'
    className: 'container file-list'
    # id: 'file-list'

    initialize: ->
      @collection.on 'add', @addItem
      @collection.on 'change', (f)->
        f.listItemView.render()

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
            th ''
            th 'uploaded'
            th 'description here...'
        
          tr class:'upload-place-holder', ->
            td colspan:'4', 'drop to upload your file'
        tbody ->
        tfoot ->
          tr ->
            td colspan:'4', ->
              form action:'/upload', method:'post', enctype:"multipart/form-data", ->
                input type:'text', name: 'title'
                input type:'file', name:'upload'
                input type:'submit', value:'upload'

    addItem: (f)=>
      f.listItemView ?= new Views.ListItem { model: f }
      f.listItemView.render().open @$('tbody')
      @
    
    render: ->
      console.log @collection
      @$el.html ck.render @template, @collection

      @addItem f for f in @collection.models

      @delegateEvents()
      @

  [exports.Model,exports.Collection] = [Model, Collection]