info = require('./info.coffee')
pandora = require('./pandora.coffee')
Tag = require('taglib').Tag
prompt = require('prompt')
colors = require('colors')

prompt.message = '> '
prompt.delimiter = ''
prompt.start()

time = ->
  return (new Date().getTime() + '').substr(0,10)
t = time()

User = {
#  authToken: -1
  stations: []
#  currentPlaylist: {}
#  currentStation: -1
}

pandora.proxy = { proxy: info.proxy, proxy_host: info.proxy_host, proxy_port: info.proxy_port }

debug = {
  log: (msg) ->
    console.log 'DEBUG: '.grey + msg
  info: (msg) ->
    console.log 'INFO: '.blue + msg
}

completedSongs = 0

pandora.addListener 'sync', (data) ->
  debug.info 'Syncing with pandora. Using proxy? ' + pandora.proxy.proxy
  pandora.authUser(t, info.username, info.password)

pandora.addListener 'auth', (data) ->
  debug.info 'Authed. getting Station list'
  User.authToken = data
  pandora.getStations(t, User.authToken)

pandora.addListener 'stations', (data) ->
  User.stations = data
  for station in data
    if station.name is 'chilled'
      pandora.getPlaylist(t, User.authToken, station.id, info.audio_format)
      User.currentStation = station.id
      setInterval((id) ->
        debug.info "Downloaded #{completedSongs} songs"
        debug.log 'Getting playlist for ' + station.name
        pandora.getPlaylist(t, User.authToken, station.id, info.audio_format)
      , 120000)

pandora.addListener 'playlist', (data) ->
  User.currentPlaylist = data
  debug.info 'Playlist: '
  for song in User.currentPlaylist
    debug.info "\t #{song.songTitle} - #{song.artistSummary}"
    pandora.getSong(song, info.download_dir)

pandora.addListener 'song', (song, status) ->
  if song.fileState is 'complete'
    # file is fully completed
    completedSongs++
    # should tag before writing any data TODO
    tag = new Tag "#{song.dir}#{song.fileName}"
    tag.title = "#{song.songTitle}"
    tag.artist = "#{song.artistSummary}"
    tag.album = "#{song.albumTitle}"
    tag.genre = "#{song.genre}"
    tag.save()

    debug.log "#{JSON.stringify tag}".blue
    debug.log "#{song.songTitle} downloaded to #{song.dir} "

pandora.addListener 'err', (str, data) ->
  console.log "ERR: ".red
  console.log "\t #{str} : #{JSON.stringify data}"

app = () ->
  getCredentials () ->
    pandora.sync()

getCredentials = (cb) ->
  if !info.username?
    prompt.get 'username', (err, result) ->
      info.username = result.username
  if !info.password?
    prompt.get {name: 'password', hidden: true}, (err, result) ->
      info.password = result.password
      cb null
  else
    cb null

app()
