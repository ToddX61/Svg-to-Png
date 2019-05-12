[![Xcode 10](https://img.shields.io/badge/Xcode-10-blue.svg)](https://developer.apple.com/xcode/)
[![Platform](https://img.shields.io/badge/platforms-macOS-blue.svg)](https://developer.apple.com/platforms/)
[![Swift 4.2](https://img.shields.io/badge/swift-5-red.svg?style=flat)](https://developer.apple.com/swift) [![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)

# Svg to Png

*Svg to Png* is a project editor for converting svg files to texture atlases.  *Svg to Png* doesn't do the actual conversions, but rather runs command line tools like **rsvg-convert**, **inkscape** or any executable that can convert svg images to png via a bash shell command.
 
## Requirements

* macOS 10.11 or greater. *(Svg to Png supports Mojave's dark mode)*

## Install svg converters
*Svg to Png* comes pre-configured with support for:

* rsvg-convert (**[librsvg](https://github.com/GNOME/librsvg)**). Install librsvg on your mac with [Homebrew](https://brew.sh): `brew install librsvg` This is probably the easiest to install and seems to run faster than the others (though I haven't tested conversion quality compared to the others.)

* **[svgexport](https://github.com/shakiba/svgexport)**. *svgexport* requires that **npm** and **node.js** are installed on your mac. If need be: `brew install node` then `npm install svgexport -g`

* **[ImageMagick](https://www.imagemagick.org)**. `brew install imagemagick`.  Note that if *inskscape* is installed, ImageMagick will us that to convert.

* **[inkscape](https://www.inkscape.org)**. *inkscape* requires *XQuartz*. I recommend **not** using *inkscape* unless it’s already installed. `brew cask install inkscape`.  If you decide to use *inkscape*, preloading *XQuartz* will significantly improve export time.

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

### Environment paths

The default environment paths to run export commands support all the predefined commands (assuming they're installed using the default installation folder). 

If you add a command, export and see: `'my command' not found`, trying adding the folder where the command resides using *Preferences*.

### Shell scripts

*Svg to Png* supports running shell scripts. To avoid errors and make your life easier, I would recommend putting the script in `/usr/local/bin`.  Adding `#!/bin/bash` as the first line of the script can resolve other issues (i.e. *posix_spawn error*.)

### Debugging in Xcode

When debugging *Svg to Png*, be aware that the environment path is not the same as that used by bash, or commands you run from macOS's *Terminal*.


## Command line version: svgtopng
A command line version, *svgtopng* allows a little more flexibility, including the option to override several different values in the project.

### Usage

`svgtopng [<svgproject> <svgproject> ...] [options]`

`<svgproject> <svgproject> ... one or more svg project files
`

##### Options

*    -v:	version number
*    -h:	this help page
*    -x:	export svg files in the specified projects
*    -f:	only export svg specified files or folders, for instance: -f svgfile1.svg svgfolder ... The default: all svg files are processed
*    -s:	override the svg files' width and height: -s 26:32
*    -r:	resolutions to export: -r 1,2,3 or 2,3, 1 ...etc... 
* 		default is to use the svg file's resolutions defined in the svg project
*    -c:	the number of the export command (as viewed in *Svg to Png* to use when exporting: -c3 ... Defaults to the default command defined in *Svg to Png*
*    -o:	target folder where png files are exported to (it will be created if need be) ... The default is to use the svg folder's target, or the svg folder if no target specified

##### Examples

* `svgtopng myproject.svgprj` Export all files in 'myproject' where 'myproject' is in the current directory
* `svgtopng ~/Documents/svg/myproject` Export all files in 'myproject' 
* `svgtopng myproject1, myproject2, -s36:40` Override the svg's size 
* `svgtopng myproject -f my-svg-folder`  Export all file in folder 'my-svg-folder'
* `svgtopng myproject -f "rounded_0000.svg" biglion.svg`  Export the first file found in the project named 'rounded_0000.svg' and the first file in the project named 'biglion' (note, it is possible to have the same filename in different folders
* `svgtopng svgproject -r2,3` Export all files in svgproject with 2x and 3x resolutions
* `svgtopng svgproject -c1`  Export all files in svgproject using the export command 1 (that is, *rsvg-convert*) ... By default, the export command defined as the default in *Svg to Png* is used
* `svgtopng myproject -o ~/Documents/TestSvgs` Export all files in 'my project' to '~/Documents/TestSvgs'

You can use multiple options in any order (the project files must be specified before any options):

`svgtopng "my project" -s40:40 -r1 -c1 -f mysvg.svg -o ~/Documents/TestSvgs

### Installing

The easiest way to install svgtopng is to:

* clone or download 
* open project 'Svg to Png.xcodeproj'
* select scheme 'svgtopng'
* build project
* copy 'svgtopng' to /usr/local/bin (you can use Finder's 'Go > Go to Folder...' menu option ... the folder is hidden).
* edit ~/.bash_profile in a text editor, and add the line `alias svgtopng="/usr/local/bin/svgtopng"`

You can use *svgtopng* in a shell script, from a Terminal session ... or even add it as an export command in *Svg to Png*



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
* The default export commands apply to **all** projects. Enhance to allow per project and/or per folder and/or per individual file.
* Allow multiple selection in the outline view.
* Ability to set default resolutions to a project or folder
* Other?

## Completed enhancements

###Version 1.1.2
* various fixes
* command line version added
* added option to override svg file's size with the folder's default (in Preferences)
* added ability to specify additional search paths for export commands


###Version 1.1.1

* Extract viewbox from SVG file when added to project and set width, height in ViewController - Completed v1.1.0
