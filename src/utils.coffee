fs = require 'fs'
path = require 'path'

mkdirsP = (p, mode, f) ->
  paths = path.normalize(p).split('/')
  if path.existsSync p
    f p
  if p.charAt(0) is '.'
    current = '.'
  for dir in paths
    current += "/#{dir}"
    if not path.existsSync current
      fs.mkdirSync current, mode
  f p

isBitSet = (byte, offset, bit) ->
  (byte[offset] & (1 << bit)) isnt 0

getInt24 = (byte, offset, big_endian) ->
  b1 = byte[offset]
  b2 = byte[offset+1]
  b3 = byte[offset+2]

getTextEncoding = (byte) ->
  switch byte
    when 0x00
      return 'ascii'
    when 0x01,0x02
      return 'utf16'
    when 0x03
      return 'utf8'
  return 'utf8'

findZero = (data, start, end) ->
  i = start
  while data[i] is 0
    if i >= end
      return end
    i++
  return i

common =
  mkdirsP: mkdirsP
  isBitSet: isBitSet
  getInt24: getInt24
  getTextEncoding: getTextEncoding
  findZero: findZero

module.exports = common