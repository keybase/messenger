{checkers}            = require './checkers'
constants             = require './constants'
sc                    = constants.status.codes
sc_lookup             = constants.status.lookup
log                   = require './log'
mm                    = require('./mod').mgr
url                   = require 'url'
env                   = require '../lib/env'

util = require 'util'

##-----------------------------------------------------------------------

make_status_obj = (code, desc, fields) ->
  out = { code }
  out.desc = desc if desc?
  out.fields = fields if fields?
  out.name = sc_lookup[code]
  return out
  
##-----------------------------------------------------------------------

exports.Handler = class Handler

  constructor : (@req, @res) ->
    log.make_logs @,  { remote : @req.ip, prefix : @req.protocol }
    @_error_in_field    = {}
    @oo                 = {}
    @user               = null
    @response_sent_yet  = false
   
  #-----------------------------------------

  needed_fields : -> []
  maybe_fields : -> []

  #-----------------------------------------

  is_input_ok : () -> Object.keys(@_error_in_field).length is 0
   
  #-----------------------------------------

  pub: (dict) -> @oo[k] = v for k,v of dict
  clear_pub : () -> @oo = {}

  #-----------------------------------------

  get_unchecked_input_field: (f) ->
    ###
    does no error checking
    ###
    v       = null
    arrays  = [ "body", "query", "params"]
    for a in arrays
      break if (v = @req[a][f])?
    if (not v?) or (v.length is 0) 
      return null
    return v

  #-----------------------------------------

  get_input_field : (f, is_optional) ->
    v = @get_unchecked_input_field f
    if (not v?) and is_optional
      return true
    [v,e] = checkers[f] v
    ret = true
    if e
      @_error_in_field[f] = e
      ret = false
    else
      @[f] = v
    return ret
  
  #-----------------------------------------
  
  get_input : ->
    ret = true
    for f in @needed_fields()
      ret = false unless @get_input_field f, false
    for f in @maybe_fields()
      ret = false unless @get_input_field f, true
    @set_error sc.INPUT_ERROR, "missing or invalid input", @_error_in_field unless ret
    return ret

  #-----------------------------------------

  set_error : (code, desc = null, fields = null) ->
    @oo.status = make_status_obj code, desc, fields
    log.warn "set_error #{code} #{desc}" unless code is sc.OK
    new Error code

  #-----------------------------------------

  set_ok : () -> @set_error sc.OK
   
  #-----------------------------------------

  is_ok : () -> 
    (not @oo?.status?.code?) or (@oo.status.code is sc.OK)

  #-----------------------------------------

  status_code : () -> @oo?.status?.code or sc.OK
  status_name : () -> 
    code = @status_code()
    sc_lookup[code] or "code-#{code}"
  handler_name : () -> @constructor.name

  #-----------------------------------------

  get_iparam : (f) -> parseInt(@req.param(f), 10)
  
  #-----------------------------------------
  
  send_res_json : (cb) ->
    @format_res()
    @res.send @oo
    @response_sent_yet = true
    cb()

  #-----------------------------------------

  format_res : ->
    if @oo.status?
      # noop
    else if not @is_input_ok()
      @set_error sc.INPUT_ERROR, "Error in JSON input", @_error_in_field
    else
      @set_ok()
   
  #==============================================
  
  handle : (cb) ->
    await @__handle_universal_headers defer()
    await @__set_cross_site_get_headers defer()
    await @__handle_checks defer()
    unless did_reply
      await @__handle_custom defer()
      await @__handle_output defer()
    cb()

  #------

  __set_cross_site_get_headers: (cb) ->
    if @allow_cross_site_get_requests()
      @res.set 'Access-Control-Allow-Origin' :     '*'
      @res.set 'Access-Control-Allow-Methods':     'GET'
      @res.set 'Access-Control-Allow-Headers':     'Content-Type, Authorization, Content-Length, X-Requested-With'
      # I believe this is the default anyway, but let's play it safe
      @res.set 'Access-Control-Allow-Credentials': 'false'
    cb()

  #------

  __handle_universal_headers : (cb) ->
    if env.get().get_run_mode().is_prod()
      @res.set "Strict-Transport-Security", "max-age=31536000"
    cb()

  #------
  
  __handle_checks : (cb) ->
    if @get_input()
      @set_ok()
    cb()

  #------
  
  __handle_custom : (cb) ->
    if @is_ok()
      await @_handle defer()
    else
      await @_handle_err defer()
    cb()

  #------
  
  __handle_output : (cb) ->
    if @response_sent_yet
      await @send_res_json defer()
    cb()
   
  #==============================================

  _handle_err : (cb) -> @_handle cb

  #-----------------------------------------
    
  @make_endpoint : (opts) ->
    (req, res) =>
      handler = new @ req, res, opts
      await handler.handle defer()

  #-----------------------------------------
    
  @bind : (app, path, methods, opts = {}) ->
    ep = @make_endpoint opts
    for m in methods
      app[m.toLowerCase()](path, ep)

#==============================================

exports.BOTH = [ "GET" , "POST" ] 
exports.GET = [ "GET" ]
exports.POST = [ "POST" ]
exports.DELETE = [ "DELETE" ]
