fs        = require 'fs'
RSVP      = require 'rsvp'
throttle  = require 'rsvp-throttle'
github    = require 'octonode'

repoName  = 'ssured/githubapitest'

# make sure these files exist!
githubCredentials = JSON.parse fs.readFileSync 'credentials.json', 'ascii'

# authenticate and build the promisified repo object
repo = github.client(githubCredentials).repo repoName
for method in ['contents', 'createContents', 'updateContents']
  repo[method] = RSVP.denodeify repo[method], ['data','headers']

# save to github, returns a fixed URL to the file if succesful
sendToGithub = throttle 1, (path, buffer) ->
  console.log '  -  Uploading', buffer.length, 'bytes to', path
  repo.createContents(path, "Automatic upload of data", buffer)
  .then ({data,headers}) ->
    console.log '  -  Uploaded', buffer.length, 'bytes to', path
    data.content.html_url.replace('github.com', 'raw.githubusercontent.com').replace('/blob/', '/')
  .catch (err) ->
    console.log '  -  Upload failed!', path, err
    throw err

[1...10].forEach (testRun) ->
  files = []
  [0...Math.floor(Math.random()*10)].forEach (fileNr) ->
    # create random data
    maxTargetSizeInBytes = 100000
    data = Array.apply(null, new Array(Math.floor(Math.random()*maxTargetSizeInBytes/17))).map(->Math.random().toString(36).substr(2)).join('\n')
    files.push sendToGithub('testdata/data'+ testRun + '-' + fileNr + '.txt', new Buffer(data))

  RSVP.all(files).then (urls) ->
    console.log 'Written', urls.join('\n')
