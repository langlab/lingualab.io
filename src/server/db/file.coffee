#
# user file class 
#

mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
CFG = require './../config'
https = require 'https'

Zencoder = require './zen'

{EventEmitter} = require 'events'

_ = require 'underscore'

fs = require 'fs'
util = require 'util'

formidable = require 'formidable'
knox = require 'knox'

{ KEY, SECRET, MEDIA_BUCKET } = CFG.S3

klient = knox.createClient {
  key: KEY
  secret: SECRET
  bucket: MEDIA_BUCKET
}

wait = (someTime,thenDo) ->
  setTimeout thenDo, someTime
doEvery = (someTime,action)->
  setInterval action, someTime


FileSchema = new Schema {
  created: { type: Date, default: Date.now() }
  localPath: String
  owner: { type: ObjectId, ref: 'User' }
  title: { type: String, default: 'Untitled' }
  filename: String
  ext: String
  type: String
  mime: String
  size: Number
  status: {}
}

FileSchema.methods =

  azUrl: ->
    "#{CFG.S3.URL_ROOT}/#{CFG.S3.MEDIA_BUCKET}/#{@_id}.#{@ext}"

  needsConverting: ->
    @type in ['video','audio']

  # receive the upload from the request, then pass off to processing
  upload: (req)->
    f = new formidable.IncomingForm()
    f.keepExtensions = true
    f.uploadDir = __dirname.replace 'server/db', 'upload'

    files = {}
    fields = {}


    f.on 'progress', (br, be)=>
      # console.log "#{br*100/be }% recvd"
      # @emit 'progress', (br*100/be)

    f.on 'field', (field, value)->
      # console.log field, value
      fields[field] = value

    f.on 'file', (name, file)->
      files[name] = file
      # console.log "file: #{ JSON.stringify file }"
      
    f.on 'end', =>
      @localPath = files.file.path
      @filename = files.file.filename
      @title = files.file.filename
      fileNameParts = files.file.filename.split('.')
      @ext = fileNameParts[fileNameParts.length-1]
      @mime = files.file.mime
      @size = files.file.size
      @type = files.file.type.split('/')[0]
      @status = 'uploading'
      @save (err)=>
        @report 'file:sync', { method: 'create', model: @ }
        @moveToAz()

    f.parse req, (err)->
      if err then console.log 'error: ',err

  # upload the file to Amazon S3
  moveToAz: ->
    klient.putFile @localPath, "#{@_id}.#{@ext}", (err,resp)=>
      @status = if @needsConverting() then { action: 'converting', progress: 0 } else 'ready'
      @save (err)=>
        @report 'file:sync', { method: 'status', model: @ }
        @convert() if @needsConverting()
          
  # send media files to Zencoder  
  convert: ->
    zencoder = new Zencoder @
    zencoder.encode()
    zencoder.on 'progress', (job)=>
      #console.log 'zen prog',util.inspect job
      @status = { action: 'converting', progress: job.progress }
      @save (err)=> @report 'file:sync', { method: 'status', model: @ }
    zencoder.on 'finished', (job)=>
      #console.log 'zen fin'
      @status = 'ready'
      @save (err)=> @report 'file:sync', { method: 'status', model: @ }

  # send information to client through websockets
  report: (ev,data)->
    @model('file').sio.sockets.in(@owner).emit ev, data


FileSchema.statics = 

  socketSetup: (@sio)->

  getAllForUser: (userId,cb)->
    @find({owner: userId}).run cb

  # receive sync messages from client-side Backbone models
  sync: (data, sock, cb)->

    console.log 'socket: this user: ', sock.store.data.userId

    { method, model, options } = data
    userId = sock.store.data.userId

    switch method
      
      when 'read'
        if (id = model._id)
          @getAllForUser id, (err,model)=>
            cb err, model
        else
          @find (err,model)=>
            cb err, model

      when 'update'
        @findById model._id, (err,modelToUpdate)=>
          delete model._id
          delete model._user
          _.extend modelToUpdate, model
          modelToUpdate.save (err)=>
            cb err,modelToUpdate

      when 'create'
        newModel = new Model model
        newModel.save (err)=>
          cb err, newModel


      when 'delete'
        @findById model._id, (err,modelToDelete)=>
          modelToDelete.remove (err)=>
            cb err


module.exports = FileSchema


