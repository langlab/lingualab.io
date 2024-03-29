CFG = require './config'
stylus = require 'stylus'

__baseDir = __dirname.replace '/src/server',''

# sets the routes on the app, then returns

userAuth = (req,res,nxt)->
  if req.session.auth?.loggedIn
    nxt()
  else
    res.redirect '/'

module.exports = (app)->

  {File, User} = require './db'

  app.get '/', (req,res)->
    if req.user?
      req.user.getFiles (err,files)->
        req.user.files = files
        req.session.user = req.user
        res.render 'index', {session: req.session, user: req.user, CFG: CFG}
    else
      res.render 'index', {session: req.session, CFG: CFG}

  app.get '/favicon.ico', (req,res)->
    res.sendfile "#{__baseDir}/pub/img/favicon.ico"

  app.get '/ck.js', (req,res)->
    res.sendfile "#{__baseDir}/src/node_modules/coffeekup/lib/coffeekup.js"
  
  app.get '/twitter/return', (req, res)->
    res.redirect '/'


  app.post '/upload', userAuth, (req,res)->
    console.log 'upload attempt'
    uploadFile = new File { owner: req.user._id }
    uploadFile.upload req

  app.get '/hello', (req, res)->
    for i in [1..1000]
      res.write "<div>#{i}</div>"
    res.end()



  app.get '/file/:name', (req,res)->
    path = "#{__dirname}/upload/#{req.params.name}"
    if req.query.dl then res.download path else res.sendfile path

  app.get '/t/files', userAuth, (req,res)->
    req.user.getFiles (err,files)->
      res.json err ? files


  app
