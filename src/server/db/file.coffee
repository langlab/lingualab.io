#
# user file class 
#

mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

_ = require 'underscore'

fs = require 'fs'
util = require 'util'

formidable = require 'formidable'
knox = require 'knox'

klient = knox.createClient {
  key: 'AKIAIUJTVW7ZLSILOJRA'
  secret: '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'
  bucket: 'lingualabio-media'
}


FileSchema = new Schema {
  created: { type: Date, default: Date.now() }
  localPath: String
  owner: { type: ObjectId, ref: 'User' }
  title: { type: String, default: 'Untitled' }
  filename: String
  type: String
  mime: String
  size: Number
}

FileSchema.methods =

  upload: (req)->
    f = new formidable.IncomingForm()
    f.keepExtensions = true
    f.uploadDir = "#{__dirname}/../upload"

    files = {}
    fields = {}
    
    f.on 'progress', (br, be)=>
      #console.log "#{br*100/be }% recvd"
      @emit 'progress', (br*100/be)

    f.on 'field', (field, value)->
      console.log field, value
      fields[field] = value

    f.on 'file', (name, file)->
      files[name] = file
      console.log "file: #{ JSON.stringify file }"
      
    f.on 'end', =>
      console.log JSON.stringify files
      @localPath = files.file.path
      @filename = files.file.filename
      @mime = files.file.mime
      @size = files.file.size
      @type = files.file.type
      @save (err)=>
        @emit 'uploaded'

    f.parse req, (err)->
      if err then console.log 'error: ',err

FileSchema.statics = 

  getAllForUser: (userId,cb)->
    @find({owner: userId}).run cb

module.exports = FileSchema


