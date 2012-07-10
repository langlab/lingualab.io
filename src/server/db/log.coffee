
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

LogSchema = new Schema {
  dt: {type: Date, default: Date.now()}
  user: { type: ObjectId, ref: 'User' }
  type: String
  description: String
  data: { any: {} }
}

module.exports = LogSchema