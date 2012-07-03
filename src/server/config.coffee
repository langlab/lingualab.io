###
# server-side application configuration data
###

module.exports =

  INFO:
    NAME: 'boilerplate app'
    AUTHOR: 'George Pezzuti Dyer'
    URL: 'http://github.com/georgedyer'

  STAGE: 'DEV'  # 'DEV' or 'PROD'
 
  DEV_HOST: 'lingualab.io'
  PROD_HOST: 'domain.com'

  HOST: -> @["#{ @STAGE }_HOST"]

  DEV_PORT: 8181
  PROD_PORT: 8181

  PORT: -> @["#{ @STAGE }_PORT"]

  TWITTER:
    CONSUMER_KEY: 'aoMCcJR62q9GYRAP9OOUQ'
    CONSUMER_SECRET: 'oT133ULqySY3H55xWQHa7nA5iV7a1UzAFJMnubyw'

  AMAZON:
    SECRET: 'x'

  DB:
    HOST: -> @["#{ @STAGE }_HOST"]
    NAME: 'test'


  # have CLIENT return the configuration object to inject into the client
  CLIENT: ->

    CLIENT_DATA =
      INFO: @INFO



