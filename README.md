[![Xcode 10](https://img.shields.io/badge/Xcode-10-blue.svg)](https://developer.apple.com/xcode/)
[![Platform](https://img.shields.io/badge/platforms-macOS-blue.svg)](https://developer.apple.com/platforms/)
[![Swift 4.2](https://img.shields.io/badge/swift-5-red.svg?style=flat)](https://developer.apple.com/swift) [![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)

# Svg to Png

*Svg to Png* is a project editor for converting svg files to texture atlases.  *Svg to Png* doesn't do the actual conversions, but rather runs command line tools like **rsvg-convert**, **inkscape** or any executable that can convert svg images to png via a bash shell command.
 
## Requirements

* macOS 10.11 or greater. *(Svg to Png supports Mojave's dark mode)*

## Install svg converters
*Svg to Png* comes pre-configured with support for:

* rsvg-convert (**[librsrg](https://github.com/GNOME/librsvg)**). Install librsvg on your mac with [Homebrew](https://brew.sh): `brew install librsvg`

* **[svgexport](https://github.com/shakiba/svgexport)**. *svgexport* requires that **npm** and **node.js** are installed on your mac. If need be: `brew install node` then `npm install svgexport -g`

* **[ImageMagick](https://www.imagemagick.org)**. `brew install imagemagick`

* **[inkscape](https://www.inkscape.org)**. *inkscape* requires XQuartz. I recommend **not** using *inkscape* unless it’s already installed. `brew cask install inkscape`

## How do I use it?

* Open the *Svg to Png* app. 
* Add folders (i.e atlases) and .svg files.
* For each atlas or svg file 
    * supply a width and height (specify it on the atlas and .svg files inherit them from the atlas.)
    * select resolutions to include: 1x, 2x, 3x.
* Save the project.  *Svg to Png* saves to  a *.svgproj* file.

## Selecting a different export command

* From the *Project* menu, select the *Export Commands* option.
* Click on the checkbox (in the *Default* column) of the command you'd like to use for the project

## Adding, modifying export commands

You add add new commands by clicking the **'+'** button in the *ExportCommands* window, then modifying the bash shell command line in the bottom half of that window.

When adding commands, variables are available that will be replaced with the corresponding value from your project:

* *@width* - the exported png's width
* *@height* - the exported png's width
* *@source* - the svg file to convert
* *@target* - the exported png file
* *@originalWidth* - the width of the svg
* *@originalHeight* - the height of the svg

Although you can't modify the predefined commands, you can edit the custom ones.

## A note on 'rasterized' svg files

When I first started on this project, I was very ignorant about svg files. To me: "They're vector files that can be resized and maintain the integrity of the image."

I tested a lot of svg samples from different sources. But some stubbornly resisted scaling smoothly: "Why does my scaled file look like a raster image?" After many wasted hours, I found out why. They **are** raster images. Embedded in the SVG file. D'oh!

If your svg file (opened in a text editor) contains something like: 

`<image id="mine" width="28px" height="32px" xlink:href="data:image png;base64,iVBORw0KGgoAAAANSUhEUgAAABwAAAAg.....>`

... then, some of the elements in your svg have been rasterized. They will not scale smoothly. Why?

* A raster image was inserted into the svg file.
* The vector drawing tool used to create the svg was unable to transform an effect because there was no equivalant in the svg specification.

## Possible enhancements

What started as a small (or so I thought) experiment, became way more involved than I planned. Yet still, there are many possible enhancements that could be added. Issue a pull request and go for it.

* Change from table cell based outline to a view based one.
* The default export commands apply to **all** projects. Enhance to saving per project and/or per folder or individual files.
* Allow multiple selection in the outline view.
* Ability to set default resolutions to a project or folder
* Other?

## Completed enhancements

* Extract viewbox from SVG file when added to project and set width, height in ViewController - Completed v1.1.0
