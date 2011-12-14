# ISO country flags SVG collection - high quality vector graphics country flag icons

## Description
This repository contains 248 country flag SVG icons as shown in the following sheet:

![iso-country-flags-sheet-flat.png](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/iso-country-flags-sheet-flat.png "ISO country flags svg collection")

You can build the above icon sheet with different icon styles using templates in the artwork directory: flat, simple, fancy, glossy:

![templates.png](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/templates.png "Country flag icons templates")

Simply type "make" to build PNG versions of the country flags contained in this collection. This will create about 320MB of data: flat, simple, fancy, glossy template based PNG files with the following resolutions: 512x512 (web), 256x256, 128x128, 96x96, 72x72, 64x64, 48x48, 36x36, 32x32, 24x24, 16x16.

For example the results with the template "flat" applied to the "United States" country flag icon looks like follows:

![resolutions.png](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/resolutions.png "Country flag icon resoultions")
 
## Requirements
For converting the SVG files to different formats using different templates, you need the following software:

* Inkscape [here](http://www.inkscape.org/).
* ImageMagick [here](http://www.imagemagick.org/).

## Are you using this country flags collection?

Want to be featured in a gallery of apps using it? Then please send a screenshot and details of your app to [Jakob Flierl](https://github.com/koppi).

### Usage examples

* Google Earth - [G+ users of the world - KMZ file](http://goo.gl/YJjv3):

  ![G+ users of the world KMZ file](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/example-google-earth.png)

* Google Maps - [G+ users of the world - PicasaWeb album](http://goo.gl/mHyJb):

  ![G+ users of the world picasaweb album](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/example-google-maps.png) Notice: you first have to zoom out to see anything on the world map (it seems, that there is a bug in Google Maps, which prevents to show the country icons).

## License / Info

The country flag icons in this repository were collected from Wikipedia Commons project during the [EUHackathon 2011](http://www.euhackathon.eu/). We did not find an up to date free collection of SVG vector graphics icons during the hack marathon. So we decided to build up this collection and share it here with future EUHackathoners and the Internet.

Most of the country flag icons are licensed under the [Public Domain](http://en.wikipedia.org/wiki/Public_domain).

## Building your own icon sets

If you want to build your own icon sets with the same templates used for the flags here, you just create a folder under [svg/](https://github.com/koppi/iso-country-flags-svg-collection/tree/master/svg), and drop your .svg files in there. Run make to (re-)generate the output.

Country flag examples use a surface area of 512x512, but this size is not a requirement, but be sure to keep the 1:1 ratio for best results.

## TODO

We try to keep the TODO list short. You can [browse issues](https://github.com/koppi/iso-country-flags-svg-collection/issues) related to iso-country-flags-svg-collection to see, what's being worked on.

## Authors

* Initial import of the iso-country-flags-collection to github - [Jakob Flierl](https://github.com/koppi).
* Makefile based build system - [Tit Petric](https://github.com/titpetric). (See: "Building your own icon sets" above.)
