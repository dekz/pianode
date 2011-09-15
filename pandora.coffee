crypt = require('./crypt.js')
sys = require('sys')
http = require('http')
xml2js = require('xml2js')
PandoraAPI = require('./PandoraApi.coffee')
info = require('./info.coffee')

parser = new xml2js.Parser()

time = ->
  return (new Date().getTime() + '').substr(0,10)

PandoraUser = {
  username: info.username,
  password: info.password,
  stations: [],
  authToken: "-1"
  audio_format: info.audio_format or 'mp3-hifi'
}

sync = (cb) ->
  PandoraAPI.sync((encrypted, opts) ->
    dohttppost(encrypted, opts, cb))

authUser = (t, username, password, cb) ->
  PandoraAPI.authUser(t, username, password, (encrypted, opts) ->
    dohttppost(encrypted, opts, cb))

getStations = (t, token, cb) ->
  PandoraAPI.getStations(t, token, (encrypted, opts) ->
    dohttppost(encrypted, opts, cb))

getPlaylist = (t, token, stationid, format, cb) ->
  PandoraAPI.getPlaylist(t, token, stationid, format, (encrypted, opts) ->
    dohttppost(encrypted, opts, cb))

dohttppost = (data, opts, cb) ->
  req = http.request opts, (res) ->
    res.setEncoding 'utf8'
    body = ''
    res.on 'data', (chunk) ->
      body += chunk
    res.on 'end', (chunk) ->
      cb(body)
    res.on 'error', (chunk) ->
      console.log "err: #{chunk}"

  req.write data
  req.end()
    
run = ->
  t = time()
  PandoraUser.timeToken = t
  #parser.addListener 'end', (result) ->
  #  console.log result

  sync (data) ->
    parser.once 'end', (result) ->
      console.log 'Sync token' + result
    parser.parseString(data)

    authUser t, info.username, info.password, (result) ->
      parser.once 'end', (result) ->
        result = result.params.param.value.struct
        for r in result.member
          if r.name is 'authToken'
            console.log "authToken: #{r.value}"
            PandoraUser.authToken = r.value
            updateStations()

      parser.parseString(result)

updateStations = ->
  getStations PandoraUser.timeToken, PandoraUser.authToken, (stations) ->
    parser.once 'end', (result) ->
      console.log result
      stations = result.params.param.value.array.data.value
      for r in stations
        station = { otherInfo: r }
        for a in r.struct.member
          if a.name is 'stationName'
            station.name = a.value
          if a.name is 'stationId'
            station.id = a.value
        PandoraUser.stations.push(station)
    parser.parseString(stations)

    for station in PandoraUser.stations
      if station.name is 'chilled'
        getPlaylist(PandoraUser.timeToken, PandoraUser.authToken, station.id, PandoraUser.audio_format,
          handlePlaylist)

handlePlaylist = (data) ->
  parser.once 'end', (result) ->
    result = result.params.param.value.array.data.value
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
          url = v.value.slice(0,-48) + crypt.decrypt(v.value.substr(-48))
          song.audioURL = url
        if v.name is 'audioEncoding'
          song.audioEncoding = v.value
        if v.name is 'artRadio'
          song.artRadio = v.value
        if v.name is 'songDetailURL'
          song.songDetailURL = v.value
      console.log song
  parser.parseString(data)

run()
