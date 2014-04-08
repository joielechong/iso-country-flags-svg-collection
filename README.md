## Description

[ISO 3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1) defines two-letter country codes which are used most prominently for the Internet's country code top-level domains (with a few exceptions).

This repository contains 248 country flag SVG icons as shown in the following sheet:

![iso-country-flags-sheet-flat.png](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/iso-country-flags-sheet-flat.png "ISO country flags svg collection")

You can build the above icon sheet with different icon styles using the templates in the build directory: none, flat, simple, fancy, glossy:

![templates.png](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/templates.png "Country flag icons templates")

Simply type

```
$ make -j4
```

to build PNG versions of the country flags contained in this collection. This will create about 320MB of data: none, flat, simple, fancy, glossy template based PNG files with the following resolutions: "512x512 (web), 256x256, 128x128, 96x96, 72x72, 64x64, 48x48, 36x36, 32x32, 24x24, 16x16".

For example the results with the template "flat" applied to the "United States" country flag icon looks like follows:

![resolutions.png](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/resolutions.png "Country flag icon resoultions")
 
### Usage examples

Type

```
$ make help
```

to see all build targets.

* Country flags icon sheets - type ```$ make -j4 sheets```.

* [WebGL Earth - ISO country flags](http://tinyurl.com/webgl-earth-iso-country-flags).

  ![WebGL Earth - ISO country flags](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/example-webgl-earth.png). Open the [live demo](http://tinyurl.com/webgl-earth-iso-country-flags) in your web browser. This demo uses a slightly modified [iso-3166-1.json file](http://dl.dropbox.com/u/3139257/iso-country-flags-svg-collection/examples/iso-3166-1.json) (with an added "var data = " string) an the [WebGL Earth API](http://www.webglearth.org/).

* Google Maps - [G+ users of the world - PicasaWeb album](http://goo.gl/mHyJb):

  ![G+ users of the world picasaweb album](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/example-google-maps.png) Notice: you first have to zoom out to see anything on the world map (it seems, that there is a bug in Google Maps, which prevents to show the country icons).

* Xplanet - [howto generate xplanet marker config files](https://github.com/koppi/iso-country-flags-svg-collection/wiki/example-xplanet):

  ![example-xplanet-de](https://raw.github.com/koppi/iso-country-flags-svg-collection/master/examples/example-xplanet-de.png) Notice: go to the [Wiki](https://github.com/koppi/iso-country-flags-svg-collection/wiki/example-xplanet). for howto generate xplanet marker config files. Run the following command to generate all the xplanet marker config files: ```$ make -j4 xplanet```, a shortcut for the command: ```$ scripts/build.pl --cmd example xplanet --json iso-3166-1.json --out build --res 16x16 --lang all```.
  
## Download

You can download pre built PNG icon sets from my [Dropbox](http://goo.gl/oaoEl).

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=koppi&url=https://github.com/koppi/iso-country-flags-svg-collection&title=&language=&tags=svg,country,flags&category=images)

## Building the icon sets

### Tools required

For converting the SVG files to the PNG format using different templates, you need to install the following software packages:

* Perl modules: XML::LibXML, JSON
* Inkscape
* ImageMagick
* pngcrush
* optipng

On Debian/Ubuntu you can install these packages with the following command:

```
 $ sudo apt-get -y install libxml-libxml-perl libjson-perl inkscape imagemagick pngcrush optipng
```

Simply type "make" to generate the icon sets. By default the Makefile generates icon sets with the following resolutions. For the country-squared SVG files:

```
512x512 256x256 128x128 96x96 72x72 64x64 48x48 36x36 32x32 24x24 16x16
```

and for the country-4x3 SVG files:

```
1280x960 640x480 320x240 160x120 80x60 40x30 20x15
```

### Building your own PNG icon sets

If you want to build your own icon sets with the same templates used for the flags here, you just create a folder under [svg/](https://github.com/koppi/iso-country-flags-svg-collection/tree/master/svg), and drop your SVG files in there. Run make to (re-)generate the output.

Country flag examples use a surface area of 512x512 (1:1) and 640x480 (4:3), so be sure to keep the 1:1 or 4:3 ratios for best results.

## Related projects

See https://github.com/koppi/iso-country-flags-svg-collection/wiki/Related

## Authors / TODO / License

* [Jakob Flierl](https://github.com/koppi): initial import of the iso-country-flags-collection to github.

* We try to keep the TODO list short. You can [browse issues](https://github.com/koppi/iso-country-flags-svg-collection/issues) related to iso-country-flags-svg-collection to see, what's being worked on.

* Most of the country flag icons are licensed under the [Public Domain](http://en.wikipedia.org/wiki/Public_domain).
