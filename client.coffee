player = null
stream = null
currentSong = null
socket = null
vis = null

load = ->
  playing_time = $("#playing_time")
  $("#nextSong").click(nextSong)
  canvas = $("#fft")[0]
  socket = io.connect('http://localhost:1337')

  socket.emit('newSong');

  buffer = ''

  socket.on 'data', (song, data) ->
    if !vis?
      vis = new Visualisation(canvas)
      vis.visualizer()

    if !currentSong?
      currentSong = song
    
    if song.songTitle is currentSong.songTitle
      if stream?
        stream.buffer data
      else
        if buffer.length+data.length >= 1024
          stream = new Mad.StringStream(buffer+data)
          buffer = ''
          $("#album_art").attr("src", song.artRadio)
          $("#id3_artist_name").text(song.artistSummary)
          $("#id3_song_title").text(song.songTitle)

          if !player?
            player = new Mad.Player(stream)
            player.createDevice()

            player.onProgress = (playtime, total, preloaded) ->
              playing_time.text(secondsToHms(playtime))
              if total is playtime and playtime isnt 0
                console.log 'Getting a new song'
                nextSong()
            
            player.onPlay = () ->
              $("#toggle_play_button").text("Pause")
            
            player.onPause = () ->
              $("#toggle_play_button").text("Play")

            player.setPlaying(true)

            oldAudioProcess = player.dev._node.onaudioprocess
            newAudioProcess = (e) ->
              oldAudioProcess(e)
              vis.audioAvailable(e)

            player.dev._node.onaudioprocess = newAudioProcess
        else
          buffer += data

nextSong = ->
  if player?
    player.setPlaying(false)
    player.destroy()
    player = null
    currentSong = null
    stream = null
    socket.emit('newSong')

pause = ->
  if player?
    player.setPlaying(!player.playing)
    $("#toggle_play_button").text(player.playing ? "Pause" : "Play")

secondsToHms = (d) ->
    d = Number(d)
    h = Math.floor(d / 3600)
    m = Math.floor(d % 3600 / 60)
    s = Math.floor(d % 3600 % 60)
    return ((h > 0 ? h + ":" : "") + (m > 0 ? (h > 0 && m < 10 ? "0" : "") + m + ":" : "0:") + (s < 10 ? "0" : "") + s)

load()