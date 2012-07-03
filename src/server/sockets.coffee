
CFG = require './config'
{ User, Model, mongoose } = require './db'

_ = require 'underscore'
io = require 'socket.io'

module.exports = (app)->
  
  sio = io.listen app
  
  sio.set 'authorization', (data, accept)->
      # check if there's a cookie header
      #console.log data.headers
      if (data.headers.cookie)
          
          # if there is, parse the cookie
          cookieStr = _.find data.headers.cookie.split(';'), (i)-> /express\.sid/.test(i)
          ssid = unescape cookieStr?.split('=')[1]

          # note that you will need to use the same key to grad the
          # session id, as you specified in the Express setup.
          data.sessionId = ssid
          app.store.get ssid, (err,sess)->
            data.session = sess
            data.userId = sess?.user?._id

      else
         # if there isn't, turn down the connection with a message
         # and leave the function.
         return accept('No cookie transmitted.', false)
      # accept the incoming connection
      accept(null, true)

  sio.sockets.on 'connection', (socket)->
    # console.log 'session: ', socket.handshake.session
    
    socket.set 'userId', socket.handshake.userId
    
    # receive data from backbone sync and pass to mongoos object
    socket.on 'model', (data,cb)->
      Model.sync data, cb


  sio