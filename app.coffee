info = require('./info.coffee')
pandora = require('./pandora.coffee')

time = ->
  return (new Date().getTime() + '').substr(0,10)
t = time()

User = {
#  authToken: -1
  stations: []
#  currentPlaylist: {}
#  currentStation: -1
}

completedSongs = 0
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
  User.currentPlaylist = data
  for song in User.currentPlaylist
    console.log "#{song.songTitle} - #{song.artistSummary}"
    pandora.getSong(song, info.download_dir)

pandora.addListener 'song', (song, status) ->
  if song.fileState is 'complete'
    # file is fully completed
    console.log "#{song.fileName} completed"

pandora.addListener 'err', (str, data) ->
  console.log "error performing #{str} - #{data}"

pandora.sync()
