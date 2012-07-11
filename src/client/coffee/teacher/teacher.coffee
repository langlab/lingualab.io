
module 'App.Teacher', (exports,top)->
  
  class Model extends Backbone.Model
    initialize: ->
      @files = new App.File.Collection @get('files')

  exports.Views = Views = {}

  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'navbar navbar-fixed-top'

    template: ->
      div class:'navbar-inner', ->
        div class:'container', ->
          a class:'brand', href:'#', ->
            i class:'icon-beaker icon-large'
            span ' lingualab.io'
          ul class:'nav', ->
            li ->
              a href:'#files', ->
                i class:'icon-briefcase'
                text ' Files'
          span class:'pull-right', "#{@get('name')}"

    render: ->
      @$el.html ck.render @template, @model
      @


  class exports.Router extends top.App.Router
    initialize: ->
      @extendRoutesWith @teacherRoutes
      @teacher = new Model top.app.session.user
      @fromDB()
      @showTopBar()

    teacherRoutes:
      'files':'files'

    fromDB: ->
      @io = top.app.sock
      @io.on 'file:sync', (data)=>
        console.log 'file:sync',data
        console.log @teacher.files
        @teacher.files.fromDB(data)

    showTopBar: ->
      @views.topBar ?= new Views.TopBar { model: @teacher }
      @views.topBar.render().open()

    home: ->
      @clearViews()
      @showTopBar()
      
    files: ->
      @showTopBar()
      @views.filez = new App.File.Views.List { collection: @teacher.files }
      @views.filez.render().open '.main'

    extra: ->
      console.log 'get jiggy withit'