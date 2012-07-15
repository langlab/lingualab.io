
module 'App.Teacher', (exports,top)->

  class Model extends Backbone.Model

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

          a class:'btn btn-navbar', 'data-toggle':'collapse', 'data-target':'.nav-collapse', ->
            span class:'icon-beaker icon-large'
            span class:'icon-reorder icon-large'

          div class:'nav-collapse', ->
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
                    a href:'/logout', ->
                      i class:'icon-signout'
                      text " sign out"

    render: ->
      @$el.html ck.render @template, @model
      @


  class exports.Router extends top.App.Router

    initialize: ->
      @extendRoutesWith @teacherRoutes
      
      @teacher = new Model top.app.session.user
      @filez = new top.App.File.Collection @teacher.get 'files'

      @views =
        topBar: new Views.TopBar { model: @teacher }
        filez: new App.File.Views.Main { collection: @filez }

      @fromDB()
      @showTopBar()

    teacherRoutes:
      '/':'home'
      'files':'files'

    fromDB: ->
      @io = top.app.sock
      @io.on 'file:sync', (data)=>
        console.log 'file:sync',data
        @filez.fromDB(data)

    showTopBar: ->
      @views.topBar.render().open()

    home: ->
      console.log 'home route'
      @clearViews('topBar')
      
    files: ->
      console.log 'files route'
      @clearViews('topBar')
      @views.filez.render().open '.main'
      #@views.filez = new App.File.Views.List { collection: @teacher.files }
      #@views.filez.render().open '.main'

    extra: ->
      console.log 'get jiggy withit'