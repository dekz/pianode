pandora_host = "www.pandora.com"
pandora_rpc_port = 80
pandora_protocol_version = "31"
pandora_rpc_path = "/radio/xmlrpc/v" + pandora_protocol_version + "?"

crypt = require('./crypt.js')

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
  cb(encrypted, opts)

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
  cb(encrypted, opts)

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
  cb(encrypted, opts)

getPlaylist = (t, token, stationId, format, cb) ->
  xml = "<methodCall><methodName>playlist.getFragment</methodName><params><param><value><int>#{t}</int></value></param><param><value><string>#{token}</string></value></param><param><value><string>#{stationId}</string></value></param><param><value><string>0</string></value></param><param><value><string></string></value></param><param><value><string></string></value></param><param><value><string>#{format}</string></value></param><param><value><string>0</string></value></param><param><value><string>0</string></value></param></params></methodCall>"
  encrypted = crypt.encrypt(xml)
  # Use abbreviated approx time for rid
  uri = pandora_rpc_path + "rid=" + time().substr(3) + 'P&method=' + 'getFragment'
  opts = {
    host: pandora_host,
    port: pandora_rpc_port,
    path: uri,
    method: 'POST' }
  cb(encrypted, opts)
 
getSong = (url, cb) ->
  url = url.replace('http://', '')
  endOfHost = url.lastIndexOf('pandora.com')+11
  opts = {
    host: url.substr(0, endOfHost)
    port: pandora_rpc_port,
    path: url.substr(endOfHost, url.length),
    method: 'GET' }
  cb('', opts)

module.exports = {
  authUser: authUser,
  getStations: getStations,
  getPlaylist: getPlaylist,
  sync: sync,
  getSong: getSong,
  pandora_host: pandora_host,
  pandora_rpc_port: pandora_rpc_port,
  pandora_rpc_path: pandora_rpc_path,
  pandora_protocol_version: pandora_protocol_version
}
