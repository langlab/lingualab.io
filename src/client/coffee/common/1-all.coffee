
# shared functions and variables

w = window
w.ck = CoffeeKup

# make setTimeout and setInterval less awkward
# by switching the parameters!!

w.wait = (someTime,thenDo) ->
  setTimeout thenDo, someTime
w.doEvery = (someTime,action)->
  setInterval action, someTime


# include the socket connection in every Model and View

Backbone.Model::io = Backbone.Collection::io = Backbone.View::io = ->
  window.app.sock

Backbone.View::open = (cont = 'body')->
  @$el.appendTo cont
  @trigger 'open', cont
  @

Backbone.View::render = ->
  @$el.html ck.render @template, @model ? @collection ? @
  @

Backbone.Router::extendRoutesWith = (xtraRoutes)->
  for name,route of xtraRoutes
    if _.isFunction route
      @route name, name, route
    else
      @route name, route

# to create modules/namespaces

window.module = (target, name, block) ->
  [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
  top    = target
  target = target[item] or= {} for item in name.split '.'
  block target, top


# custom jquery plugins
# used in this app

do ($=jQuery)->

  $.fn.center = ->
    @css "position", "absolute"
    @css "top", Math.max(0, (($(window).height() - @outerHeight()) / 2) + $(window).scrollTop()) + "px"
    @css "left", Math.max(0, (($(window).width() - @outerWidth()) / 2) + $(window).scrollLeft()) + "px"
    @


do ($=jQuery)->

  $.fn.slider = (method)->
    @methods = {

      init: (options={})->
        options.min ?= 0
        options.max ?= 100

        handle = $('<div/>').addClass('slider-handle')
        groove = $('<div/>').addClass('slider-groove')

        root = $(@).addClass('slider-cont') 
        handle.appendTo groove
        groove.appendTo root

        ###
        handle.draggable {
          containment: groove
          axis: 'x'
        }
        ###

        root.on 'mousedown', (e)=>
          @setHandleX e.offsetX
          @data 'dragging', true

        root.on 'mouseover', (e)=>
          @data 'dragging', false

        root.on 'mousemove', (e)=>
          @setHandleX e.offsetX


      setHandleX: (x)=>
        handle.css 'left', x - (handle.width()*0.5)


      update: ->
        console.log 'move:',newpx = (@data('v')-@options.min)/(@options.max-@options.min)
        $(@).find('.slider-handle').css 'left', newpx
        @

      val: (v)->
        console.log @data('v'),v
        if v?
          @data('v',v)
          @update
          @
        else @data('v')
    }

    if @methods[method]
      @methods[method].apply this, Array::slice.call(arguments, 1)
    else if typeof method is "object" or not @method
      @methods.init.apply this, arguments
    else
      $.error "Method " + @method + " does not exist"






