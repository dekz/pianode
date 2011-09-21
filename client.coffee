player = null
stream = null
currentSong = null
socket = null
vis = null

load = ->
  playing_time = $("#playing_time")
  $("#toggle_play_button").click(pause)
  $("#nextSong").click(nextSong)
  canvas = $("#fft")[0]
  socket = io.connect('http://localhost:1337')
  socket.emit('test');
  socket.emit('newSong');

  buffer = ''
  visTimer = null

  socket.on 'pandora_newSong', (song) ->
    console.log song

  
  socket.on 'data', (song, data) ->
    if stream?
      stream.buffer data
    else
      if buffer.length+data.length >= 512
        stream = new Mad.StringStream(buffer+data)
        # TODO remove this options setting of nothing
        stream.options = {}
        buffer = ''

        $("#id3_artist_name").text(song.artistSummary)
        $("#id3_song_title").text(song.songTitle)

        if !currentSong?
          currentSong = song

        if !vis?
          vis = new Visualisation(canvas)
          vis.visualizer(song)
    
        if !visTimer?
          visTimer = setInterval ->
             vis.visualizer(song)
          , 50

        if !player?
          player = new Mad.Player(stream)
          # Create a new Audio device and change the event to 
          # also call the visualizer
          player.createDevice ->
            oldAudioProcess = player.dev._node.onaudioprocess
            newAudioProcess = (e) ->
              oldAudioProcess(e)
              vis.audioAvailable(e)
            player.dev._node.onaudioprocess = newAudioProcess

          player.onPlay = () ->
            $("#toggle_play_button").text("Pause")
          
          player.onPause = () ->
            $("#toggle_play_button").text("Play")

          player.setPlaying(true)

          player.onProgress = (playtime, total, preloaded) ->
            playing_time.text(secondsToHms(playtime))
            delta = playtime
            if total is playtime and playtime isnt 0
              nextSong()
      else
        buffer += data
  
  

nextSong = ->
  if player?
    player.setPlaying(false)
    player.destroy()
    player = null
    currentSong = null
    stream = null
  clearInterval(visTimer)
  visTimer = null
  socket.emit('newSong')

pause = ->
  if player?
    player.setPlaying(!player.playing)
    $("#toggle_play_button").text(if player.playing then "Pause" else "Play")

secondsToHms = (d) ->
    d = Number(d)
    h = Math.floor(d / 3600)
    m = Math.floor(d % 3600 / 60)
    s = Math.floor(d % 3600 % 60)
    out = ((if h > 0 then h + ':' else '') + (if m > 0 then (if h > 0 and m < 10 then '0' else '') + m + ':' else '0:') + (if s < 10 then '0' else '') + s)


load()