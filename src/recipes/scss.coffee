autoprefixer = require('autoprefixer')
pxtorem = require('postcss-pxtorem')
lost = require('lost')
scsslintReporter = require('./scsslint-reporter')
sh = require('shelljs');

processors = [
  autoprefixer()
  lost()
  pxtorem({prop_white_list: []})
]

### ---------------- RECIPE ----------------------------------------------- ###
module.exports =
  name: 'recipe-scss'
  attach: ->
    self = @
    @register
      name:   'Sass'
      ext:    'scss'
      type:   'style'
      doc:    false
      test:   false
      lint:   false
      reload: false
      compileFn: (stream) ->
        {files, dest, $, logging, watching, caching, banner, plumbing, stopPlumbing, onError, rootPath} = self.helpers
        {logger, notify, execute, merge, args} = self.util
        {env, dir} = self.project

        # Allow the use of a local scsslint.yml file
        configPath = if sh.test('-f', "#{env.cwd}/scsslint.yml")
          "#{env.cwd}/scsslint.yml"
        else
          "#{rootPath}/src/config/lint/scsslint.yml"

        stream
          .pipe $.sourcemaps.init()
          # .pipe caching 'scss'
          .pipe logging()

          # Lint
          .pipe $.scssLint(
            config: configPath
            customReport: scsslintReporter()
          )

          # Compile
          .pipe $.sass()
          .on('error', onError)
          .pipe $.postcss(processors)


          .pipe $.sourcemaps.write './maps'
