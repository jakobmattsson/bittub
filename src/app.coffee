util = require 'util'
express = require 'express'
manikin = require 'manikin-mongodb'
nconf = require 'nconf'
resterTools = require 'rester-tools'
rss = require 'rss'




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
  hostname: 'localhost'




app = express()
db = manikin.create()
app.use(express.bodyParser())
app.use(resterTools.replaceContentTypeMiddleware({ 'text/plain': 'application/json', '': 'application/json' }))
app.use(resterTools.corsMiddleware())


bittubUrl = 'http://' + nconf.get('hostname') + ":" + nconf.get('PORT')




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


app.get '/accounts/:account/rss', (req, res) ->
  db.list 'tubs', { account: req.params.account }, jsonErr res, (data) ->

    data.sort (a, b) ->
      new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()

    feed = new rss
      title: "BitTub feed for account #{req.params.account}"
      description: "BitTub feed for account #{req.params.account}"
      feed_url: "#{bittubUrl}/accounts/#{req.params.account}/rss"
      site_url: bittubUrl
      # image_url: 'http://example.com/icon.png'
      author: 'BitTub'

    data.forEach (item) ->
      feed.item
        title: "#{item.ip}+#{new Date(item.timestamp).getTime()}"
        description: util.inspect(item.data)
        url: "#{bittubUrl}/accounts/#{item.account}/tubs/#{item.id}"
        date: item.timestamp

    res.set('content-type', 'application/rss+xml')
    res.send(feed.xml())


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
