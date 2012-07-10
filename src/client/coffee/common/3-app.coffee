# main app module

module 'App', (exports,top)->
  
  class Session extends Backbone.Model

  exports.Views = Views = {}

  # sample view
  class Views.Main extends Backbone.View
    className: 'main'
    tagName: 'div'

    template: ->
      div class:'hero-unit', ->
        h2 ->
          i class:'icon-beaker icon-large'
          text ' lingualab.io'
        a href:'/auth/twitter',class:'btn', ->
          i class:'icon-twitter'
          span ' sign in with twitter'

    render: ->
      @$el.html ck.render @template
      @




  class exports.Router extends Backbone.Router

    views:
      main: new App.Views.Main()

    clearViews: (exceptFor)->
      view.remove() for key,view of @views when key isnt exceptFor

    routes:
      '':'home'
      'timeline':'timeline'
      'timer':'timer'

    home: ->
      @clearViews()
      @views.main.render().open()

    timeline: ->
      @clearViews()

      @activity = new App.Activity.Model {
        duration: 600
        events: [
          { start: 10, pause: true, duration: 5 }
          { start: 30, pause: false, duration: 10}
        ]
      } 

      @views.tl = new App.Activity.Views.Timeline({model: @activity})
      @views.tl.render().open()

    timer: ->
      @clearViews()
      console.log 'route: timer'
      @t = new App.Activity.Timer()
      @t.addCues [
        { at: 4, fn: -> console.log 'hi 4' }
        { at: 10, fn: -> console.log 'hi 10' }
        { at: 4, fn: -> console.log 'hello 4'}
        { at: 11, fn: -> console.log 'yo yo'}
      ]

      throttledLog = _.throttle(((txt)-> console.log txt), 200, true)

      @t.on 'status', (data)-> 
        msg = "#{data.name} at #{data.secs}s"

      @v = new App.Activity.Views.Timer { model: @t }

      @v.render().open()




  



# kick it off
$ ->
  

  # if there is a signed-in user, 
  # wait for the next script to start the router

  app.router ?= if window.app.session.user?.role is 'teacher' then (new App.Teacher.Router()) else (new App.Router())

  Backbone.history.start()

