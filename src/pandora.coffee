crypt = require('./crypt.js')
sys = require('sys')
http = require('http')
xml2js = require('xml2js')
parser = new xml2js.Parser()
fs = require('fs')

EventEmitter = require('events').EventEmitter
PandoraAPI = require('./PandoraApi.coffee')
Pandora = new EventEmitter()
Proxy = { proxy: false }
Pandora.proxy = Proxy

time = ->
  return (new Date().getTime() + '').substr(0,10)

Pandora.sync = (cb) ->
  PandoraAPI.sync (encrypted, opts) ->
    doHttpReq encrypted, opts, (data, err) ->
      if err?
        Pandora.emit('err', 'sync', err)
        return
      parser.once 'end', (result) ->
        if !result.params?
          handleFault('sync', result)
          return
        else
          result = result.params.param.value
          Pandora.emit('sync', result)
      parser.parseString(data)

Pandora.authUser = (t, username, password, cb) ->
  PandoraAPI.authUser t, username, password, (encrypted, opts) ->
    doHttpReq encrypted, opts, (data, err) ->
      if err?
        Pandora.emit('err', 'auth', err)
        return
      parser.once 'end', (result) ->
        if result.fault? or !result.params?
          handleFault('auth', result)
          return
        else
          result = result.params.param.value.struct
          for r in result.member
            if r.name is 'authToken'
              Pandora.emit('auth', r.value)
       parser.once 'error', (result) ->
         console.log 'error parsing auth: ' + err
      parser.parseString(data)

Pandora.getStations = (t, token, cb) ->
  PandoraAPI.getStations t, token, (encrypted, opts) ->
    doHttpReq encrypted, opts, (data, err) ->
      if err?
        Pandora.emit('err', 'auth', err)
        return
      parser.once 'end', (result) ->
        if !result.params?
          handleFault('stations', result)
          return
        stations = result.params.param.value.array.data.value
        stationList = []
        for r in stations
          station = { otherInfo: r }
          for a in r.struct.member
            if a.name is 'stationName'
              station.name = a.value
            if a.name is 'stationId'
              station.id = a.value
          stationList.push station
        Pandora.emit('stations', stationList)
      parser.parseString(data)

Pandora.getPlaylist = (t, token, stationid, format, cb) ->
  PandoraAPI.getPlaylist t, token, stationid, format, (encrypted, opts) ->
    doHttpReq encrypted, opts, (data, err) ->
      if err?
        Pandora.emit('err', 'playlist', err)
        return
      parser.once 'end', (result) ->
        if !result.params?
          handleFault('playlist', result)
          return
        result = result.params.param.value.array.data.value
        songs = []
        for item in result
          song = { otherInfo: item }
          for v in item.struct.member
            if v.name is 'songTitle'
              song.songTitle = v.value
            if v.name is 'artistSummary'
              song.artistSummary = v.value
            if v.name is 'albumTitle'
              song.albumTitle = v.value
            if v.name is 'audioURL'
              url = v.value.slice(0,-48) + crypt.decrypt v.value.substr(-48)
              song.audioURL = url
            if v.name is 'audioEncoding'
              song.audioEncoding = v.value
            if v.name is 'artRadio'
              song.artRadio = v.value
            if v.name is 'songDetailURL'
              song.songDetailURL = v.value
            if v.name is 'albumTitle'
              song.albumTitle = v.value
            if v.name is 'genre' and v.value.array?
              song.genre = v.value.array.data.value
          songs.push song
        Pandora.emit('playlist', songs)
      parser.parseString(data)

Pandora.getSong = (song, dir) ->
  PandoraAPI.getSong song.audioURL, (encrypted, opts) ->
    req = http.request opts, (res) ->
      res.setEncoding('binary')
      res.on 'data', (chunk) ->
        song.fileState = 'streaming'
        Pandora.emit('song', song, chunk)
      res.on 'end', (chunk) ->
        song.fileState = 'complete'
        Pandora.emit('song', song, chunk)
    req.end()

doHttpReq = (data, opts, cb, encoding) ->
  if Pandora.proxy.proxy
    proxy = Pandora.proxy
    opts.headers = { Host: opts.host }
    opts.host = proxy["proxy_host"]
    opts.port = proxy["proxy_port"]

  req = http.request opts, (res) ->
    res.setEncoding(encoding or 'utf8')
    body = ''
    res.on 'data', (chunk) ->
      body += chunk
    res.on 'end', (chunk) ->
      cb(body)
    res.on 'error', (chunk) ->
      console.log "err: #{chunk}"
  req.write data
  req.end()
    
handleFault = (str, result) ->
  console.log 'Got a fault ' + str
  if result.fault?
    for a in result.fault.value.struct.member
      if a.name is 'faultString'
        Pandora.emit('err', str, result)

module.exports = Pandora
