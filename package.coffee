name: 'pianode'
description: 'Pandora client'
keywords: ['pianode', 'pandora', 'mp3', 'music']
version: require('fs').readFileSyc('./VERSION')

author: 'dekz <dekz@dekz.net>'

licences: [
  type: 'FEISTY'
  url: 'http://github.com/feisty/license/raw/master/LICENSE'
]

contributors: ['dekz <dekz@dekz.net>']

repository:
  type: 'git'
  url: 'https://github.com/dekz/pianode.git'
  private: 'git@github.com/:dekz/pianode.git'
  web: 'https://github.com/dekz/pianode'

main: 'app.coffee'

dependencies:
  'coffee-script' : '>= 1'
  'xml2js' : '>= 0.1'

engines:
  node: '>= 0.4.0'
  npm: '>= 0.3.15'
