coffeeStylish = require('coffeelint-stylish').reporter
coffeelintrc  = require '../config/lint/coffeelintrc'
lazypipe      = require 'lazypipe'

module.exports = (globalConfig) ->
  {args, util, tasks, recipes, commander, assumptions, smash, user, platform, getProject} = globalConfig
  {logger, notify, execute} = util

  {assets, env, dir, pkg, helpers} = project = getProject()
  {files, banner, dest, time, $, logging, watching} = helpers

  ### ---------------- RECIPE --------------------------------------------- ###
  compile = (stream) ->
    stream
      .pipe $.if args.watch, $.cached 'main'
      .pipe logging()

      # Compile
      .pipe $.jade pretty:true, compileDebug:true
      .on('error', (err) -> logger.error err.message)

  ### ---------------- TASKS ---------------------------------------------- ###
  jade =
    compile: ->
      compile files '.jade'
        .pipe dest.compile()
