

CFG = require './server/config'
numCPUs = require('os').cpus().length

app = require './server/app'
sio = require('./server/sockets')(app)


app.listen CFG.PORT()


console.log "listening on port #{ CFG.PORT() }"