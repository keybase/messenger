
log = require './log'

##=======================================================================
#
# Module Manager
#
#   'Modules' are a set of signleton objects used for managing things
#   in one place, like configuration files, and connections to other
#   services or processes.
#
#   Initialization happens in two passes:
#     1. Creation (see create below)
#     2. Initialization (see init below)
#
#   The two-pass system allows the configuration of the config system
#   to see how to configure connections, for instance.
#
##=======================================================================

class Manager

  #-----------------------------------------
  
  constructor: () ->
    @_modules         = []
    @_inited          = false
    @_inited_ok       = null
    @_after_init_fns  = []

  #-----------------------------------------
  
  create: (modules) ->
    for m in modules
      # We can either specify a module as [ name, opts ] pair, of just a name
      [ mn, opts ] = if typeof m is 'string' then [ m, {} ] else m
      
      klass = require("./mod/#{mn}").Module
      mod = new klass opts
      mod.name = mn
      @_modules.push mod
      @[mn] = mod

  #-----------------------------------------
  
  init: (cb) ->
    ok = true
    for mod in @_modules
      await mod.init defer res
      if not res
        log.error "#{mod.name}: module initialization failed"
        ok = false
    @_inited_ok = ok
    @_inited    = true
    cb ok
    fn(@_inited_ok) for fn in @_after_init_fns

  #-----------------------------------------

  start : (modules, cb) ->
    @create modules
    await @init defer ok
    cb ok

  #-----------------------------------------

  after_init: (fn) ->
    if @_inited
      fn @_inited_ok
    else
      @_after_init_fns.push fn
    
##=======================================================================

exports.Manager = Manager
exports.mgr = mgr = new Manager()
exports.get_mgr = () -> mgr

##=======================================================================
