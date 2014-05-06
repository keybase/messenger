mysql = require 'mysql'
mm    = require('../mod').mgr
log   = require '../log'
sc    = require('../constants').status.codes

##=======================================================================

exports.Tx = class Tx
  constructor : () -> 
    @txl = []
    @commit_trigger = null
  push : (query, args, opts) ->
    @txl.push {query, args, opts}
  clear : -> @txl = []

##=======================================================================

class Database

  constructor : (@cfg) ->

  init : (cb) ->
    n = @cfg.n_threads
    cfg = @cfg.db
    @_waiters = []
    @_clients = (mysql.createConnection cfg for i in [0...n])
    cb true

  ##-----------------------------------------
  
  _get : (cb) ->
    if @_clients.length
      c = @_clients.pop()
    else
      await @_waiters.push defer c
    cb c

  ##-----------------------------------------
  
  _putback : (cli) ->
    if @_waiters.length
      w = @_waiters.shift()
      w cli
    else
      @_clients.push cli

  ##-----------------------------------------

  # Fake assembling this query as the node MySQL library would do it
  fake_q : (q, args) -> 
    parts = q.split('?')
    out = []
    for arg,i in args
      out.push parts[i]
      arg = if (typeof(arg) is 'number') then arg else ('"' + arg + '"')
      out.push arg
    out.push parts[-1...][0]
    out.join('')

  ##-----------------------------------------

  query : (q, args, cb, opts) ->
    unless (q? and q.length) and (args? and Array.isArray args) and (typeof(cb) is 'function')
      throw new Error "Bad db.query call -- need (q,args,cb)"
    await @_get defer cli
    await cli.query q, args, defer res...
    cb res...
    @_putback cli

  ##-----------------------------------------

  load1 : (q, args, cb) ->
    await @query q, args, defer err, res, info
    desc =  "query #{q} w/ #{JSON.stringify args}"
    ok = false
    if err?
      err = new Error "Error in #{desc}: #{err}"
      err.sc = sc.DB_SELECT_ERROR
    else if res.length is 0
      err = new Error "Lookup failed in #{desc}: none found"
      err.sc = sc.NOT_FOUND
    else if res.length > 1
      err = new Error "Lookup failed in #{desc}: too many rows: #{res.length}"
      err.sc = sc.CORRUPTION
    else
      row = res[0] 
    cb err, row

  ##-----------------------------------------

  update1 : (q, args, cb, insert_or_update = false) ->
    await @query q, args, defer err, info
    ret = false
    if err?
      log.error "In #{q} w/ #{JSON.stringify args}: #{err}"
    else if (((ar = info.affectedRows) isnt 1) and
             (not insert_or_update or (ar isnt 2)))
      log.warn "In #{q} w/ #{JSON.stringify args}; wrong number of rows: #{ar}"
    else ret = true
    cb ret

  ##-----------------------------------------
  
  transaction : (tx, cb) ->
    await @_get defer cli
    await cli.query 'START TRANSACTION', [], defer err

    if err?
      started = false
      ok = false
    else
      ok = true
      started = true

    elist = []
    edict = {}

    if ok
      for c,i in tx.txl
        await cli.query c.query, c.args, defer err, rows
        if err?
          err = new Error "Error in command #{c.query}: #{err}"
        else if (a = c.opts?.assertion)? and not a rows
          err = new Error "assertion #{i} failed"
        elist[i] = err
        edict[name] = err if (name = c.opts?.name)?
        if err?
          ok = false
          break
        
    if started
      op = if ok then 'COMMIT' else 'ROLLBACK'
      await cli.query op, [], defer commit_err
      if commit_err
        commit_err = new Error "Error in command #{op}: #{commit_err}"
  
        # report an error either way
        if not err?
          err = commit_err
        else
          log.error commit_err

    cb err, elist, edict
    @_putback cli
    
##=======================================================================

class Module

  constructor : () ->
    for name, cfg of mm.config.dbs
      @_dbs[name] = new Database cfg

  init : (cb) ->
    ok = true
    for db in @_dbs
      await db.init defer tmp
      ok = false unless tmp
    cb ok

  get : (n) -> @_dbs[n]

##=======================================================================

exports.Module = Module

##=======================================================================
