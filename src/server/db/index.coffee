CFG = require '../config'

mongoose = require 'mongoose'
mongoose.connect "mongodb://#{ CFG.DB.HOST() }/#{ CFG.DB.NAME }"
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
mongooseAuth = require 'mongoose-auth'
_ = require 'underscore'


UserSchema = new Schema {}
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
      callbackPath: '/twitter/callback'
      redirectPath: '/'
      moduleTimeout: 15000

}


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


Model = mongoose.model 'model', ModelSchema
User = mongoose.model 'user', UserSchema

module.exports =
  mongoose: mongoose
  Model: Model
  User: User
  
