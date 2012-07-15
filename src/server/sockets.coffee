# standalone socket server
# connects to mongo db
# auths through mongo session store

CFG = require './config'

{ mongoose, User, File } = require './db'

_ = require 'underscore'
io = require 'socket.io'

# the socket session store
MongoStore = require 'socket.io-mongo'

# get a connection to the express session store
ExpMongoStore = require('connect-mongo')(require 'express')
ss = new ExpMongoStore {
  db: 'lingualab'
}

sio = io.listen CFG.SIO.PORT

sio.configure ->
  iostore = new MongoStore {url: "mongodb://#{CFG.DB.HOST}:#{CFG.DB.PORT}/#{CFG.DB.NAME}"}
  iostore.on 'error', console.error
  sio.set 'store', iostore

sio.set 'authorization', (data, accept)->
    # check if there's a cookie header
    if (data.headers.cookie)
        
        # if there is, parse the cookie
        cookieStr = _.find data.headers.cookie.split(';'), (i)-> /express\.sid/.test(i)
        ssid = unescape cookieStr?.split('=')[1]

        # note that you will need to use the same key to grad the
        # session id, as you specified in the Express setup.
        data.sessionId = ssid
        ss.get ssid, (err,sess)-> 
          User.findById sess?.auth?.userId, (err,user)->
            data.user = user
            data.userId = user?._id
            console.log 'user access: ', user?._id

    else
       # if there isn't, turn down the connection with a message
       # and leave the function.
       return accept('No cookie transmitted.', false)
    # accept the incoming connection
    accept(null, true)

sio.sockets.on 'connection', (socket)->
  # console.log 'session: ', socket.handshake.session
  
  socket.set 'userId', socket.handshake.userId

  # each client joins own private room (handles access via multiple clients simultaneously)
  socket.join socket.handshake.userId

  # all clients join the sys channel for universal announcements
  socket.join 'sys'
  
  # receive data from backbone sync and pass to mongoose objects
  socket.on 'file', (data,cb)->
    File.sync data, this, cb

  # send back the handshake info
  socket.on 'handshake', (cb)-> cb socket.handshake


File.socketSetup(sio)

