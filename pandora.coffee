pandora_host = "www.pandora.com"
pandora_rpc_port = 80
pandora_protocol_version = "31"
pandora_rpc_path = "/radio/xmlrpc/v" + pandora_protocol_version + "?"

crypt = require('./crypt.js')
sys = require('sys')
http = require('http')
xml2js = require('xml2js')
info = require('./info.coffee')

time = ->
  return (new Date().getTime() + '').substr(0,10)

sync = (cb) ->
  xml = "<?xml version=\"1.0\"?><methodCall><methodName>misc.sync</methodName><params></params></methodCall>"
  encrypted = crypt.encrypt(xml)
  uri = pandora_rpc_path + "rid=" + time().substr(3) + 'P&method=' + 'sync'
  opts = {
    host: pandora_host,
    port: pandora_rpc_port,
    path: uri,
    method: 'POST' }
  doHttpPost('sync', encrypted, opts, cb)

authUser = (t, username, password, cb) ->
  # Use full time for the XML rpc 
  xml = "<?xml version=\"1.0\"?><methodCall><methodName>listener.authenticateListener</methodName><params><param><value><int>#{t}</int></value></param><param><value><string>#{username}</string></value></param><param><value><string>#{password}</string></value></param></params></methodCall>"
  encrypted = crypt.encrypt(xml)
  # Use abbreviated approx time for rid
  uri = pandora_rpc_path + "rid=" + time().substr(3) + 'P&method=' + 'authenticateListener'
  opts = {
    host: pandora_host,
    port: pandora_rpc_port,
    path: uri,
    method: 'POST' }
  doHttpPost('authenticateListener', encrypted, opts, cb)

getStations = (t, token, cb) ->
  xml = "<?xml version=\"1.0\"?><methodCall><methodName>station.getStations</methodName><params><param><value><int>#{t}</int></value></param><param><value><string>#{token}</string></value></param></params></methodCall>"
  encrypted = crypt.encrypt(xml)
  # Use abbreviated approx time for rid
  uri = pandora_rpc_path + "rid=" + time().substr(3) + 'P&method=' + 'getStations'
  opts = {
    host: pandora_host,
    port: pandora_rpc_port,
    path: uri,
    method: 'POST' }
  doHttpPost('getStations', encrypted, opts, cb)

doHttpPost = (method, data, opts, cb) ->
  req = http.request(opts, (res) ->
    res.setEncoding('utf8')
    body = ''
    res.on 'data', (chunk) ->
      body += chunk

    res.on 'end', (chunk) ->
      cb(body)
    
    res.on 'error', (chunk) ->
      console.log "err: #{chunk}"
  )
  req.write(data)
  req.end()
    
run = ->
  t = time()
  parser = new xml2js.Parser()
  parser.addListener 'end', (result) ->
    console.log result

  sync (data) ->
    parser.once 'end', (result) ->
      console.log 'Sync token' + result
    parser.parseString(data)

    authUser t, info.username, info.password, (result) ->
      parser.once 'end', (result) ->
        #        console.log JSON.stringify(result.params.param.value.struct, null, ' ')
        result = result.params.param.value.struct
        for r in result.member
          if r.name is 'authToken'
            console.log "authToken: #{r.value}"
            getStations t, r.value, (stations) ->
              parser.once 'end', (result) ->
                stations = result.params.param.value.array.data.value
                console.log 'Stations: '
                for r in stations
                  for a in r.struct.member
                    if a.name is 'stationName'
                      console.log a.value
              parser.parseString(stations)
            
      parser.parseString(result)

run()
