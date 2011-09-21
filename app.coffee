# Pandora req
info = require('./info.coffee')
pandora = require('./src/pandora.coffee')
Tag = require('taglib').Tag
# other req
prompt = require('prompt')
colors = require('colors')
path = require('path')
fs = require('fs')
findit = require('findit')

prompt.message = '> '
prompt.delimiter = ''
prompt.start()
clients = {}

time = ->
  return (new Date().getTime() + '').substr(0,10)
t = time()

User = {
#  authToken: -1
  stations: []
  currentPlaylist: []
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

  console.log 'Stations:'
  for stationIndex in [0..(data.length-1)]
    console.log "\t #{stationIndex} - #{data[stationIndex]?.name}"

  prompt.get 'station', (err, result) ->
    User.currentStation = data[result.station]
    pandora.getPlaylist(t, User.authToken, User.currentStation.id, info.audio_format)
#    setInterval((id) ->
#      debug.info "Downloaded #{completedSongs} songs"
#      debug.log 'Getting playlist for ' + User.currentStation.name
#      pandora.getPlaylist(t, User.authToken, User.currentStation.id, info.audio_format)
#    , 180000)

pandora.addListener 'playlist', (data) ->
  debug.info 'Playlist'
  for song in data
    debug.info "\t #{song.songTitle} - #{song.artistSummary}"
    User.currentPlaylist.push(song)

getNextSong = (cb) ->
  if !User.currentPlaylist? or User.currentPlaylist.length <= 1
    if !User.currentStation?
      return
    console.log('Out of items in the playlist, getting a new one')
    pandora.getPlaylist(t, User.authToken, User.currentStation.id, info.audio_format)
   else
     song = User.currentPlaylist.pop()
     User.currentSong = song
     console.log 'getting ' + User.currentSong.songTitle
     pandora.getSong(song)
     if cb?
       cb(song)

pandora.addListener 'song!!', (song, chunk) ->
  if !song.writeStream?
    createSongFile song, info.download_dir, (fileName) ->
      song.writeStream = fs.createWriteStream(fileName + song.fileName, {flags: 'w', encoding: 'binary' }
      # should write tag here if possible
      song.writeStream chunk, 'binary'
  else
      # Write the chunk given
      song.writeStream chunk, 'binary'


  if song.fileState is 'complete'
    # file is fully completed
    song.writeStream.end()
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

createSongFile = (song, dir, cb) ->
   localDir = "#{dir}/#{song.artistSummary}/#{song.albumTitle}/"
   if !song.fileName?
     song.dir = localDir
     song.fileName = "#{song.songTitle}.mp3"
   common.mkdirsP localDir, '0777', (fileName) ->
     cb fileName

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

app = require('http').createServer (req, res) ->
  handler(req, res)

io = require('socket.io')
io = io.listen(app)
io.set 'log level', 1
app.listen 1337

io.sockets.on 'connection', (socket) ->

  clients[socket.id] = socket
  getCredentials(pandora.sync)
  User.currentSong = null
  
  getNextSong (song) ->
    socket.emit 'pandora_newSong', song

  socket.on 'disconnect', ->
    delete clients[socket.id]
  
  pandora.addListener 'song', (song, chunk) ->
    if User.currentSong is null or User.currentSong is song
      User.currentSong = song
      socket.emit 'data', song, chunk

  socket.on 'newSong', ->
    getNextSong (song) ->
      socket.emit 'pandora_newSong', song

songFiles = []

loadFiles = ->
  finder = findit.find('./mp3')
  finder.on 'file', (file) ->
    if file.substr(-4) is '.mp3'
      songFiles.push file

loadFiles()

handler = (req, res) ->
  filePath = '.' + req.url
  if filePath is './'
    filePath = './client.html'
  path.exists filePath, (exists) ->
    if exists
      fs.readFile filePath, (err, data) ->
        if err
          res.writeHead 500
          res.end 'Error loading ' + filePath
        else
          res.writeHead 200, { 'Content-Type': 'text/html' }
          res.end data, 'utf8'
