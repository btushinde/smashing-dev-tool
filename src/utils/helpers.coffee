# Project-specific helpers for accessing source code consistiently regardless of project

_ =               require 'lodash'                # array and object utilities
chalk =           require 'chalk'
tildify =         require 'tildify'
moment =          require 'moment'                # time/date utils
open =            require 'open'                  # open files
fs =              require 'fs'
path =            require 'path'                  # manipulate file paths
join =            path.join

gulp =            require 'gulp'                  # streaming build system
lazypipe =        require 'lazypipe'              # re-use partial streams
runSequence =     require 'run-sequence'          # execute tasks in parallel or series

# <br><br><br>


smashRoot = process.mainModule.filename.replace '/bin/smash', ''
smashPkg  = require "#{smashRoot}/package"

{dir, pkg, assumptions, build}          = project       = require '../config/project'
{logger, notify, merge, execute, args} = util    = require '../utils/util'


###
Auto-load all (most) Gulp plugins and attach to `$` for easy access
###
$ = require('gulp-load-plugins')(
  camelize: true
  config: smashPkg
  scope: ['dependencies']
)
$.util =        require 'gulp-util'
$.bowerFiles =  require 'main-bower-files'
$.browserSync = require 'browser-sync'
$.reload =      $.browserSync.reload
# <br><br><br>

logging  = ->  $.if args.verbose, $.using()
watching = ->  $.if args.watch, $.reload(stream: true)
caching  = (cache) ->  $.if args.watch, $.cached cache or 'main'
plumbing = ->  $.if args.watch, $.plumber(errorHandler: console.log)
time     = (f) -> moment().format(f)

isBuilding = _.contains args._, 'build'



# -------------------------------  API  ---------------------------------
module.exports =

  ###
  Plugins
  ###
  $: $
  # <br><br><br>

  ###
  Shortcut for conditional logging, watching in a stream
  ###
  logging:    logging
  watching:   watching
  plumbing:   plumbing
  caching:    caching
  isBuilding: isBuilding
  # <br><br><br>


  ###
  Returns a source stream for a given asset type. This gives us
  a place to attach plugins that should be used for all asset groups
  and allows us to use a much cleaner syntax when building tasks.
  @method files
  @param {...String} types The desired file types
  @return {Object}
  ###
  files: (src, types, read=true, excludes) ->
    fileArgs = arguments

    # Incorporate local build config from smashfile
    buildConfig = _.values(project.build)[0]
    alts = (alt for alt in buildConfig?.alternates)

    # Helpers
    isExt = (s) -> _.isString(s) and s[0] is '.'
    isntExt = (s)-> _.isString(s) and s[0] isnt '.'
    invert = -> _.map(arguments[0], (g) -> "!#{g}")  # negate a glob


    # Build file extension filter
    _filter =
      if      a = _.find(fileArgs, _.isArray) then  a
      else if a = _.find(fileArgs, isExt)     then [a]
      else ['.*']

    # Compute file query folder/scope
    _target =
      if _.find(fileArgs, _.isPlainObject) then 'path'
      else if a = _.find(fileArgs, isntExt)
        if _.contains(['vendor', 'build', 'compile', 'test'], a) then a else 'client'
      else 'client'

    # Find `read` flag
    _read =
      if (reed = _.find fileArgs, _.isBoolean)? then reed
      else if _config?.read? then _config.read
      else true

    # Find config object
    _config = if a = _.find(fileArgs, _.isPlainObject) then a else {}

    # Compute base path
    _base = if _config?.path? then _config.path else dir[_target]


    # Glob helpers
    getExcludes = ->
      ex = switch
        when _.isString excludes  then [excludes]
        when _.isArray excludes   then  excludes
        else []
      if isBuilding and buildConfig.exclude?
        ex = ex.concat buildConfig.exclude
      invert ex

    getAlternates = ->
      for alt in alts
        if isBuilding
          "!#{alt[0]}"
        else
          "!#{alt[1]}"

    globs =
      vendor:       ["**/components/vendor{,/**}"]
      vendorMain:   $.bowerFiles filter:new RegExp _filter.join '|'
      test:         ["#{dir.client}/**/*_test*"]
      index:        ["#{dir.client}/index.*"]
      alternates:   getAlternates() or []
      exclude:      getExcludes() or []

    # Build source glob for Gulp
    srcBase = ["#{_base}/**/*+(#{ _filter.join '|' })"]
    source = switch _target
      when 'client', 'compile', 'build'
        srcBase
          .concat globs.exclude
          .concat invert globs.test
          .concat globs.alternates
          .concat invert globs.vendor

      when 'test'   then globs.test
      when 'vendor' then globs.vendorMain
      when 'path'
        ex = if isBuilding and buildConfig.exclude? then invert buildConfig.exclude else []
        if _config.path.indexOf '.' >= 0 then [_config.path].concat ex else srcBase.concat ex
      else logger.error "!! Unknown file target '#{src}'. Could not build stream."

    if args.debug
      logger.debug
        target: chalk.red _target
        base:   chalk.green _base
        filter: chalk.yellow _filter
        read:   chalk.red _read
        path:   chalk.magenta _config?.path or ''
        exclude: chalk.yellow globs.exclude
      logger.debug chalk.magenta srcBase
      console.log source

    gulp.src source, read: _read, base: dir[_target] or ''
  # <br><br><br>

  ###
  A collection of destination objects targeting folders from
  the project config. A shortcut for having to write `.pipe(gulp.dest dir compile)`
  ###
  dest:
    compile:       ->  gulp.dest dir.compile
    build:         ->  gulp.dest dir.build
    deploy:        ->  gulp.dest dir.deploy
    client:        ->  gulp.dest dir.client
    compileVendor: ->  gulp.dest dir.vendor
  # <br><br><br>

  ###
  Returns the current time with the given format
  @method time
  @param {String} format moment.js time format
  @return {Object}
  ###
  time: time
  # <br><br><br>

  ###
  Banner placed at the top of all JS files during development.
  Overridden by value of `banner` from Smashfile unless null
  TODO: add Git branch and SHA
  ###
  banner: project?.banner or "/** \n
                              * #{pkg.name}  \n
                              * v. #{pkg.version}  \n
                              * \n
                              * Built #{time 'dddd, MMMM Do YYYY, h:mma'}  \n
                              */ \n\n"
  # <br><br><br>
