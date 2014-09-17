# Een REST server die je de roosters geeft

Sleep = require 'sleeprest'
rooster = require './rooster'

server = new Sleep
server.get (req) ->
  help:
    '/leerling/:nummer': 'Verkrijg het rooster van de leerling met leerlingnummer :nummer.'

server.resource('/leerling/:nummer').get (req) ->
  {nummer} = req.params
  rooster(nummer).then (result) ->
    rooster: result

port = process.argv[2] or 1337
server.listen port
