
module 'App.File', (exports,top)->

  class Model extends Backbone.Model
    idAttribute: '_id'
    thumbBase: "http://s3.amazonaws.com/lingualabio-media"
    iconHash: {
      video: 'facetime-video'
      image: 'picture'
    }

    thumbnail: ->
      @thumbnailUrl ?= do =>
        switch @get 'type'
          when 'video'
            "#{@thumbBase}/#{@id}_0001.png"
          when 'image'
            "#{@thumbBase}/#{@id}.#{@get 'ext'}"
          else 'http://placehold.it/100x100'

    icon: ->
      @iconHash[@get('type')]



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
      
      onProgress = (e)->
        uplTask.trigger 'progress', perc = Math.round((e.position / e.total) * 100)

      onSuccess = -> uplTask.trigger 'complete'
      
      # start an upload
      uplTask = $.upload "/upload", file, {upload: {progress: onProgress}, success: onSuccess}
      
      _.extend uplTask, Backbone.Events
      console.log 'upl task', uplTask

      # tack the file info onto the upload task itself
      uplTask.file = file 
      
      # trigger out the task so that event handlers can be attached by whatever cares
      @trigger 'upload:start', uplTask

  exports.Views = Views = {}

  # view with dragover functionality to inherit from
  class Views.DragOver extends Backbone.View

    dragOver: (e)->
      e.originalEvent.dataTransfer.dropEffect = "copy"
      e.stopPropagation()
      e.preventDefault()
      false

    dragEnter: (e)->
      console.log 'dragenter',$(e.target)
      e.stopPropagation()
      e.preventDefault()
      false

    dragLeave: (e)->
      console.log 'dragleave', $(e.target)
      e.stopPropagation()
      e.preventDefault()
      false
        
    drop: (e)->
      e.stopPropagation()
      e.preventDefault()
      files = e.originalEvent.dataTransfer.files
      i = 0
      for f in files
        console.log 'uploading ',f
        @collection.uploadFile f
      return false


  # main file view, controls other list/browse sub-views
  class Views.Main extends Views.DragOver
    tagName: 'div'
    className: 'files-main'

    events:
      'click .toggle-list':'toggleList'
      'dragenter': 'dragEnter'
      #'dragover': 'dragOver'
      'dragleave': 'dragLeave'
      'drop': 'drop'

      'keyup search-query':'doSearch'



    initialize: ->
      @browser ?= new Views.Browser { collection: @collection }
      @list ?= new Views.List { collection: @collection }

      @currentList = @list

      @collection.on 'reset', =>
        @renderList()

      # when ever an upload starts, get the task and make a progress view for it
      @collection.on 'upload:start', (task)=>
        task.view = new Views.UploadProgress { model: task }
        task.view.render().$el.prependTo @$el
        

    template: ->
          
      div class:'row', ->
        span class:'btn-toolbar span3', ->
          input class:'search-query span3', type:'text', placeholder:'search'
        span class:'btn-toolbar span9 pull-right', ->
          
          
          span classs:'btn-loose-group pull-left',->    
            a class:'btn tt', rel:'tooltip', 'data-original-title':"you can also add files by dragging them right onto the window!", ->
              i class:'icon-info'
              i class:'icon-hand-up'
            button class:'btn select-upload tt', rel:'tooltip', 'data-original-title': 'upload files from your computer', ->
              text "+ "
              i class:'icon-folder-open'
            button class:'btn internet-upload tt', rel:'tooltip', 'data-original-title':'find files on the internet to upload', ->
              text "+ "
              i class:'icon-cloud'

          span class:'btn-group pull-right', 'data-toggle':'buttons-radio', ->
            button class:"btn toggle-list #{if @currentList is @browser then 'active' else ''}", ->
              i class:'icon-th'
            button class:"btn toggle-list #{if @currentList is @list then 'active' else ''}", ->
              i class:'icon-list'
              
            
              
      div class:'files-list', ->

    doSearch: ->


    toggleList: ->
      console.log 'toggle-list'
      @currentList.remove()
      @currentList = if @currentList is @browser then @list else @browser
      @renderList()

    renderList: ->
      @currentList.remove()
      @currentList.render().open @$('.files-list')

    render: ->
      @$el.html ck.render @template, @
      @renderList()
      @$('.tt').tooltip()
      @delegateEvents()
      @

  # view to show the progress of an upload
  # suppose to go away when finished
  class Views.UploadProgress extends Backbone.View
    tagName: 'div'
    className: 'uplaod-progress row'

    initialize: ->
      console.log 'new upl task model: ',@model

      @model.on 'progress', (perc)=>
        @setPercentTo perc
        if perc is 100 then @remove()

      @model.on 'success', => @remove()

    template: ->
      span class:'span2 pull-left', "#{@name}"
      span class:'span9 pull-right', ->
        div class:'progress upload-progress', ->
          div class:'bar'

    setPercentTo: (p)->
      @$('.bar').width "#{p}%"
      @

  # icon-browser sub-view
  class Views.Browser extends Backbone.View
    tagName: 'div'
    className: 'file-browser'

    initialize: ->
      @collection.on 'add', @addItem
      @collection.on 'change', (f)->
        f.brItemView.render()

      @collection.on 'reset', => @render()


    template: ->
      ul class:'thumbnails', ->
        
    addItem: (f)=>
      f.brItemView ?= new Views.BrowserItem { model: f }
      f.brItemView.render().open @$('ul.thumbnails')
      @

    render: ->
      @$el.html ck.render @template
      for f in @collection.models
        @addItem f
      @

  # list sub-view
  class Views.List extends Backbone.View
    tagName: 'div'
    className: 'container file-list'

    initialize: ->
      @collection.on 'add', @addItem
      @collection.on 'change', (f)->
        f.listItemView.render()

      @collection.on 'reset', => @render()


    template: ->
      table class:'table table-fluid span12', ->
        thead ->
        tbody ->
        tfoot ->
          

    addItem: (f)=>
      f.listItemView ?= new Views.ListItem { model: f }
      f.listItemView.render().open @$('tbody')
      @
    
    render: ->
      console.log @collection
      @$el.html ck.render @template, @collection
      @addItem f for f in @collection.models

      upl = @collection.uploadFile
      input = @$('.select-upload').browseElement()
      input.on 'change', (e)->
        for f in e.target.files
          console.log 'uploading ',f
          upl f

      @delegateEvents()
      @


  # just the thumbnail part of the view
  class Views.Thumnbail extends Backbone.View
    tagName: 'span'
    className: 'file-icon'

    template: ->
      img src:"#{@thumbnail()}"

  # single items in a list
  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'file-list-item'

    template: ->
      td @get('title')
      td @get('status')
      td moment(@get('created')).format("MMM D h:mm:ss a")
      td @get('localPath')

  # single icon items in the browser view
  class Views.BrowserItem extends Backbone.View
    tagName: 'li'
    className: 'browser-item span3'

    template: ->
      div class:'thumbnail', ->
        img src:"#{@thumbnail()}"
        div class:'item-info caption', ->
          h5 ->
            i class:"icon-#{@icon()}"
            text " #{ @get('title') }"


 

  [exports.Model,exports.Collection] = [Model, Collection]