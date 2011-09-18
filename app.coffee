# Pandora req
info = require('./info.coffee')
pandora = require('./src/pandora.coffee')
Tag = require('taglib').Tag
# other req
prompt = require('prompt')
colors = require('colors')
path = require('path')
fs = require('fs')

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
    setInterval((id) ->
      debug.info "Downloaded #{completedSongs} songs"
      debug.log 'Getting playlist for ' + User.currentStation.name
      pandora.getPlaylist(t, User.authToken, User.currentStation.id, info.audio_format)
    , 180000)

pandora.addListener 'playlist', (data) ->
  User.currentPlaylist = data
  debug.info 'Playlist'
  for song in User.currentPlaylist
    debug.info "\t #{song.songTitle} - #{song.artistSummary}"
    pandora.getSong(song, info.download_dir)
    return

pandora.addListener 'song', (song) ->
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
    data = fs.readFile("#{song.dir}#{song.fileName}", 'binary', (err, data) ->
      for s in clients
        s.emit 'data', data
    )

    debug.log "#{JSON.stringify tag}".blue
    debug.log "#{song.songTitle} downloaded to #{song.dir} "

pandora.addListener 'err', (str, data) ->
  console.log "ERR: ".red
  console.log "\t #{str} : #{JSON.stringify data}"

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


app = require('http').createServer((req, res) ->
  handler(req, res)
)
io = require('socket.io')
io = io.listen(app)
app.listen 1337

test = io.of('./test').on('connection', console.log)

io.sockets.on 'connection', (socket) ->

  clients[socket.id] = socket

  socket.on 'disconnect', ->
    for s in clients
      if s.id is socket.id
        console.log 'Remove ' + s.id

  socket.emit 'news', { hello: 'world' }
  socket.on 'my other event', (data) ->
    console.log data

  setTimeout( ->
    fileName = "./mp3/Between The Buried And Me/Alaska/Medicine Wheel.mp3"
    readStream = fs.createReadStream fileName, { 'flags' : 'r', 'encoding': 'binary', 'bufferSize' : 1024*4 }
    readStream.on 'data', (data) ->
      socket.emit 'data', data
  , 1000)

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

run = ->
  #getCredentials(pandora.sync)
  io.set 'log level', 1

run()
