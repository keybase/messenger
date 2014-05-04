http     = require 'http'
path     = require 'path'
env      = require '../lib/env'
mm       = require('../lib/mod').mgr
log      = require '../lib/log'

# Express middleware
express        = require 'express'
bodyParser     = require 'body-parser'
methodOverride = require 'method-override'
morgan         = require 'morgan'
errorHandler   = require 'errorhandler'

iced.catchExceptions()

##-----------------------------------------------------------------------

env.make (m) -> m.usage 'Usage: $0 [-ld] [-m <devel|prod>] [-p <port>]'

##-----------------------------------------------------------------------

class App

  #-----------------------------------------

  set_port : () ->
    @port = env.get().get_port { dflt : 3000, config : mm.config.host.internal } 
    @bind_addr = env.get().get_bind_addr { dflt : null, config : mm.config.host.internal }

  #-----------------------------------------
  
  constructor : () ->

  #-----------------------------------------
  
  configure_express : () ->
    @app = app = express()
    port = @port

    log.info "In app.configure: set port to #{port}"
    app.set 'port', port
    app.enable 'trust proxy'
    app.use bodyParser()
    app.use methodOverride()

    # For devel
    app.use morgan 'dev'
    app.use errorHandler()

  #-----------------------------------------
  
  make_routes : () ->
    files = [ 'msg' ]
    for f in files
      require("../http/#{f}").bind_to_app @app

  #-----------------------------------------

  run : () ->
    modules = [ 'config', 'db' ]

    mm.create modules
    @set_port()
    @configure_express()
    @make_routes()

    # Now we're safe to set up connections, etc...
    await mm.init defer ok
    log.error "Module initialization failure" unless ok

    if ok
      await http.createServer(@app).listen @port, @bind_addr, defer()
      log.info "Express server listening on #{@bind_addr}:#{@port}"
    if not ok
      process.exit -1

##-----------------------------------------------------------------------

(new App).run()
