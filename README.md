# Smashing Dev Tool

This is a WIP CLI for Smashing Boxes, focusing on frontend tooling and automation. By following the conventions this tool is built on, you can instantly add front end tooling and dev ops goodness to any Smashing Boxes project. Define which asset filetypes you want to include in your Smashfile and it will build a data model of your source code that can be manipulated and queried by other modules.

The goal of this project is to provide a general toolset for building optimized, well-tested client-side applications with or without backend integration. For this reason, no assumptions are made about 3rd-party libraries that might be used in a given project. Still, some assumptions must be made to maintain a relatively small set of all-purpose commands. Most of these assumptions are captured in `src/config/_smashfile.coffee` and can be overridden in the Smashfile for a given project.

## Prerequisites

+ [Node + NPM](http://nodejs.org/)
+ [Bower](https://www.npmjs.com/package/bower)
+ [CoffeeScript](https://www.npmjs.com/package/coffee-script)

## Installation
`smashing-dev-tool` is available via the NPM registry. It currently depends on Bower and CoffeeScript globally.

```
  $ npm install -g coffee-script bower smashing-dev-tool
```

The `smash` command should now be available globally. Some commands are only available from inside a project with a valid `smashfile.coffee`.



## Available Commands

### Global

+ `smash`: show available commands and options. Same as `smash help`.
+ `smash new <project-name>`: generate a new `smashing-dev-tool`-compatible project in a folder called `<project-name>` and `bower install` dependencies for the chosen template

### Per-project

+ `smash compile`: compile the project source into unoptimized HTML, JS and CSS ready for the browser
+ `smash serve`: run a BrowserSync-based development server and re-compile on file changes
+ `smash build`: build the compiled source into a minified, otpimized set of files for deployment
+ `smash docs`: generate a static documentation site for this codebase
+ `smash clean`: remove all generated files (`/compile`, `/build`, `/docs`)
+ `smash bump [patch|minor|major|prerelease]`: bump the version by the specified importance level and tag the repo (reuqires a `git init`'d project repo)

---

# `smash`-able Projects

## Project Generation

**Command**: `smash new <project-name>`

Smashing Dev Tool borrows from the [Slush](http://slushjs.github.io/) project to allow for straight-forward, stream-based scaffolding from templates. A template consists of a list of questions contained in `prompts.json`, a `bower.json` manifest containing dependencies needed by the template, and a `smashfile.coffee` that contains configuration used by the tool. The remaining files in a template have no restrictions, but should conform to the default folder assumptions (`/client`, `/compile`, `/build`, `/docs`) unless they are overridden in the included `smashfile.coffee`.

During project generation, user input is gathered from the commandline and inserted into the template files using [gulp-template](https://github.com/sindresorhus/gulp-template). Variables can be used in template files as follows:

`prompts.json`:
```json
[
  {
    "name": "appName",
    "message": "What is the name of your project?",
    "default": "Sample Application"
  },
  {
    "name": "appDescription",
    "message": "What is the description?",
    "default": "A sample application."
  }
]
```

`client/index.jade`:
```jade
doctype html
head
  title <%= appNameSlug %>

body
  div.container
    h1 <%= appName %>
    p <%= appDescription %>
```

Files prefixed with `_` will be copied to the destination as dotfiles (`_bowerrc` &rArr; `.bowerrc`) in the generated project. All other files will be copied directly, preserving directory structure and replacing template tags with the appropriate values. After generation [gulp-install](https://github.com/slushjs/gulp-install) will run `bower install` and/or `npm install` inside the project directory. [gulp-conflict](https://github.com/slushjs/gulp-conflict) will prompt the user for action if the project directory contains file conflicts.

_**Note**: at minimum, `appName` is required in `prompts.json` to create a project_

_**Note**: the variable `appNameSlug` is a hyphen-delimited version of `appName` automatically generated and available for use within your templates._


## Compling Code

**Command**: `smash compile`

The compile phase transforms code located in `/client` into browser-ready code located in `/compile`. Preprocessors defined in the Smashfile are run against files with the appropriate extensions (`.coffee`, `.jade`, `.styl`, `.scss`, etc.). Other filetypes defined in the Smashfile are copied directly. The directory structure defined in the source folder (`/client` by default) is maintained in `/compile`.

## Serving Code

**Command**: `smash serve`

Files are served from `/compile` for development using [BrowserSync](http://www.browsersync.io/). Running `smash serve` will compile source files, start a BrowserSync server and open a browser to the server's URL. Changes to filetypes defined in the Smashfile will cause all connected browsers to refresh

## Building Code

**Command**: `smash build`

The build phase will first compile the code, then optimize the contents of `/compile` into a production-ready package. Options such as the name of the output folder (`/build` by default) and whether to build all source into a single file are controlled via the Smashfile.


## Documentation Generation
**Command**: `smash docs`

Smashing Dev Tool currently uses [Groc](https://github.com/nevir/groc) to generate a static documentation site in `/docs`. A `.groc.json` file will be dynamically generated each time the command is run and contains settings required for Groc. These settings are based on the local `bower.json` and settings in `smashfile.coffee`.


## Example Smashfile

In each project the `smashfile.coffee` file contains local config used by `smashing-dev-tool` to compile/build/document client-side assets. Default assumptions made by the tool can be overridden here on a per-project basis. The following configuration overrides many of the default assumptions, but for basic projects only the `assets` array is really needed.

```coffee
module.exports =

  # Global filetype settings. Specifies which files `smashing-dev-tool` cares about.
  assets: [
    'coffee'
    'js'
    'jade'
    'styl'
    'json'
  ]

  # Global directory assumption overrides
  dir:
    client: 'WebContent'
    server: 'src'

  # Global image asset settings
  images:
    path: 'images'                   # override default image asset location (`/client/data/images`)

  # Compile phase settings
  compile:
    copy: [                          # specify file glob patterns to copy directly
      'client/**/*.data':''          # ex: '<file-pattern>':'<path/within/compile/directory>'
    ]

  # Build phase settings
  build:
    path:          'pkg'             # override default build path
    html2js:       true              # compile HTML templates into a JS module
    css2js:        true              # compile CSS styles into a JS module
    includeIndex:  false             # include `index.{html,jade}` in built code
    includeVendor: false             # include vendor libraries in built code
    exclude: [                       # exclude glob patterns from built code
      'client/index.jade'
      'client/main/**/*'
      'client/data/sample/**/*'
    ]
    styles:
      out: 'sample-app.min.css'      # override default concat'd styles filename (css2js)
      order: [                       # re-order styles for injection and concatenation
        'app.css'
        '**/*.css'
      ]
    scripts:
      out: 'sample-app.min.js'       # override default concat'd scripts filename
      order: [                       # re-order scripts for injection and concatenation
        '**/jquery.js'
        '**/*jquery*.*'
        '**/angular.js'
        '**/*angular*.*.js'
        'components/vendor/**/*.js'
        'app.js'
      ]
    views:
      out: 'sample-app-views.js'     # override default concat'd views filename (html2js)

    alternates: [
      [
        'client/app.coffee',         # use `client/app.coffee` during compile and serve
        'client/app-build.coffee'    # use `client/app-build.coffee` when building for production
      ]
    ]
```

_**Note**: the Smashfile format changes frequently as we attempt to strike a balance between convention and configuration._


## TODO/Future
+ Automated testing of source code (unit, e2e)
+ Integration with the [taperole](https://github.com/smashingboxes/taperole) provisioning/deployment tool
+ API mocking, test data generation
+ UI/UX deliverables generated from source code (style tiles, style guide, etc.)
