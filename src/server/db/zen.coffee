https = require 'https'
CFG = require './../config'
{EventEmitter} = require 'events'

class Zencoder extends EventEmitter

  constructor: (@file)->
    
    if @file.type is 'video'
      output = [
        {
          format: 'mp4'
          video_codec: 'h264'
        }
        {
          format: 'webm'
          video_codec: 'vp8'
        }
      ]
    else if @file.type is 'audio'
      output = [
        {
          format: 'mp3'
        }
      ]


    output = _.filter output, (o)=>
      o.url = "s3://#{CFG.S3.MEDIA_BUCKET}/#{@file._id}.#{o.format}"
      o.public = 1
      o.format isnt @file.ext
    
    if @file.type is 'video'
      output.thumbnails = { interval: 10 }

    @jobBody = 
      input: "s3://#{CFG.S3.MEDIA_BUCKET}/#{@file._id}.#{@file.ext}"
      output: output

  startCheckingStatus: =>
    @statusChecker = doEvery 1000, @getJobStatus

  stopCheckingStatus: ->
    cancelTimeout @statusChecker

  getJobStatus: =>

    options =
      host: CFG.ZENCODER.API_HOST
      path: "/api/v2/jobs/#{@job.id}/progress.json?api_key=#{}"

    https.get options, (resp)=>
      resp.on 'data', (prog)=>
        @job.progress = prog
        eventType = if prog.state is 'finished' then 'finished' else 'progress'
        @emit eventType, @job


  encode: ->

    options =
      host: CFG.ZENCODER.API_HOST
      path: CFG.ZENCODER.API_PATH
      method: 'POST'
      headers:
        'Content-type':'application/json'
        'Content-length': JSON.stringify(@jobBody).length
        'Accept': 'application/json'
        'Zencoder-Api-Key': CFG.ZENCODER.API_KEY

    jobCreate = https.request options, (resp)=>
      resp.on 'data', (@job)=>

      resp.on 'end', @startCheckingStatus

    jobCreate.end JSON.stringify @jobBody, 'utf8'


module.exports = Zencoder