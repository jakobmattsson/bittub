express = require 'express'
manikin = require 'manikin-mongodb'
nconf = require 'nconf'




models =
  accounts:
    fields:
      name: { type: 'string', unqiue: true, required: true }

  tubs:
    owners: account: 'accounts'
    fields:
      data: 'mixed'
      headers: 'mixed'
      timestamp: 'date'
      ip: 'string'



nconf.env().argv().defaults
  mongo: 'mongodb://localhost/bittub'
  NODE_ENV: 'development'
  PORT: 7777




app = express()
db = manikin.create()
app.use(express.bodyParser())


jsonErr = (res, f) ->
  (err, data) ->
    return res.json({ err: err.toString() || 'sorry' }) if err?
    f(data)



app.get '/', (req, res) ->
  res.send('Maybe you are looking for <a href="/accounts">accounts</a> or <a href="/tubs">tubs</a>')


app.post '/accounts', (req, res) ->
  db.post 'accounts', { name: req.body.name }, jsonErr res, (data) ->
    res.json(data)


app.get '/accounts', (req, res) ->
  db.list 'accounts', {}, jsonErr res, (data) ->
    res.json(data)


app.get '/accounts/:id', (req, res) ->
  db.getOne 'accounts', { filter: { id: req.params.id } }, jsonErr res, (data) ->
    res.json(data)


app.get '/accounts/:account/tubs', (req, res) ->
  db.list 'tubs', { account: req.params.account }, jsonErr res, (data) ->
    res.json(data)


app.get '/accounts/:account/tubs/:tub', (req, res) ->
  db.getOne 'tubs', { filter: { id: req.params.tub, account: req.params.account } }, jsonErr res, (data) ->
    res.json(data)


app.get '/tubs', (req, res) ->
  db.list 'tubs', { }, jsonErr res, (data) ->
    res.json(data)


app.get '/tubs/:tub', (req, res) ->
  db.getOne 'tubs', { filter: { id: req.params.tub } }, jsonErr res, (data) ->
    res.json(data)


app.post '/accounts/:account/tubs', (req, res) ->
  entry = {
    account: req.params.account
    data: req.body
    timestamp: new Date().getTime()
    headers: req.headers
    ip: req.connection.remoteAddress
  }

  db.post 'tubs', entry, jsonErr res, (data) ->
    res.json(data)





db.connect nconf.get('mongo'), models, (err) ->
  return console.log(err) if err?

  port = nconf.get('PORT')
  app.listen(port)
  console.log("app now running at port #{port}")
