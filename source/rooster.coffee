request = require('request')
cheerio = require('cheerio')
Promise = require 'bluebird'

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

    vakken = {}

    els = $('.container .nobr, .vrij').each (index) ->
      $this = $(this)
      if $this.is '.vrij'
        return

      [docent, vak, lokaal] = $this.contents().filter (i, el) ->
        el.name isnt 'br' # Remove line breakes
      .map (i, el) ->
        $(el).text()

      vakken[index] = [docent, vak, lokaal]
    return vakken

  .then (vakken) -> # Place it in a grid
    # TODO: ^^^

  .catch (err) ->
    console.log err.stack

if not module.parent?
  module.exports process.argv[2]
