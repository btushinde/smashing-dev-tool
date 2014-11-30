smasher = require '../config/global'
util = require '../utils/util'
helpers = require '../utils/helpers'

{args, tasks, recipes, commander, assumptions, rootPath, user, platform, project} = smasher
{logger, notify, execute, merge} = util
{dir, env} = project
{files, dest, $, logging, watching, banner} = helpers

coffeeStylish = require('coffeelint-stylish').reporter
coffeelintrc = require '../config/lint/coffeelintrc'


### ---------------- RECIPE --------------------------------------------- ###

smasher.recipe
  name:      'CoffeeScript'
  ext:       'coffee'
  type:      'script'
  doc:       true
  test:      true
  lint:      true
  reload:    true
  compileFn: (stream) ->
    stream
      .pipe $.if args.watch, $.cached 'main'
      .pipe logging()

      # Lint
      .pipe $.coffeelint coffeelintrc
      .pipe $.coffeelint.reporter()
      .pipe $.coffeelint.reporter "fail"

      # Compile
      .pipe $.coffee bare:true

      # Post-process
      .pipe $.header banner