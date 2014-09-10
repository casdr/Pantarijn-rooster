request = require('request')
cheerio = require('cheerio')
Promise = require 'bluebird'
_ = require 'lodash'

UREN = 7
DAGEN = ['ma', 'di', 'wo', 'do', 'vr']
TIJDEN = ['08:00', '08:45', '09:50', '10:35', '11:20', '12:30', '13:15', '14:00', '15:00']
base = "http://infoweb.candea.nl"

module.exports = (leerlingnummer, weeknummer) ->
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
    _.map $('.les,.vervallen'), (les) ->
      $les = $(les)

      [tijd, vak, docent, lokaal] = $les.contents().filter (i, el) ->
        el.name isnt 'br' # Remove line breakes
      .map (i, el) ->
        $(el).text()

      dagstr = $les.attr('id').match(/(?:.*)(.{2})(\d{2})/)[1]
      dag = DAGEN.indexOf dagstr
      t = TIJDEN.indexOf tijd.trim()
      if t is -1
        console.log tijd, TIJDEN
      [t, dag, docent, vak, lokaal]


  .then (vakken) -> # Place it in a grid
    dagen = []
    for dag in DAGEN
      dagen.push Array.apply(null, new Array TIJDEN.length).map(-> null)
    for vak,i in vakken
      [tijd, dag, _, _, _] = vak
      if dag is -1
        throw new Error "Wait what... les op #{tijd}??"
      dagen[dag][tijd] = vak
    return dagen

  .catch (err) ->
    console.log err.stack

if not module.parent?
  if process.argv[2]?
    module.exports(process.argv[2], 36).then(console.log)
  else
    console.log 'Geef een leerlingnummer op!'
