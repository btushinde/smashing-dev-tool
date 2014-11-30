smasher  = require '../config/global'
helpers = require '../utils/helpers'
csslintrc = require '../config/lint/csslintrc'

{args, util, tasks, commander, assumptions, smash, user, platform, project} = smasher
{logger, notify, execute} = util
{assets, env, dir, pkg} = project
{files, banner, dest, time, $, logging, watching} = helpers

cfg =
  csso:                      false # set to true to prevent structural modifications
  css2js:
    splitOnNewline:          true
    trimSpacesBeforeNewline: true
    trimTrailingNewline:     true
  myth:
    sourcemap:               false


### ---------------- RECIPE --------------------------------------------- ###
smasher.recipe
  name:   'CSS'
  ext:    'css'
  type:   'style'
  doc:    true
  test:   true
  lint:   true
  reload: false
  compileFn: (stream) ->
    stream
      # Lint
      .pipe $.csslint csslintrc
      .pipe $.csslint.reporter()

      # Post-process
      # .pipe $.myth cfg.myth

  buildFn: (stream) ->
    stream
      # Optimize
      .pipe $.csso cfg.csso

      # Concat
      .pipe $.if args.watch, $.continuousConcat 'app-styles.css'
      .pipe $.if !args.watch, $.concat 'app-styles.css'
      .pipe $.css2js()
      .pipe $.wrapAmd()

    # Minify


### ---------------- TASKS ---------------------------------------------- ###
# css =
#   compile: ->
#     compile files '.css'
#     .pipe $.if args.watch, $.cached 'css'
#     .pipe logging()
#     .pipe dest.compile()
#     .pipe $.if args.watch, $.remember 'css'
#     .pipe watching()
#
#
#   build: ->
#     build files 'compile', '.css'
#     .pipe logging()
#     .pipe dest.compile()
#     .pipe watching()