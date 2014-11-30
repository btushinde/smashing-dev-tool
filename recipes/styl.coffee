
smasher  = require '../config/global'
helpers = require '../utils/helpers'

{args, util, tasks, recipes, commander, assumptions, smash, user, platform, project} = smasher
{logger, notify, execute} = util
{assets, env, dir, pkg} = project
{files,  banner, dest, time, $, logging, watching} = helpers


### ---------------- RECIPE ----------------------------------------------- ###
smasher.recipe
  name:   'Stylus'
  ext:    'styl'
  type:   'style'
  doc:    false
  test:   false
  lint:   false
  reload: false
  compileFn: (stream) ->
    stream
      .pipe $.if args.watch, $.cached 'styl'
      .pipe logging()

      # Compile
      .pipe $.stylus()
      .on('error', (err) -> logger.error err.message)