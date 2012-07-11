CFG = require './config'
__baseDir = __dirname.replace '/src/server',''

express = require 'express'

store = new express.session.MemoryStore()
_ = require 'underscore'




mongooseAuth = require 'mongoose-auth'

app = express.createServer()

{mongoose} = app.db = require('./db')

app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session {
  secret: 'keyboardCat'
  key: 'express.sid'
  store: store
}

delete express.bodyParser.parse['multipart/form-data']

app.use express.bodyParser()
app.use mongooseAuth.middleware()
app.use express.static "#{__baseDir}/pub"
app.set 'views', "#{__baseDir}/src/client/views"
app.set 'view options', { layout: false }
app.set 'view engine', 'coffee'
app.register '.coffee', require('coffeekup').adapters.express
app.use express.errorHandler()


mongooseAuth.helpExpress(app)

app = require('./routes')(app)

# attach the session store onto the app
# for later reference
app.store = store

module.exports = app

  