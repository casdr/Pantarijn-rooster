request = require('request')
cheerio = require('cheerio')
Promise = require 'bluebird'
_ = require 'lodash'

base = "http://school.zermelo.nl/Pantarijn/infoweb"
weeknummer = 38

DAGEN = 5
UREN = 7

module.exports = (leerlingnummer) ->
  request = request.defaults jar: true

  new Promise (yell, cry) ->
    url = "#{base}/selectie.inc.php?wat=week&weeknummer=#{weeknummer}&type=0&groep=&element=&sid=0.7051241090521216"
    request url, (error, response) ->
      if error or  response.statusCode isnt 200
        cry error
      else
        yell()

  .then ->
    new Promise (yell, cry) ->
      url = "#{base}/index.php?ref=2&id=#{leerlingnummer}"
      request url, (error, response, html) ->
        if error or  response.statusCode isnt 200
          cry error
        else
          yell html

  .then (html) ->
    $ = cheerio.load html
    _.map $('.nobr, .vrij'), (les) ->
      $les = $(les)
      if $les.is '.vrij'
        return null

      [docent, vak, lokaal] = $les.contents().filter (i, el) ->
        el.name isnt 'br' # Remove line breakes
      .map (i, el) ->
        $(el).text()

      text = null
      if docent is '... ' or lokaal is '... '
        container = $les.parent().parent().parent()
        hovertext = container.attr('onmouseover').match(/showHoverInfo\('', '(.*)', this\);/)[0]
        text = $(hovertext).text()

      # Fix meerdere docenten
      if docent is '... '
        docent = text.match(/Docenten((?:[a-z]+ )+)/)[1].trim().split(' ')
      else
        docent = [docent]

      # Fix meerdere lokalen
      if lokaal is '... '
        lokaal = text.match(/Lokalen((?:[a-z0-9]+ )+)/)[1].trim().split(' ')
      else
        lokaal = [lokaal]

      [docent, vak, lokaal]


  .then (vakken) -> # Place it in a grid
    dagen = []
    for vak,i in vakken
      dag = Math.floor i % DAGEN
      (dagen[dag] ||= []).push vak
    return dagen

  .catch (err) ->
    console.log err.stack

if not module.parent?
  if process.argv[2]?
    module.exports(process.argv[2]).then(console.log)
  else
    console.log 'Geef een leerlingnummer op!'
