
CFG = require '../config'
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

console.log dbUrl = "mongodb://#{ CFG.DB.HOST }/#{ CFG.DB.NAME }"
mongoose.connect dbUrl

mongooseAuth = require 'mongoose-auth'
_ = require 'underscore'


UserSchema = new Schema {
  role: { type: String, enum: ['teacher','student'], default: 'teacher' }
  created: { type: Date, default: Date.now() }
  lastLogin: Date 
  activeSessions: { any: {} }
  activeClients: { any: {} }
  twitterId: { type: Number, index: true }
  twitterName: String
  twitterData: String
  name: String
}

UserSchema.plugin mongooseAuth, {

  everymodule:
    everyauth:
        User: -> 
          return User

  twitter:
    everyauth:
      myHostname: "http://#{CFG.HOST()}"
      consumerKey: CFG.TWITTER.CONSUMER_KEY
      consumerSecret: CFG.TWITTER.CONSUMER_SECRET
      callbackPath: '/twitter/return'
      redirectPath: '/'
      moduleTimeout: 15000

}

myUserMethods =
  getFiles: (cb)->
    File.find { owner: @._id }, (err,files)->
      cb err,files

# additional static methods for users 'collection'
myUserStatics =
  
  # keep track of all of the connected sockets 
  # and connected sessions
  # for this user in an object/collection
  connectUser: (userId, sock, sess)->
    
    @activeSockets ?= {}
    thisUser = @activeSockets[userId] ?= {}
    thisUser[sock.id] = sock
    
    @activeSessions ?= {}
    thisUser = @activeSessions[userId] ?= {}
    thisUser[sess.id] ?= sess.data

  # removes a socket from the users's collection when it disconnects
  disconnectUser: (userId, sockId)->
    delete @activeSockets[userId][sockId]
  
  getAll: (cb)->
    @find (err, users)->
      cb users

# careful to just add them to UserSchema 
# so as not to overwrite mongooseAuth statics
_.extend UserSchema.statics, myUserStatics
_.extend UserSchema.methods, myUserMethods


ModelSchema = new Schema {
  _user: { type: ObjectId, ref: 'User' }
  title: String
  description: String
}

ModelSchema.statics =

  sync: (data, cb)->

    { method, model, options, userId } = data

    switch method
      
      when 'read'
        if (id = model._id)
          @findById id, (err,model)=>
            cb err, model
        else
          @find (err,model)=>
            cb err, model

      when 'read-user'
        @getForUser userId, (err,myModels)=>
          cb err,myModels

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


module.exports =
  mongoose: mongoose
  Model: Model = mongoose.model 'model', ModelSchema
  User: User = mongoose.model 'user', UserSchema
  File: File = mongoose.model 'file', require './file'
  Log: Log = mongoose.model 'log', require './log'
  
