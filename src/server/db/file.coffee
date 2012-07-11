#
# user file class 
#

mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
CFG = require './../config'
console.log CFG
https = require 'https'

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


class Zencoder
  constructor: (@file)->
    if @file.type is 'video'
      output = [
        {
          format: 'mp4'
          video_codec: 'h264'
          base_url: "#{CFG.S3.URL_ROOT}/#{CFG.S3.MEDIA_BUCKET}"
        }
        {
          format: 'webm'
          video_codec: 'v8'
          base_url: "#{CFG.S3.URL_ROOT}/#{CFG.S3.MEDIA_BUCKET}"
        }
      ]
    else if @file.type is 'audio'
      output = [
        {
          format: 'mp3'
          base_url: "#{CFG.S3.URL_ROOT}/#{CFG.S3.MEDIA_BUCKET}"
        }
      ]

    _.filter output (o)-> o.format isnt @file.ext
    
    if @file.type is 'video'
      output.thumbnails = { interval: 10 }

    @jobBody = 
      api_key: CFG.ZENCODER.API_KEY
      input: "#{CFG.S3.URL_ROOT}/#{CFG.S3.MEDIA_BUCKET}/#{@file._id}.#{@file.ext}"
      output: output

    console.log @jobBody

  encode: ->

    options =
      host: CFG.ZENCODER.API_HOST
      path: CFG.ZENCODER.API_PATH
      method: 'POST'

    jobCreate = https.request options, (resp)->
      resp.on 'data', (data)->
        console.log 'zc: ',data

    jobCreate.end @jobBody, 'utf8'




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

  upload: (req)->
    f = new formidable.IncomingForm()
    f.keepExtensions = true
    console.log "upload dir base: #{__dirname}"
    f.uploadDir = __dirname.replace 'server/db', 'upload'

    files = {}
    fields = {}
    
    f.on 'progress', (br, be)=>
      console.log "#{br*100/be }% recvd"
      @emit 'progress', (br*100/be)

    f.on 'field', (field, value)->
      console.log field, value
      fields[field] = value

    f.on 'file', (name, file)->
      files[name] = file
      console.log "file: #{ JSON.stringify file }"
      
    f.on 'end', =>
      @localPath = files.file.path
      @filename = files.file.filename
      fileNameParts = files.file.filename.split('.')
      @ext = fileNameParts[fileNameParts.length-1]
      @mime = files.file.mime
      @size = files.file.size
      @type = files.file.type.split('/')[1]
      @status = 'uploading'
      @save (err)=>
        @model('file').sio.sockets.in(@owner).emit 'file:sync', { method: 'create', model: @ }
        @moveToAz()

    f.parse req, (err)->
      if err then console.log 'error: ',err

  # upload the file to Amazon S3
  moveToAz: ->
    klient.putFile @localPath, "#{@_id}.#{@ext}", (err,resp)=>
      console.log "knox resp #{resp.statusCode}"
      @status = 'converting'
      @save (err)=>
        @model('file').sio.sockets.in(@owner).emit 'file:sync', { method: 'status', model: @ }
        zencoder = new Zencoder @
        zencoder.encode()


FileSchema.statics = 

  socketSetup: (@sio)->

  getAllForUser: (userId,cb)->
    @find({owner: userId}).run cb


module.exports = FileSchema


