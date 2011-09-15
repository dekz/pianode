info = require('./info.coffee')
pandora = require('./pandora.coffee')

time = ->
  return (new Date().getTime() + '').substr(0,10)
t = time()

User = {
  authToken: -1
  stations: []
  currentPlaylist: {}
  currentStation: -1
}

pandora.addListener 'sync', (data) ->
  pandora.authUser(t, info.username, info.password)

pandora.addListener 'auth', (data) ->
  User.authToken = data
  pandora.getStations(t, User.authToken)

pandora.addListener 'stations', (data) ->
  User.stations = data
  for station in data
    if station.name is 'chilled'
      pandora.getPlaylist(t, User.authToken, station.id, info.audio_format)
      User.currentStation = station.id

pandora.addListener 'playlist', (data) ->
  console.log 'got me a playlist'
  User.currentPlaylist = data
  console.log data

pandora.addListener 'err', (str, data) ->
  console.log "error performing #{str} - #{data}"

pandora.sync()
