fs = require('fs')
strtok = require('strtok')
descriptions = require('./descriptions.coffee').descriptions

module.exports = id3 = {}

isBitSet = (byte, offset, bit) ->
  (byte[offset] & (1 << bit)) isnt 0

getInt24 = (byte, offset, big_endian) ->
  b1 = byte[offset]
  b2 = byte[offset+1]
  b3 = byte[offset+2]

decodeString = (data, charset, start, end) ->
  switch charset
    when 'ascii'
      return { text: data.toString(charset, start, end), length: end-start }
    when 'utf8'
      return { text: data.toString(charset, start, end), length: length: end-start}

  int = if big_endian then (((b1 << 8) + b2) << 8) + b3 else (((b3 << 8) + b2) << 8) + b1
  if int < 0 then int += 1677216
  return int

id3.readTags = (data) ->
  #ID3
  version = data[3]
  if version > 4 then return
  id = {
    version: "2.#{version}.#{data[4]}"
    major: version
    unsync: isBitSet(data, 5, 7)
    xheader: isBitSet(data, 5, 6)
    xindicator: isBitSet(data, 5, 5)
    size: readTagSize(data, 6)
  }
  offset = 10
  if id.xheader
    offset += strok.UINT32_BE.get(data, offset) + 4
  frames = if id.usync then {} else readFrames(data, id, offset, id.size - 10)
  frames.id3 = id
  return frames

readFrames = (data, id, offset, size) ->
  frames = {}
  major = id.major
  frame_header_size = 0
  frame_offset = 0
  while offset < size 
    frame_offset = offset
    flags = null
    frame = { id: null, size: null, description: null, data: null }
    switch major
      when 2
        frame.id = data.toString('ascii', frame_offset, frame_offset+3)
        frame.size = getInt24(data, frame_offset+3, true)
        frame_header_size = 6
      when 3
        frame.id = data.toString('ascii', frame_offset, frame_offset+4)
        frame.size = strtok.UINT32_BE.get(data, frame_offset, frame_offset+4)
        frame_header_size = 10
      when 4
        frame.id = data.toString('ascii', frame_offset, frame_offset+4)
        frame.size = readTagSize(data, frame_offset+4)
        frame_header_size = 10
    if frame.id is '' or frame.id is '\u0000\u0000\u0000\u0000'
      break
    # move to this next frame
    offset += frame_header_size + frame.size
    frame_offset += frame_header_size
    # Get the data of the frame
    frame.data = parse(data, frame.id, frame_offset, frame.size, flags, major)
    # Get a readable description of the tag
    frame.description = descriptions[frame.id]
    console.log frame
  return {}

readTagSize = (data, offset) ->
  if !offset? then offset = 6
  b1 = data[offset]
  b2 = data[offset+1]
  b3 = data[offset+2]
  b4 = data[offset+3]
  return b4 & 0x7f | ((b3 & 0x7f) << 7) | ((b2 & 0x7f) << 14) | ((b1 & 0x7f) << 21)

parse = (data, type, offset, length, flags, major) ->
  if !major?
    major = 3

  if type[0] is 'T'
    type = 'T*'

  switch type
    when 'T*'
      charset = getTextEncoding(offset)
      start = offset
      text = ''
      offset += 1

      if data[start+length-1] is 0 and (start + length - 1) >= offset
        text = decodeString(data, charset, offset, start + length -1).text
      else
        text = decodeString(data, charset, offset, start + length).text
      return text
  return ''

getTextEncoding = (byte) ->
  switch byte
    when 0x00
      return 'ascii'
    when 0x01,0x02
      return 'utf16'
    when 0x03
      return 'utf8'
  return 'utf8'

data = fs.readFileSync('./test/ataraxia.mp3')
console.log id3.readTags(data)
