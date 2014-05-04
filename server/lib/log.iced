
base = require('framed-msgpack-rpc').log
path = require 'path'

##=======================================================================

_settings = {}
_possible_levels = []

##=======================================================================

format_date = () ->
  d = new Date()
  mv = [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug' , 'Sep', 'Oct', 'Nov', 'Dev']
  [ mv[d.getMonth()], d.getDate(), d.toLocaleTimeString() ]

##=======================================================================

_output_final_sink = (m) -> console.log m

exports.output_hook = output_hook = (m) ->
  parts = if _settings.date then format_date() else []
  parts.push _settings.procstamp if _settings.procstamp?
  parts.push m
  _output_final_sink parts.join ' '

##=======================================================================

spawn_logger = (argv) ->
  argv.push "-t"
  argv.push _settings.procname
  cmd   = argv.shift()
  cpm   = require 'child_process'
  child = cpm.spawn cmd, argv
  child.on 'exit', (code) ->
    console.log "Logger process (#{cmd}, #{JSON.stringify argv}) exitted w/ code=#{code}"
    _output_final_sink = (m) -> console.log m
  _output_final_sink = (m) -> 
    m += "\n" if m[m.length-1] isnt '\n'
    child.stdin.write m


##=======================================================================
 
exports.Logger = class Logger extends base.Logger
  constructor : (d = {}) ->
    super d
    @prefix = null unless d.prefix?
    @output_hook = output_hook
  make_child :  (d) -> return new Logger d
  
##=======================================================================
 
exports.RpcLogger = class RpcLogger extends base.Logger
  constructor : (d = {}) ->
    super d
    @output_hook = output_hook
  make_child :  (d) -> return new RpcLogger d
  
##=======================================================================

exports.make_logs = (obj, d) ->
  logger = new Logger d
  for l in _possible_levels
    obj[l] = ((k) -> (m) -> logger[k](m) )(l)

##=======================================================================

exports.init = (env) ->

  levels = {}
  firsts = {}
  for k,v of base.levels 
    k = k.toLowerCase()
    levels[k] = v
    firsts[k[0]] = v

  base.set_default_level lev if ((rawlev = env.get_log_level())? and
    (lev = if rawlev.length > 1 then levels[rawlev] or firsts[rawlev])?)
  
  _settings.procname = path.basename process.argv[1]
  if env.get_run_mode().is_devel()
    _settings.procstamp = "#{_settings.procname}[#{process.pid}]"
    _settings.date = true
  if (argv = env.get_logger_cmdline())?
    spawn_logger argv

  # For the purposes of the RPC base class...
  base.set_default_logger_class RpcLogger
  
  exports.global_logger = gl = new Logger()
    
  for k of levels when k isnt 'top' and k isnt 'none'
    _possible_levels.push k
    exports[k] = ((k2) -> (m) -> gl[k2](m) )(k)

  if rawlev and not lev
    exports.error "Could not set logging level to #{rawlev}"
