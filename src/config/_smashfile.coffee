###
Base Smashfile

This serves as the basis for creating per-project smashfiles. These settings
represent the default config for a given version of this tool, and are merged
with the contents of the smashfile for a given project at runtime.
###


module.exports =
  # --- Per-project Smashfiles can't override: ---
  supportedAssets: ['js', 'coffee', 'css', 'styl', 'scss', 'html', 'jade', 'json']


  # --------------------- Config
  banner: ""

  # Client-side code
  client:
    path: 'client'

  # Server-side code
  server:
    path: 'server'

  # 3rd-party libraries
  vendor:
    path: 'client/components/vendor'

  images:
    path: 'data/images'

  fonts:
    path: 'client/data/fonts'


  # File types to handle for a project
  assets: [ ]

  # --------------------- Phases
  # Modules
  modules:
    suffix: '-module'

  # Partials
  partials:
    prefix: '_'

  # Testing
  test:
    prefix: 'test_'

  # Documentation
  docs:
    path: 'docs'


  # Compile phase
  compile:
    path:        'compile'
    html2js:     true
    css2js:      true
    skipPlugins: [ ]
    exclude:     [ ]
    addRootSlash: true

    styles:      { }
    views:       { }
    scripts:     { }
    images:      { }
    fonts:       { }

    styles:
      order: [ ]
    views:
      order: [ ]
    scripts:
      order: [ ]

  # Build Phase
  build:
    path:          'build'
    html2js:       true
    css2js:        true
    skipPlugins:   []
    exclude:       []
    includeIndex:  true
    includeVendor: true
    absolutePath: false
    addAssetPrefix: null
    addRootSlash: true

    styles:
      out: 'app-styles.min.css'
      order: [ ]
    views:
      out: 'app-views.min.js'
      order: [ ]
    scripts:
      out: 'app.min.js'
      order: [ ]

    alternates: [ ]

  # Deploy Phase
  deploy:
    path: 'deploy'

  # Swagger API Framework
  swagger:
    path:                     'schema'
    port:                     3100
    # uiSrc:                  'schema/ui'
    uiUrl:                    '/docs'
    schemaUrl:                '/api-docs'
    schemaFile:               'swagger.json' # can be "swagger.json" or "swagger.yaml"
    # schemaPath:               'schema/definitions'
    partialsIndex:            'index.yml'
    partialsDir:              'definitions'
    controllersDir:           'controllers'
    mockResponses:            true
    parser:
      dereferenceInternal$Refs: true
      dereference$Refs:         true



  # Electron Wrapper
  electron:
    entryPoint: 'compile/index.js'
    src:        'compile'
    release:    'release'
    cache:      'cache'
    version:    'v0.30.0'
    packaging:  false
    platforms:  ['darwin-x64']
