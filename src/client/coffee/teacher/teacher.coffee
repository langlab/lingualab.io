
module 'App.Teacher', (exports,top)->
  
  class Model extends Backbone.Model
    initialize: ->
      @files = new App.File.Collection @get('files')

  exports.Views = Views = {}

  class Views.TopBar extends Backbone.View
    tagName: 'div'
    className: 'top-bar navbar navbar-fixed-top'

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
          ul class:'nav pull-right', ->
            li class:'divider-vertical'
            li class:'dropdown', ->
              a href:'', class:'dropdown-toggle', 'data-toggle':'dropdown', ->
                img src:"#{@get('twit').profileImageUrl}"
                text " #{@get('twit').name} "
                b class:'caret'
              ul class:'dropdown-menu', ->
                li class:'divider'
                li ->
                  a href:'/logout', "sign out"

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
      @clearViews('topBar')
      @files()
      
    files: ->
      @clearViews('topBar')
      @views.filez = new App.File.Views.List { collection: @teacher.files }
      @views.filez.render().open '.main'

    extra: ->
      console.log 'get jiggy withit'