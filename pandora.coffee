pandora_host = "www.pandora.com"
pandora_rpc_port = 80
pandora_protocol_version = "31"
pandora_rpc_path = "/radio/xmlrpc/v" + pandora_protocol_version + "?"

crypt = require('./crypt.js')
sys = require('sys')
http = require('http')

rid = (new Date().getTime() % 10000000000).toString().substring(0,7)

time = ->
  return (new Date().getTime() + '').substr(0,10)

sync = ->
  xml = "<?xml version=\"1.0\"?><methodCall><methodName>misc.sync</methodName><params></params></methodCall>"
  encrypted = crypt.encrypt(xml)
  uri = pandora_rpc_path + "rid=" + time().substr(3) + 'P&method=' + 'sync'
  opts = {
    host: pandora_host,
    port: pandora_rpc_port,
    path: uri,
    method: 'POST' }
  doHttpPost('sync', encrypted, opts, console.log)

doHttpPost = (method, data, opts, cb) ->
  req = http.request(opts, (res) ->
    res.setEncoding('utf8')
    res.on 'data', (chunk) ->
      cb(chunk)
    
    res.on 'error', (chunk) ->
      cb(chunk)
  )
  req.write(data)
  req.end()
    
sync()
