
##=======================================================================

class RunMode

  DEVEL : 0
  PROD : 1
  STAGING : 2
  
  constructor : (s) ->
    t =
      devel : @DEVEL
      prod : @PROD
      staging : @STAGING
      
    [ @_v, @_name, @_chosen ] = if (s? and (m = t[s])?) then [m, s, true ]
    else [ @PROD, "prod", false ]

  is_devel : () -> (@_v is @DEVEL)
  is_prod : () -> @_v is @PROD
  is_staging : () -> (@_v is @STAGING)

  toString : () -> @_name
  chosen : () -> @_chosen
  config_dir : () -> @_name

##=======================================================================

class Env

  # Load in all viable command line switching opts
  constructor : (opt_fn) ->
    @env = process.env
    @argv = opt_fn(require('yargs')).argv
    @mm = require('./mod').mgr
    require('./log').init @

  get_opt : ({env, arg, config, dflt}) ->
    r = null
    r = env(@env)  if not r? and env?
    r = arg(@argv) if not r? and arg?
    r = config(co) if not r? and config? and (co = @mm.config)?
    r = dflt()     if not r? and dflt?
    return r

  get_port : ({dflt, config}) ->
    @get_opt
      env : (e) -> e.PORT
      arg : (a) -> a.p
      config : (c) -> 
        if config? then config.port
        else if c? then c.port
        else null
      dflt : -> dflt

  get_bind_addr : ({dflt, config}) ->
    @get_opt
      env : (e) -> e.BIND_ADDR
      arg : (a) -> a.b
      config : (c) ->
        if config? then config.bind_addr
        else if c? then c.bind_addr
        else null
      dflt : -> dflt

  get_debug : () ->
    @get_opt
      env : (e) -> e.DEBUG
      arg : (a) -> a.d
      config : (c) -> c.logging?.debug
      dflt : -> false

  get_run_mode : () ->
    unless @_run_mode
      raw = @get_opt
        env : (e) -> e.RUN_MODE
        arg : (a) -> a.m
        config : (c) -> c.run_mode
        dflt : null
      @_run_mode = new RunMode raw
    return @_run_mode

  get_log_level : () ->
    @get_opt
      env : (e) -> e.LOG_LEVEL
      arg : (a) -> a.l
      config : (c) -> c.log.level
      dflt : -> null

  get_log_priority : () ->
    @get_opt
      env : (e) -> e.LOG_PRIORITY
      arg : (a) -> a.P
      config : (c) -> if @get_run_mode().is_prod() then c.log.priority else null
      dflt : -> null

  get_logger_cmdline : () ->
    p = @get_log_priority()
    if p?
      r = @get_opt
        env : (e) -> e.LOGGER_CMDLINE
        arg : (a) -> a.C
        config : (c) -> c.log.cmdline
        dflt : -> [ "logger", '-i' ]
      r = r.split /\s+/ if typeof r is 'string'
      r.push '-p'
      r.push p
    else r = null
    return r
 
  get_args : () -> @argv._
  get_argv : () -> @argv

##=======================================================================

_env = null
exports.make = (f) -> _env = new Env f
exports.get  = () -> _env

