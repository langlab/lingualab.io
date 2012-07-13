https = require 'https'
CFG = require './../config'
{EventEmitter} = require 'events'
_ = require 'underscore'

wait = (someTime,thenDo) ->
  setTimeout thenDo, someTime
doEvery = (someTime,action)->
  setInterval action, someTime


class Zencoder extends EventEmitter

  constructor: (@file)->
    @prepareJobReq()

  prepareJobReq: ->
    
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
        o.thumbnails =
          number: 10
          base_url: "s3://#{CFG.S3.MEDIA_BUCKET}/"
          prefix: "#{@file._id}"
          width: 400

    @jobReq = 
      input: "s3://#{CFG.S3.MEDIA_BUCKET}/#{@file._id}.#{@file.ext}"
      output: output

  startCheckingStatus: =>
    @statusChecker = doEvery 1000, @getJobStatus

  stopCheckingStatus: ->
    clearTimeout @statusChecker

  getJobStatus: =>
    options =
      host: CFG.ZENCODER.API_HOST
      path: "/api/v2/jobs/#{@job.id}/progress.json?api_key=#{CFG.ZENCODER.API_KEY}"
      headers:
        'Accepts':'application/json'


    https.get options, (resp)=>
      resp.setEncoding 'utf8'
      resp.on 'data', (prog)=>
        @job.progress = prog.progress
        eventType = if prog.state is 'finished' then 'finished' else 'progress'
        @emit eventType, @job
        if eventType is 'finished' then @stopCheckingStatus()


  encode: ->

    options =
      host: CFG.ZENCODER.API_HOST
      path: CFG.ZENCODER.API_PATH
      method: 'POST'
      headers:
        'Content-type':'application/json'
        'Content-length': JSON.stringify(@jobReq).length
        'Accept': 'application/json'
        'Zencoder-Api-Key': CFG.ZENCODER.API_KEY

    console.log 'requesting job: ',options, @jobReq
    jobCreate = https.request options, (resp)=>
      resp.setEncoding 'utf8'

      resp.on 'data', (@job)=>
        if _.isString(@job)
          @job = JSON.parse @job

        console.log 'from zen: ',@job

      resp.on 'end', @startCheckingStatus

    jobCreate.end JSON.stringify @jobReq, 'utf8'


module.exports = Zencoder