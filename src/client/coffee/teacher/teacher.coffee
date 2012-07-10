
module 'App.Teacher', (exports,top)->

  console.log 'top',top
  
  class Model extends Backbone.Model

  exports.Views = Views = {}


  class Views.TopBar extends Backbone.Views
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
                i class:'icon-folder'
                text ' Files'


  class exports.Router extends top.App.Router
    initialize: ->
      @extendRoutesWith @teacherRoutes

    teacherRoutes:
      'files':'files'


    home: ->
      @clearViews()


    files: ->
      @views.filez = new App.File.Views.List {collection: app.session.user.files}
      @views.render().open()

    extra: ->
      console.log 'get jiggy withit'