gulp    = require 'gulp'
_       = require 'lodash'
del     = require 'del'
chalk   = require 'chalk'
fs      = require 'fs'

module.exports = (Smasher) ->
  {commander, assumptions, user, platform, project, recipes, util, helpers} = Smasher
  {logger, notify, execute, merge, args} = util
  {files, $, dest, onError, rootPath, pkg, logging, templateReplace} = helpers
  {dir} = project

  target        = project.dir?.build
  buildOpts     = null
  buildTasks    = null
  includeVendor = null
  includeIndex  = null

  cfg =
    ngAnnotate:
      remove: false
      add: true
      single_quote: true
    ngHtml2js:
      moduleName: "templates-main"
      prefix: ''
    css2js:
      splitOnNewline:          false
      trimSpacesBeforeNewline: false
      trimTrailingNewline:     true
    uglify:
      mangle: false
      preserveComments: 'some'

  revAll = new $.revAll()

  Smasher.on 'clean', -> Smasher.startTask 'build:clean'

  ### ---------------- COMMANDS ------------------------------------------- ###
  Smasher.command
    cmd: 'build [target]'
    alias: 'b'
    description: 'build local assets for production based on Smashfile'
    options: [
      opt: '-c --cat'
      description: 'Output injected index file for inspection'
    ]
    action: (_target) ->
      buildOpts     = project.build or {}
      target        = buildOpts.out or project.dir.build
      includeVendor = if buildOpts.includeVendor? then buildOpts.includeVendor else true
      includeIndex  = if buildOpts.includeIndex? then buildOpts.includeIndex else true

      buildTasks = if includeIndex then ['build:index']
      else ['build:assets']
      Smasher.startTask buildTasks


  ### ---------------- TASKS ---------------------------------------------- ###
  # Build assets and start server
  Smasher.task 'build', ['build:index'], (done) ->
    Smasher.startTask 'build:serve'

  # Build assets from compiled source
  Smasher.task 'build:assets', ['build:clean', 'compile:assets'], ->
    JSoutfile   = recipes.js.getOutFile()
    CSSoutfile  = recipes.css.getOutFile()
    HTMLoutfile = recipes.html.getOutFile()
    css2js      = project.build.css2js
    html2js     = project.build.html2js

    target ?= 'build'
    logger.info "Building assets from #{chalk.magenta './'+dir.compile} to #{chalk.red './'+target}"


    # ------------------CSS-----------------------
    cssVendor = files('vendor', '.css', true)
    cssApp    = recipes['css'].build(false)
    _css = [ cssApp ]
    _css.push cssVendor if includeVendor
    css = merge _css
      .pipe $.order project.build.styles.order
      .pipe $.concat CSSoutfile
      .pipe $.if css2js, $.css2js(cfg.css2js)
      .pipe $.if !css2js, revAll.revision()

    # ------------------HTML-----------------------
    htmlVendor = files('vendor', '.html', true)
    htmlApp    = recipes['html'].build(false)
    _html = [ htmlApp ]
    _html.push htmlVendor if includeVendor
    html = merge _html
      .pipe $.if html2js, $.order      project.build.views.order
      .pipe $.if html2js, $.ngHtml2js  cfg.ngHtml2js
      .pipe $.if html2js, $.ngAnnotate cfg.ngAnnotate
      .pipe $.if html2js, $.concat     HTMLoutfile

    # ------------------JS-------------------------
    jsVendor = files('vendor', '.js', true)
    jsApp    = recipes['js'].build(false)
    _js = [ jsApp ]
    _js.push jsVendor if includeVendor
    _js.push css      if css2js
    _js.push html     if html2js
    js = merge _js
      .pipe $.order  project.build.scripts.order
      .pipe $.concat JSoutfile
      .pipe $.uglify cfg.uglify
      .pipe $.if     args.cat, $.cat()
      .pipe revAll.revision()


    ### ------------------APP------------------ ###
    app = [
      js
      recipes.images.build(false)
      recipes.fonts.build(false)
    ]
    app.push css   unless css2js
    app.push html  unless html2js
    merge app
      .pipe $.plumber()
      .pipe gulp.dest target


  Smasher.task 'build:index', ['build:assets'],  ->
    logger.verbose "Injecting built files into #{chalk.magenta 'index.jade'}"
    appFiles = merge [
      files('build', '.js',  true).pipe $.order(project.build.scripts.order)
      files('build', '.css', false).pipe $.order(project.build.scripts.order)
    ]

    templateReplace(files path:"#{dir.client}/index.jade")
      .pipe logging()
      .pipe $.inject appFiles,
        name:         'app'
        ignorePath:   dir.build
        addRootSlash: project.build.addRootSlash or true
        addPrefix:    project.build.addAssetPrefix
      .pipe $.if args.cat, $.cat()
      .pipe $.jade compileDebug:true
      .on('error', (err) -> logger.error err.message)
      .pipe gulp.dest target

  Smasher.task 'build:serve', ->
    $.browserSync
      server:
        baseDir:       target
      watchOptions:
        debounceDelay:  100
      logPrefix:      'BrowserSync'
      logConnections: args.verbose
      logFileChanges: args.verbose
      # logLevel:     'debug'
      notify:         false
      port:           8080

  Smasher.task 'build:clean', (done) ->
    toDelete = []
    if fs.existsSync dir.build
      logger.info "Deleting #{chalk.magenta './'+dir.build}"
      del [dir.build], done
    else if fs.existsSync project.build.out
      logger.info "Deleting #{chalk.magenta './'+project.build.out}"
      del [project.build.out], done
    else
      done()
