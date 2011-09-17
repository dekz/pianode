fs = require('fs')
path = require('path')

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

common = { mkdirsP: mkdirsP }
module.exports = common
