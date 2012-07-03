CFG = require './config'
stylus = require 'stylus'

__baseDir = __dirname.replace '/src/server',''

# sets the routes on the app, then returns

module.exports = (app)->
  app.get '/', (req,res)->
    req.session.user = req.user
    res.render 'index', {session: req.session, CFG: CFG}

  app.get '/favicon.ico', (req,res)->
    res.sendfile "#{__baseDir}/pub/img/favicon.ico"

  app.get '/ck.js', (req,res)->
    res.sendfile "#{__baseDir}/src/node_modules/coffeekup/lib/coffeekup.js"

  app.get '/github/callback', (req,res)->
    res.redirect '/'

  app.get '/twitter/callback', (req,res)->
    res.redirect '/'

  app
