gulp = require 'gulp'
gutil = require 'gulp-util'
rename = require 'gulp-rename'
sketch = require 'gulp-sketch'
svgmin = require 'gulp-svgmin'
cheerio = require 'gulp-cheerio'
convert = require 'gulp-rsvg'
iconfont = require 'gulp-iconfont'
shell = require 'gulp-shell'
consolidate = require 'gulp-consolidate'
jsoneditor = require 'gulp-json-editor'
jsonminify = require 'gulp-jsonminify'
less = require 'gulp-less'
LessPluginAutoPrefix = require 'less-plugin-autoprefix'
minifyCSS = require 'gulp-minify-css'
minifyHTML = require 'gulp-minify-html'
fs = require 'fs'
path = require 'path'
_ = require 'lodash'

# https://github.com/svg/svgo/tree/master/plugins
# We use these plugins for all our svg optimizing.
svgoPluginOpts = [
  { removeViewBox: false }
  { removeDesc: true }
  { removeTitle: true }
  { removeRasterImages: true }
  { cleanupNumericValues: false }
]

# This is the distance between the edge of the glyph and the edge of the file.
# For instance, for 16pt18box, the glyph will be 16x16 points, and have a
# 1 point margin on all sides.

# If you want to add more sizes, you can follow the same format, but be sure to
# add to the tasks at the bottom.
sizes = {
  '16pt18box': { size: 16, box: 18 }
  '20pt24box': { size: 20, box: 24 }
  '30pt32box': { size: 30, box: 32 }
}

# This is the thickness of the line in the icon.
weights = [
  '100'
  '500'
]

getUnits = (size, box) ->
  # Hard dependancy on 1920 x 1920 SVGs…
  boxDelta = box - size
  boundingUnits = ((1920 / size) * boxDelta)
  viewBoxValue = 1920 + boundingUnits
  viewBox = "0 0 #{viewBoxValue} #{viewBoxValue}"
  translateDiff = boundingUnits / 2
  translate = "translate(#{translateDiff} #{translateDiff})"
  # Points don't make sense for web screens, but these outputs are primarily
  # for android.
  box = "#{box}pt"
  return { box, viewBox, translate }


# Export from Sketch. This will export all the weights, so long as they are
# artboards.
gulp.task 'sketch', ->
  gulp
    .src ['./src/sketch/*.sketch']
    .pipe sketch
      export: 'artboards'
      formats: 'svg'
    .pipe gulp.dest './build/exports/'


# Tasks for individual sizes.
gulpSizeTask = (weight, size, box, viewBox, translate) ->
  key = "#{weight}-#{size}"

  gulp.task key, ['sketch'], ->
    gulp
      .src ["./build/exports/#{weight}/*.svg"]
      .pipe cheerio({
        run: ($, file, done) ->
          $('svg')
            .attr({ 'height': box, 'width': box })
            .attr({ 'viewBox': viewBox })
          $('svg > g').attr({ 'transform': translate })
          done()
        # SVG is XML so this turns out to be pretty important.
        # The output is mangled without it.
        parserOptions: {
          xmlMode: true
        }
      })
      .pipe svgmin
        plugins: svgoPluginOpts
      .pipe rename
        prefix: 'ic_'
        suffix: "_#{weight}_#{size}"
      # Sure, you could use these SVGs for any platform, but we have Android in
      # mind here.
      .pipe gulp.dest("./build/weights/#{weight}/#{size}/android")
      # iOS uses PDFs.
      .pipe cheerio({
        # For iOS PDFs, use a pixel value. It will get converted to pixels
        # anyway.
        run: ($, file, done) ->
          pxBox = box.replace("pt", "px")
          $('svg')
            .attr({ 'height': pxBox, 'width': pxBox })
          done()
        parserOptions: {
          xmlMode: true
        }
      })
      .pipe convert({format: 'pdf'})
      .pipe gulp.dest("./build/weights/#{weight}/#{size}/ios")


# For each weight, export for various sizes.
for weight in weights

  do (weight) ->
    paths = {
      sketchFiles: ["./src/sketch/#{weight}/*.sketch"]
      exportSvgs: ["./build/exports/#{weight}/*.svg"]
    }

    # Now, the various sizes…
    for size, value of sizes
      # getUnits does all the math for the defined size and bounding box, then
      # adds a gulp task for each.
      units = getUnits(value.size, value.box)
      gulpSizeTask(weight, size, units.box, units.viewBox, units.translate)

    # We also want the full SVGs without modified height, width, or margin.
    gulp.task "#{weight}-full", ["sketch"], ->
      gulp
        .src paths.exportSvgs
        .pipe svgmin
          plugins: svgoPluginOpts
        .pipe gulp.dest("./build/weights/#{weight}/full/")

    # Build the icon font. We mainly use this for rudimentary testing and use
    # Icomoon for production.
    gulp.task "#{weight}-font", ["sketch"], ->

      gulp
        .src paths.exportSvgs
        .pipe svgmin
          plugins: svgoPluginOpts
        .pipe iconfont
          fontName: "trellicons-#{weight}"
          fixedWidth: true
          centerHorizontally: true
        .on 'codepoints', (codepoints, options) ->
          # Outputs a CSS file with the right characters.
          templateData = {
            glyphs: codepoints
            className: 'icon'
            weight: weight
            fontName: options.fontName
          }
          gulp
            .src './src/demo/templates/icon-css-points.tmpl'
            .pipe consolidate 'lodash', templateData
            .pipe rename 'icon-points.less'
            .pipe gulp.dest "./build/weights/#{weight}/fonts"
        .pipe gulp.dest "./build/weights/#{weight}/fonts"


gulp.task 'demo', ['500-font'], ->
  # we need the font task to be finished before building the CSS.

  autoprefix = new LessPluginAutoPrefix
    browsers: [ "last 3 Chrome versions", "last 3 Firefox versions" ]

  # Styles
  gulp
    .src './src/demo/styles/entry/app.less',
      base: path.join(__dirname, '/src/demo/styles/')
    .pipe less
      paths: [ path.join(__dirname, '/src/demo/styles/'), './build/' ]
      plugins: [ autoprefix ]
    .on 'error', (err) ->
      gutil.log(err)
      this.emit('end')
    .pipe rename 'app.css'
    .pipe gulp.dest './build/demo/'
    .pipe minifyCSS()
    .pipe rename 'app.min.css'
    .pipe gulp.dest './build/demo/'

  # HTML
  gulp
    .src './src/demo/templates/demo.html'
    .pipe minifyHTML()
    .pipe gulp.dest './build/demo/'

  # Read the Sketch file names to get data for the demo.
  fs.readdir "./src/sketch/", (err, files) ->

    # Get the icon names.
    iconNames = []
    for icon in files
      iconNames.push icon.replace(/\.[^/.]+$/, "")

    iconNames = _.compact iconNames

    # Get the sizes.
    sizeData = []
    for key, value of sizes
      sizeData.push key

    gulp
      .src "./src/demo/templates/data.json"
      .pipe jsoneditor
        icons: iconNames
        sizes: sizeData
        weights: weights
      .pipe jsonminify()
      .pipe gulp.dest './build/demo'


gulp.task 'watch', ->
  gulp.watch './src/demo/**/*', ['demo']
  gulp.watch './src/sketch/**/*.sketch', [
    '100-16pt18box',
    '100-20pt24box',
    '100-30pt32box',
    '100-full',
    '100-font',
    '500-16pt18box',
    '500-20pt24box',
    '500-30pt32box',
    '500-full',
    '500-font',
    'demo'
  ]

gulp.task 'default', [
  'watch',
  '100-16pt18box',
  '100-20pt24box',
  '100-30pt32box',
  '100-full',
  '100-font',
  '500-16pt18box',
  '500-20pt24box',
  '500-30pt32box',
  '500-full',
  '500-font',
  'demo'
]
