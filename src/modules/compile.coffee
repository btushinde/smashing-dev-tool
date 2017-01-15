gulp    = require 'gulp'
_       = require 'lodash'
del     = require 'del'
chalk   = require 'chalk'
fs      = require 'fs'
q       = require 'q'
nodemon = require 'nodemon'


module.exports = (Smasher) ->
  {recipes, commander, recipes, project, util, helpers}     = Smasher
  {logger, notify, execute, merge, args}                    = util
  {files, $, dest, logging, rootPath, pkg, templateReplace} = helpers
  {dir, assets, supportedAssets}                            = project


  target = null
  compileTasks = ['compile:assets', 'compile:index']
  compileStream = null

  Smasher.on 'clean', -> Smasher.startTask 'compile:clean'


  ### ---------------- COMMANDS ------------------------------------------- ###
  Smasher.command
    cmd: 'compile'
    alias: 'c'
    options: [
      opt: '-c --cat'
      description: 'Output injected index file for inspection'
    ]
    description: 'compile local assets based on Smashfile'
    action: (_target) ->
      target = _target
      compileTasks.push 'compile:serve'  if args.watch
      Smasher.startTask compileTasks

  # Run a local Node server if present
  Smasher.command
    cmd: 'server'
    description: 'run local coffee server'
    options: [
      opt: '--nodemon'
      description: 'Run the server under nodemon'
    ]
    action: ->
      # Just run the server
      unless args.nodemon
        logger.info 'Starting local server...'
        require("#{process.cwd()}/server")

      # Run the server with Nodemon for development reload
      else
        logger.info "Starting local server with #{chalk.cyan 'nodemon'}"
        name = chalk.magenta.underline "[#{project.pkg.npm.name or 'APP'}]"
        app  = chalk.cyan "[nodemon]"
        tag  = "#{app} #{name}"

        config =
          script:      "#{process.cwd()}/server/index.coffee"
          ext:         'coffee js json'
          restartable: 'rs'
          verbose:     args.verbose
          delay:       500
          stdout:      false
          ignore: [
            '.git'
            'node_modules/**/node_modules'
          ]
          watch: [
            "#{process.cwd()}/server/**/*.{coffee,js,json}"
          ]
          env:
            NODE_ENV:  'development'

        nodemon(config)
          .on 'start', ->
            logger.info "#{app} server starting"

          .on 'restart', (files) ->
            logger.info "#{app} restarting server..."
            if files
              logger.data chalk.yellow.bold 'files changed:'
              for file in files
                f = chalk.yellow (file.replace "#{process.cwd()}/", '')
                logger.data "    #{f}"

          .on 'crash', ->
            logger.warn chalk.red "#{app} server CRASHED"

          .on 'exit', ->
            logger.info "#{app} server exiting"

          .on 'stdout', (msg) ->
            logger.info "#{tag} #{chalk.italic msg}"

          .on 'log', ({type, message}) ->
            if args.verbose
              logger.verbose "#{app} #{message.replace process.cwd()+'/', ''}"



  ### ---------------- TASKS ---------------------------------------------- ###
  # Compile assets and start server
  Smasher.task 'compile', ['compile:index'], (done) ->
    Smasher.startTask 'compile:serve'

  # Injects assets into index.jade and compiles
  Smasher.task 'compile:index', ['compile:assets'], ->
    injectIndex = ->
      logger.info "Injecting compiled files into #{chalk.magenta 'index.jade'}"

      vendorFiles = files('vendor', '*', false)
        .pipe $.order(project.compile.scripts.order)
      appFiles = merge [
        files('compile', '.js', true).pipe $.order(project.compile.scripts.order)
        files('compile', '.css', false).pipe $.order(project.compile.styles.order)
      ]

      templateReplace(files path:"#{dir.client}/index.jade")
        .pipe logging()
        .pipe $.inject appFiles,
          name:         'app'
          ignorePath:   dir.compile
          addRootSlash: true
        .pipe $.inject vendorFiles,
          name:         'vendor'
          ignorePath:   dir.client
          addRootSlash: false
        .pipe $.if args.cat, $.cat()
        .pipe $.jade pretty:true, compileDebug:true
        .pipe $.order(project.compile.views.order)
        .on('error', (err) -> logger.error err.message)
        .pipe dest.compile()
        .pipe $.reload stream:true

    if args.watch
      gulp.task 'inject:index:compile', injectIndex
      gulp.watch "#{dir.client}/index.jade", ['inject:index:compile']

    injectIndex()

  # Clear previous compile results and compile all assets
  Smasher.task 'compile:assets', ['compile:clean'], ->
    logger.info "Compiling assets from #{chalk.green './'+dir.client} to #{chalk.magenta './'+dir.compile}"

    toCompile = _
      .chain supportedAssets
      .intersection assets
      .value()

    # source code recipes
    ax = for asset in toCompile
      recipes[asset].watch() if args.watch
      recipes[asset].compile()

    # vendor/data/non-transform recipes
    bx = for asset in ['vendor', 'images', 'fonts']
      recipes[asset].compile()

    # Load recipe definitions from Smashfile
    cx = for asset in project.recipes or []
      recipes[asset.name].compile()


    # Copy additional files
    toMerge = []
    toCopy = project.compile?.copy
    if toCopy?
      c = for cp in toCopy
        k = (_.keys cp)[0]
        v = (_.values cp)[0]
        toMerge.push (gulp.src(k).pipe($.flatten()).pipe gulp.dest "#{dir.compile}/#{v}")

    # merge for joint 'end' event
    toMerge.push merge ax
    toMerge.push merge bx
    toMerge.push merge cx
    merge toMerge
      # .pipe $.using()

  # Compile assets and watch source for changes, recompiling on event
  Smasher.task 'compile:serve', ->
    $.browserSync
      server:
        baseDir:          dir.compile
      watchOptions:
        debounceDelay:  100
      logPrefix:      'BrowserSync'
      # logConnections: true
      # logFileChanges: true
      # logLevel:     'debug'
      notify:         false
      port:           8080
      open: if args.open then true else false

  # Remove previous compilation
  Smasher.task 'compile:clean', (done) ->
    if fs.existsSync dir.compile
      logger.info "Deleting #{chalk.magenta './'+dir.compile}"
      del [dir.compile], done
    else
      done()
