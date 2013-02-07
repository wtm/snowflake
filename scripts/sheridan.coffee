# Description:
#   Display today's Sheridan menu.
#
# Commands:
#   hubot sheridan

cp = require 'child_process'
fs = require 'fs'
request = require 'request'

module.exports = (robot) ->
  pdfPath = "/tmp/sheridan.pdf"
  jpgPath = "/tmp/sheridan.jpg"

  robot.router.get '/sheridan.jpg', (req, res) ->
    fs.readFile jpgPath, (err, data) ->
      if err
        res.writeHead 404
        res.end "No menu available."
      else
        res.writeHead 200, 'Content-Type': 'image/jpg'
        res.end data

  robot.respond /sheridan/i, (msg) ->
    msg.http('http://sheridanfruit.com/deli.php').get() (err, res, body) ->
      menuUrl = body.match(/['"](http:\/\/www.sheridanfruit.com\/Common\/Gallery\/Menu[0-9_-]+\.pdf)['"]/i)[1]
      if menuUrl
        downloadMenu(msg, menuUrl)
      else
        msg.send "Couldn't find today's menu."

  downloadMenu = (msg, menuUrl) ->
    msg.send "Downloading #{menuUrl}"
    date = menuUrl.match(/menu.(.*).pdf/i)[1]
    stream = fs.createWriteStream(pdfPath)
    stream.on 'close', -> makeImage msg, pdfPath
    request(menuUrl).pipe(stream)

  imageUrl = ->
    base = process.env.HEROKU_URL or "http://localhost:#{process.env.PORT}"
    "#{base}/sheridan.jpg?#{+new Date()}"

  makeImage = (msg, pdfPath) ->
    cmd = "convert -density 200 #{pdfPath} -scale 1000x1000 -gravity Center -crop 93x38%+5+255! #{jpgPath}"
    cp.exec cmd, (err, stdout, stderr) ->
      if err
        msg.send "Error converting image: #{stderr}"
      else
        msg.send imageUrl()
