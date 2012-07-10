# user database schema

CFG = require '../config'
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
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
  files: [{ type: Schema.ObjectId, ref: 'File' }]
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

module.exports = UserSchema
