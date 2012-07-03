web-app-boilerplate
===================

This is my boilerplate for starting a web application.

  - Client side: Compiled coffeescript using jQuery for handling DOM, underscore for sugar, and backbone for ~MVC framework. Client side templates rendered from coffeescript via coffeekup.

  - Twitter bootstrap configured and compiled from less files

  - Server side: express running on node. HTML templates rendered from coffeescript via coffeekup.

  - Database: mongoDB with mongoose as the ORM

  - User authorization is handled with mongoose-auth, which connects everyauth with express sessions and mongoose/db

  - Socket.io, which I have embedded into the mongoose schemas to listen to Backbone sync calls and return data to callbacks

  - a Cakefile for watching and compiling, bundling and minifying client side scripts

  - Directory tree: all source code under src/ and compiled client side files and resources under pub/


How to use
==========
  
  `git clone git@github.com:georgedyer/web-app-boilerplate.git`

  `cd web-app-boilerplate/src`

  All work is done in src/

  From src/, run `cake dev` before you develop. This script does several things:

    1. starts up the web and socket server 
    2. on change in server/ - restarts the server
    3. on change in less/ or stylus/ - recompiles, bundles less/stylus files to css
    4. on change in coffee/ - recompiles, bundles (minifies in prod) coffee files to js
    5. outputs changes to console

  Check out the Cakefile for details.

  Work on files in src/ according to the directory tree below
  * = files where most of the work is done

```
      │
      ├── README.md # you're looking at it
      │
      ├── pub # where all the client-accessible resources go
      │   │
      │   ├── css/   # compiled from src/client/less and src/client/styl
      │   │
      │   ├── font/  # includes font-awesome font icons
      │   │
      │   ├── img/   # image resources
      │   │
      │   └── js
      │       │
      │       ├── common.js   # common src/client/coffee modules bundled+minified
      │       │
      │       ├── {role}.js   # extra coffeescript modules for authorized users
      │       │  
      │       └── vendor.js   # all scripts from vendor bundled+minified
      │
      │
      └── src
          │
          ├── Cakefile  # build tasks - dev:watch, 
          │
          ├── client
          │   │
          │   ├── coffee *          # client side coffeescript modules go here
          │   │   │                 # each sub-folder gets bundled as one js file
          │   │   │ 
          │   │   ├── common/ *     # common cs for all users visiting site, bundles to pub/js/common.js
          │   │   │ 
          │   │   └── {role}/ *     # cs for authorized user roles, compiles to pub/js/{role}.js
          │   │                     # make as many as necessary
          │   │
          │   ├── js/               # vendor js goes in here, gets bundled to pub/js/vendor.js
          │   │ 
          │   ├── less/             # mostly for creating twitter bootstrap.css
          │   │
          │   ├── styl/ *           # my stylus (->css) here
          │   │
          │   └── views/ *          # coffeekup templates used by express to render/serve client html
          │       │                 #   ^ links to files in pub/css and pub/js
          │       └─ index.coffee
          │
          │
          ├── node_modules    # server-side third-party modules
          │   │
          │   ├── coffee-script 
          │   ├── coffeekup
          │   ├── express
          │   ├── hound
          │   ├── less
          │   ├── mongoose
          │   ├── mongoose-auth
          │   ├── socket.io
          │   ├── sty
          │   ├── stylus
          │   ├── uglify-js
          │   └── underscore
          │
          │
          ├── server
          │   │
          │   ├── config.coffee *   # app config for server+client (client part gets injected)
          │   │
          │   ├── app.coffee *      # express web server configuration (incl mongooseAuth config)
          │   │
          │   ├── db.coffee *       # mongoDB connection and mongoose schema definitions
          │   │
          │   ├── routes.coffee *   # web server route definitions
          │   │
          │   └── sockets.coffee *  # set up socket session auth and passes msgs to db schemas
          │
          └── server.coffee   # starts off the express app and sockets server
                              # calls app.coffee and sockets.coffee
```








