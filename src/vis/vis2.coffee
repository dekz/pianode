# Stories in Flight Visualizer courtesy of Thomas Sturm 
# www.storiesinflight.com/jsfft/visualizer_webaudio/

theme = ["rgba(255, 255, 255,","rgba(240, 240, 240,","rgba(210, 210, 210,","rgba(180, 180, 180,","rgba(150, 150, 150,","rgba(120, 120, 150,","rgba(90, 90, 150,","rgba(60, 60, 180,","rgba(30, 30, 180,","rgba(0, 0, 200,","rgba(0, 0, 210,","rgba(0, 0, 220,","rgba(0, 0, 230,","rgba(0, 0, 240,","rgba(0, 0, 255,","rgba(0, 30, 255,","rgba(0, 60, 255,","rgba(0, 90, 255,","rgba(0, 120, 255,","rgba(0, 150, 255,"]
frameBufferSize = 4096
bufferSize = frameBufferSize/4
fft = new FFT(bufferSize, 44100)
albumArt = new Image()

histoindex = 0
histomax = 500

histobuffer_x = new Array()
histobuffer_y = new Array()
histobuffer_t = new Array()
maxvalue = new Array()

for a in [0..histomax]
	histobuffer_t[a] = 0

for a in [0..1024]
	maxvalue[a] = 0

currentValue = new Array()
signal = new Float32Array(bufferSize)
peak = new Float32Array(bufferSize)

class Visualisation

	constructor: (canvas) ->
		@canvas = canvas
		@ctx = canvas.getContext('2d')
		
	
	audioAvailable: (event) ->
		outputArrayL = event.outputBuffer.getChannelData(0)
		outputArrayR = event.outputBuffer.getChannelData(1)
		for i in [0..outputArrayL.length]
			signal[i] = (outputArrayL[i] + outputArrayR[i])/2
		fft.forward(signal)
		magnitude = 0
		for i in [0..bufferSize/8]
			magnitude = fft.spectrum[i]*8000
			currentValue[i] = magnitude
			if magnitude > maxvalue[i]
				maxvalue[i] = magnitude;
				new_pos(@canvas.width/2 + i*4 + 4,(@canvas.height/2)-magnitude-20);
				new_pos(@canvas.width/2 + i*4 + 4,(@canvas.height/2)+magnitude+20);
				new_pos(@canvas.width/2 - i*4 + 4,(@canvas.height/2)-magnitude-20);
				new_pos(@canvas.width/2 - i*4 + 4,(@canvas.height/2)+magnitude+20);
			else
				if maxvalue[i] > 10
					maxvalue[i] -= 5
	
	visualizer: (song) =>
		@ctx.clearRect(0,0, @canvas.width, @canvas.height)
		if song?.artRadio?
			albumArt.src = song.artRadio
			@ctx.globalAlpha = 0.5
			@ctx.drawImage(albumArt, (@canvas.width/2)-(130/2), (@canvas.height/2)-(130/2))

		@ctx.globalAlpha = 1
		for h in [0..histomax]
			if histobuffer_t[h] > 0
				size = histobuffer_t[h] * 4
				@ctx.fillStyle = theme[ (histobuffer_t[h])] + (0.5 - (0.5 - histobuffer_t[h]/40))+')'
				@ctx.beginPath()
				@ctx.arc(histobuffer_x[h], histobuffer_y[h], size * .5, 0, Math.PI*2, true);
				@ctx.closePath()
				@ctx.fill()
	
				histobuffer_t[h] = histobuffer_t[h] - 1
				histobuffer_y[h] = histobuffer_y[h] - 3 + Math.random() * 6
				histobuffer_x[h] = histobuffer_x[h] - 3 + Math.random() * 6
		
new_pos = (x,y) ->
	x = Math.floor(x)
	y = Math.floor(y)
	
	histobuffer_t[histoindex] = 19
	histobuffer_x[histoindex] = x
	histobuffer_y[histoindex++] = y
	
	if histoindex > histomax
		histoindex = 0;
		
root = exports ? this
root.Visualisation = Visualisation
