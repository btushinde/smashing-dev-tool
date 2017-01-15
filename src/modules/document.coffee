gulp    = require 'gulp'
_       = require 'lodash'
del     = require 'del'
chalk   = require 'chalk'
fs      = require 'fs'
open    = require 'open'

module.exports = (Smasher) ->
  {commander, assumptions, user, platform, project, util, helpers} = Smasher
  {args, logger, notify, execute, merge} = util
  {files, dest, $, logging, watching, rootPath, pkg} = helpers
  {assets, dir, env} = project

  Smasher.on 'clean', -> Smasher.startTask 'docs:clean'


  ### ---------------- COMMANDS ------------------------------------------- ###
  Smasher.command
    cmd: 'docs'
    options: [
      opt: '--open'
      description: 'Opens a browser to the relavent location once the task has finished'
    ]
    description: 'Generate documentation based on source code'
    action: ->
      Smasher.startTask 'docs'


  ### ---------------- TASKS ---------------------------------------------- ###
  Smasher.task 'docs', ['docs:clean'], (done) ->
    # notify "Groc", "Generating documentation..."
    logger.info "Generating documentation in #{chalk.magenta './'+dir.docs}"
    pkg = project.pkg.bower or project.pkg.npm

    docsGlob = ["**/*.md"]
    for asset in assets
      docsGlob.push "#{dir.client}/**/*.#{asset}"

    grocjson = JSON.stringify {
      'glob': docsGlob
      'except': [
        "#{dir.client}/components/vendor/**/*"
        "#{dir.client}/index.jade"
      ]
      'index':            'README.md'
      'index-page-title': "#{pkg.name} - docs"
      'github':           false
      'out':              dir?.docs
      'repository-url':   pkg.repository or ''
      'silent':           args.mute
      'verbose':          args.verbose
    }, null, 2


    # Dynamically generate .groc.json from config
    fs.writeFile "#{env.configBase}/.groc.json", grocjson, 'utf8', ->
      logger.info "Generated dynamic #{chalk.green '.groc.json'} from project config"  if args.verbose

      # Use our copy of Groc to generate documentation for the project
      # require("#{rootPath}/node_modules/groc").CLI [], (error)->
      console.log 'getting groc...'
      require('groc').CLI [], (error)->
        process.exit(1) if error
        # notify "Groc", "Success!"
        open("#{dir.docs}/index.html")  if args.open
        done()

  Smasher.task 'docs:clean', (done) ->
    if fs.existsSync dir.docs
      logger.info "Deleting #{chalk.magenta './'+dir.docs}"
      del [dir.docs], done
    else
      done()
