###

for this boilerplate, you need:

  - express
  - socket.io
  - mongoose
  - mongooseAuth
  - coffeekup
  - underscore

###

CFG = require './server/config'

app = require './server/app'
sio = require('./server/sockets')(app)

app.listen CFG.PORT()

console.log "express web server listening on port #{ CFG.PORT() }"