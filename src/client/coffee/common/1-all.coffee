
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

Backbone.Model::connectSocket = Backbone.Collection::connectSocket = Backbone.View::connectSocket = ->
  @io ?= window.app.sock

Backbone.View::open = (cont = 'body')->
  @$el.appendTo cont
  @trigger 'open', cont
  @

# to create modules/namespaces

module = (target, name, block) ->
  [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
  top    = target
  target = target[item] or= {} for item in name.split '.'
  block target, top




module 'UI', (exports,top)->
  
  class Slider extends Backbone.View
    tagName: 'div'
    className: 'slider-cont'

    initialize: ->
      _.defaults @options, {
        min: 0
        max: 100
        handleWidthPerc: 0   #if 0, width will default to height of the groove
      }

    template: ->
      div class:'slider-groove', -> div class:'slider-handle'

    render: ->
      @$el.html ck.render @template
      @on 'open', ->
        @groove = @$('.slider-groove')
        @handle = @$('.slider-handle')
        @setHandleWidthPerc (@options.handleWidthPerc*@grooveW()/100)
      @

    events:
      'mousedown':'startDrag'
      'mouseup':'stopDrag'
      'mousemove':'drag'

    handleW: ->
      @handle.width()

    handleX: ->
      @handle.position().left


    getVal: ->
      @options.min + (@handleX() / @grooveW()) * (@options.max - @options.min)

    setVal: (v)->
      @setSliderX ((v - @options.min)/(@options.max-@options.min) * @grooveW())
      @

    grooveW: ->
      @groove.width() - @handleW()

    setHandleWidthPerc: (perc)->
      @handle.width (perc*@grooveW()/100) or 8

    setSliderX: (x)->
      # console.log @handleW(), @grooveW(), x
      x = x - (@handleW()/2)
      x = if x < 0 then 0 else if x > @grooveW() then @grooveW() else x
      @$('.slider-handle').css 'left', x

      @trigger 'change', @getVal()
      @

    startDrag: (e)->
      targetOffsetX = if $(e.target).hasClass('slider-handle') then @handleX() else 0
      newX = e.offsetX + targetOffsetX
      @setSliderX newX
      @dragging = true
      @

    stopDrag: (e)->
      @dragging = false
      @

    drag: (e)->
      targetOffsetX = if $(e.target).hasClass('slider-handle') then @handleX() else 0
      newX = e.offsetX + targetOffsetX
      if @dragging then @setSliderX newX
      @

  exports.Slider = Slider




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






