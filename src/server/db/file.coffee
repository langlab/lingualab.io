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
  status: String
}

FileSchema.methods =

  azUrl: ->
    "#{CFG.S3.URL_ROOT}/#{CFG.S3.MEDIA_BUCKET}/#{@_id}.#{@ext}"

  needsConverting: ->
    @type in ['video','audio']

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
          

  convert: ->
    zencoder = new Zencoder @
    zencoder.encode()
    zencoder.on 'progress', (job)=>
      console.log 'zen prog'
      @status = { action: 'converting', progress: job.progress.progress }
      @save (err)=> @report 'file:sync', { method: 'status', model: @ }
    zencoder.on 'finished', (job)=>
      console.log 'zen fin'
      @status = 'ready'
      @save (err)=> @report 'file:sync', { method: 'status', model: @ }


  report: (ev,data)->
    @model('file').sio.sockets.in(@owner).emit ev, data


FileSchema.statics = 

  socketSetup: (@sio)->

  getAllForUser: (userId,cb)->
    @find({owner: userId}).run cb


module.exports = FileSchema


