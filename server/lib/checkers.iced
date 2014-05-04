mm                = require('../lib/mod').mgr
{constants}       = require '../lib/constants'
kbpgp             = require('kbpgp')
MT                = kbpgp.const.openpgp.message_types

##-----------------------------------------------------------------------

strip = (input) -> 
  if not input? then null
  else if (m = input.match /^\S*(.*?)\S*$/)? then m[1]
  else ''
      
##-----------------------------------------------------------------------

in_range = (x, config) -> (x >= config.min) and (x <= config.max)

##-----------------------------------------------------------------------

check_bool = (b) ->
  if b      in [0,"0","false",false] then return [false, null]
  else if b in [1,"1","true", true]  then return [true, null]
  else return [null, 'bad boolean value']

##-----------------------------------------------------------------------

is_empty = (m) -> not(m?) or not(m.length) or m.match(/^\s+$/)

##-----------------------------------------------------------------------

check_pgp_message = (text, type) ->
  [err, msg] = kbpgp.armor.decode text
  if err? then [ null, "Error parsing PGP data: #{err.message}" ]
  else if not is_empty(msg.post) then [ null, "found bogus trailing data" ]
  else if not is_empty(msg.pre)  then [ null, "found bogus prefix data" ]
  else if msg.type isnt type then     [ null, "wrong PGP message type" ]
  else [ msg.raw(), null ]

##-----------------------------------------------------------------------

check_base64u = (s) ->
  x = /^[0-9a-z-_]+$/i 
  if not s? then [ null, "unspecified" ]
  else if s.match x then [s, null ]
  else [ null, "not a Base64u encoded string"]

##-----------------------------------------------------------------------

check_hex = (s, len) ->
  x = /^[0-9a-f]+$/i
  if not (s = strip s)? then [ null, 'unspecified' ]
  else if not s.match x then [ null, 'need an id']
  else if len? and s.length isnt len then [ null, "needed a hex string of length #{len}" ]
  else [ s.toLowerCase(), null ]

##-----------------------------------------------------------------------

check_base64 = (s) ->
  if not s?
    return [null, 'unspecified']
  else
    x = /^[0-9a-z\/\+]+[=]{0,2}$/i
    s = s.replace /\s/g, ''
    if not s.match x
      return [ null, 'not base64']
    else
      return [ s, null]

##-----------------------------------------------------------------------

check_string = (s, min, max) ->
  if not (s = strip s)? then [ null, "unspecified" ]
  else if (min? and s.length < min) then [ null, "Must be at least #{min} long"]
  else if (max? and s.length > max) then [ null, "Must be at least #{max} long"]
  else [ s, null]

##-----------------------------------------------------------------------

check_int = (s, min, max) ->
  x = /^-?[0-9]+$/
  if not (s = strip s)? then [ null, "Unspecified" ]
  else if not s.match x then [ null, "need an integer" ]
  else if isNaN(i = parseInt s) then [ null, "Could not parse integer #{s}" ]
  else if (min? and i < min) or (max? and i > max) then [ null, "Must be in range #{min}-#{max}"]
  else [ i, null ]

##-----------------------------------------------------------------------

check_id = (x, config, required = true) ->
  empty = not x? or x.length is 0
  if empty and required then [ null, "no ID specified" ]
  else if empty and not required then [ null, null ]
  else if x.length is 2*config.byte_length then [ x, null ]
  else [ null, "ID has wrong length"]

##-----------------------------------------------------------------------

check_multi = (x,fn) ->
  if not x? or x.length is 0 then [out,err] = [ null, "no keys given" ]
  else
    v = x.split /,/
    err = null
    out = []
    for e in v when not err?
      [val,err] = fn e
      out.push val
    out = null if err?
  return [ out, err ] 

##-----------------------------------------------------------------------

exports.checkers = checkers =  {}

##-----------------------------------------------------------------------

