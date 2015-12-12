# Iconathon

Iconathon is an icon task runner that turns Sketch files into icon formats for
all various platforms. Iconathon will…

- Export to SVG for Android and the web, and PDF for iOS.
- Allow for different weights, the thickness of the line in the icon.
- Allow for different bounding boxes and margins.

_NOTE: Iconathon only works with OSX and [Sketch](http://bohemiancoding.com/sketch/).
Sorry! This is primarily an internal script that we use where we control the
environment and software used._


## Set Up

First, you’ll need to…

1. Make sure you have [Homebrew](http://brew.sh/) installed.
2. `$ brew tap Homebrew/bundle`
3. `$ brew bundle`
4. `$ npm install`

Once you’ve got all the packages, run…

- `./tools/dev`

This will run the gulp script, browserify for the testing app, and the testing
app server. Visit [localhost:4004](http://localhost:4004) to see the icons in
action. Look in `/build` for the output.


## How It Works

- The build script looks at the files in `/src/sketch`.

- There’s an 1920x1920 artboard for each weight (100 and 500). The artboard is
  the name (close, add, etc.) with a prefix of the weight, like
  `100/close` and `500/close`.

- When you save in Sketch with gulp running, the artboards will be exported in
  SVG to the `/build/exports` directory automatically via `gulp-sketch`.

- After exporting, gulp will take the file, resize, minify, and package it for
  various platforms. You can see the result in `/build/<weight>`.


## Adding and Modifying Icons

…is easy!

1. Make a new Sketch file in `/src/sketch/`.
2. Make an 1920x1920 artboard for each weight (currently 100 and 500)
3. Use underscores in the name of the file `business_class`. Use the same name
   for artboards, but prefix with the weight, like `100/business_class` and
   `500/business_class`.
4. [Draw.](#tips-for-drawing)
5. Save.

Gulp will then handle the exporting, packaging, resizing, minifying and so on,
so long as it’s running. _If you’re making a new icon, you may need to restart
the dev script._ Commit, review, and push.

To add another weight, add another artboard (named something like `700/foo`) to
the individual Sketch files, then update the default and watch tasks at the
bottom of the gulpfile.

To add another size, update the sizes object following the same format. You’ll
also need to update the default and watch tasks at the bottom of the gulpfile.

We find the 100 weight is ideal for mobile devices, and 500 is ideal for the
web. You can adapt your own naming conventions for weights.


## Tips for Drawing

- If you’re adding a third-party logo, the drawing has already been done for you!
  Don’t redraw or modify third-party logos in any way, unless you need to make it
  monochrome. Use the same icon for all the weights for third-party icons.

- Use a 1920 by 1920 pixel artboard. The math to add margins relies on these
  dimensions. It can be placed anywhere in the file, but it’s typically at 0.0.

- For 100 weight icons, use a 96px grid and stroke. For 500 weight icons, use a
  120px grid and stroke.

- Using border radius is great, but sometimes the icon font doesn’t recognize
  them and you get hard edges. To get around this, you can join the
  shapes and flatten them. Sketch will draw the appropriate handles and bezier
  curves. The downside is that this is destructive, it’s harder to align things
  afterward, and means you have to redraw stuff later if you want to change it.
  Border radius seems to work with simpler shapes like rectangles, so test it
  before flattening.

- Before you do the flattening, though, it’s nice to keep the “source” off to
  the side. If you need to come back and redraw, it’s nice to have the original
  paths.

- Don’t use borders on vectors, especially not inside/outside borders which aren’t
  supported in SVG.

- Make sure none of the paths go outside of the artboard. If so, the
  glyph in the icon font will get misaligned. Draw inside the lines.

- Fill the space edge-to-edge as much as possible. The build process will add
  margins as needed.

- All paths should be black (#000000).

- [Test!](#testing)


## Testing

There’s a small web app for testing all the icons. You can see all the icons
at once, in different sizes and formats.

If you’re running the dev script, you’re already running the web app. Just
visit [localhost:4004](http://localhost:4004). If you need to restart it,
that’s done with `npm run dev`.

If you edit or add icons, just refresh the page to get the latest.


## A Note About Icon Fonts

This script uses gulp-iconfont for testing, but we found the output wasn’t
always production ready. We use the full exported SVGs and import to
[Icomoon](https://icomoon.io/app). It could have been the way they were drawn.
Your mileage may vary.
