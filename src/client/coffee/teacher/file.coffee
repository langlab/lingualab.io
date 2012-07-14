
module 'App.File', (exports,top)->

  class Model extends Backbone.Model
    idAttribute: '_id'
    thumbBase: "http://s3.amazonaws.com/lingualabio-media"
    iconHash: {
      video: 'facetime-video'
      image: 'picture'
      pdf: 'file'
      audio: 'volume-up'
    }

    thumbnail: ->
      console.log @get('type'),@get('ext')
      @thumbnailUrl ?= do =>
        switch @get 'type'
          when 'video'
            "#{@thumbBase}/#{@id}_0001.png"
          when 'image'
            "#{@thumbBase}/#{@id}.#{@get 'ext'}"
          when 'audio'
            "/img/mp3.png"
          when 'application'
            if (@get('ext') is 'pdf') then "/img/pdf.png"
          else 'http://placehold.it/100x100'

    icon: ->
      if (@get('type') is 'application') then @iconHash[@get('ext')] else @iconHash[@get('type')]



  class Collection extends Backbone.Collection
    model: Model
    url: '/t/files'

    initialize: ->
      @fetch()

    comparator: ->
      moment(@get 'created').valueOf()

    filteredBy: (searchTerm)->
      @filter (m)->
        re = new RegExp searchTerm, 'i'
        re.test m.get('title')

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

      'keyup .search-query': (e)->
        clearTimeout @searchWait
        @searchWait = wait 200, => @currentList.doSearch($(e.target).val())

      'click .record-upload': 'openRecorder'


    initialize: ->
      @browser ?= new Views.Browser { collection: @collection }
      @list ?= new Views.List { collection: @collection }

      @currentList = @browser

      @collection.on 'reset', =>
        @renderList()

      # when ever an upload starts, get the task and make a progress view for it
      @collection.on 'upload:start', (task)=>
        task.view = new Views.UploadProgress { model: task }
        task.view.render().$el.prependTo @$el


    template: ->
          
      div class:'row files-top-bar', ->
        span class:'btn-toolbar span3', ->
          input class:'search-query span3', type:'text', placeholder:'search'
        span class:'btn-toolbar span9 pull-right', ->
          
          # for uploading
          span class:'btn-group pull-left span3',->
            a class:'btn tt', rel:'tooltip', 'data-original-title':"you can also add files by dragging them right onto the window!", ->
              i class:'icon-info'
              i class:'icon-hand-up'
            button class:'btn select-upload tt', rel:'tooltip', 'data-original-title': 'upload files from your computer', ->
              text "+ "
              i class:'icon-folder-open'
            button class:'btn internet-upload tt', rel:'tooltip', 'data-original-title':'find files on the internet to upload', ->
              text "+ "
              i class:'icon-cloud'
            button class:'btn record-upload tt', rel:'tooltip', 'data-original-title':'record and save some audio', ->
              text "+ "
              i class:"icon-comment"


          span class:'btn-group pull-right span2', 'data-toggle':'buttons-radio', ->
            button class:"btn toggle-list #{if @currentList is @browser then 'active' else ''}", ->
              i class:'icon-th'
            button class:"btn toggle-list #{if @currentList is @list then 'active' else ''}", ->
              i class:'icon-list'

          span class:'btn-group pull-right span4', 'data-toggle':'buttons-checkbox', ->
            button class:'btn', ->
              i class:'icon-facetime-video'
            button class:'btn', ->
              i class:'icon-volume-up'
            button class:'btn', "PDF"
              
            
              
      div class:'files-list', ->

    doSearch: ->
      console.log 'searching!!!'


    openRecorder: ->
      @recorder?.remove()
      @recorder ?= new Views.Recorder()
      @recorder.render().open()


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
      @$('.select-upload').browseElement().on 'change', (e)=>
        @collection.uploadFile(f) for f in e.target.files

      # fix the top search bar on scroll down
      @$('.files-top-bar').removeClass('navbar-fixed-top').waypoint (event,direction)=>
        if direction is 'down' then @$('.files-top-bar').hide().addClass('sticky').fadeIn()
        else @$('.files-top-bar').hide().removeClass('sticky').fadeIn()
      , { offset: 0 }

           
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


  class Views.Recorder extends Backbone.View
    tagName: 'div'
    className: 'modal popup-recorder'

    template: ->
      div class:'modal-header', ->
        h2 'Record and upload your voice'
      div class:'modal-body', ->
      div class:'modal-footer', ->
        button class:'btn', ->
          text ' Nevermind'
        button class:'btn btn-success', ->
          i class:'icon-upload'
          text ' Upload it!'


    render: ->
      super()
      @recorder ?= new App.Recording.Views.Recorder()
      @recorder.render().open @$('.modal-body')
      @$el.modal('show')
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

    doSearch: (@searchTerm)->
      @render()

    template: ->
      ul class:'thumbnails', ->
        
    addItem: (f)=>
      f.brItemView ?= new Views.BrowserItem { model: f }
      f.brItemView.render().open @$('ul.thumbnails')
      @

    render: ->
      @$el.html ck.render @template
      for f in (if @searchTerm then @collection.filteredBy(@searchTerm) else @collection.models)
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


    doSearch: (@searchTerm)->
      @render()

    template: ->
      table class:'table table-fluid span12', ->
        thead ->
        tbody ->
        tfoot ->
          

    addItem: (f)=>
      f.listItemView?.remove()
      f.listItemView ?= new Views.ListItem { model: f }
      f.listItemView.render().open @$('tbody')
      @
    
    render: ->
      @$el.html ck.render @template, @collection
      @addItem f for f in (if @searchTerm then @collection.filteredBy(@searchTerm) else @collection.models)

      upl = @collection.uploadFile
      input = @$('.select-upload').browseElement()
      input.on 'change', (e)->
        for f in e.target.files
          console.log 'uploading ',f
          upl f

      @delegateEvents()
      @




  # single items in a list
  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'file-list-item'

    events:
      'change .title': (e)->
        @model.save({ title: $(e.target).val() })

    template: ->
      td -> i class:"icon-#{@icon()} icon-large"
      td -> input class:'title', value:"#{ @get('title') }"
      td moment(@get('created')).format("MMM D h:mm:ss a")
      td -> input class:'tags', value:"#{ @get 'tags' }"

    render: ->
      @delegateEvents()
      super()

  # single icon items in the browser view
  class Views.BrowserItem extends Backbone.View
    tagName: 'li'
    className: 'browser-item span3'

    events:
      'change .title': (e)->
        @model.save({ title: $(e.target).val() })

    template: ->
      div class:"thumbnail #{@get 'type'}", ->
        img src:"#{@thumbnail()}"
        i class:"icon-#{@icon()} icon-large file-type-icon"
      div class:'item-info caption', ->
        input class:'title', value:"#{ @get('title') }"

    render: ->
      super()
      @delegateEvents()
      @


  class Views.Detail extends Backbone.View
    tagName: 'div'
    className: 'file-video-detail'

    template: ->
      video 
 

  [exports.Model,exports.Collection] = [Model, Collection]