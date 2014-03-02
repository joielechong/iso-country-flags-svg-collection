#!/usr/bin/env python

from os.path import basename, splitext
from optparse import OptionParser

parser = OptionParser()
parser.add_option("--cmd", dest="cmd",
                  help="command", metavar="COMMAND")
parser.add_option("--tile", dest="tile",
                  type=int, default=10,
                  help="number of horizontal tiles")
parser.add_option("--resx", dest="resx",
                  type=int, default=40,
                  help="horizontal flag size in pixel")
parser.add_option("--resy", dest="resy",
                  type=int, default=30,
                  help="vertical flag size in pixel")
parser.add_option("--image", dest="image",
                  default="flags.png",
                  help="image file with the flags")
parser.add_option("--css", dest="css",
                  default="flags.css",
                  help="css file with for flags")

(options, args) = parser.parse_args()

if options.cmd == "css":

    background_position_fmt = 'background-position: -%dpx -%dpx;'
    flag_styles = []
    i = 0
    for f in args:
        name, _ = splitext(basename(f))
        x = (i % options.tile) * options.resx
        y = (i / options.tile) * options.resy
        flag_styles.append((name, x, y))
        if name=='zz': # unknown
            default_background_position = background_position_fmt % (x, y)

        i = i+1

    print ('''.flag {
    height: %(height)dpx;
    width: %(width)dpx;
    background-image: url("%(image)s");
    background-repeat: no-repeat;
    display: block;
    overflow: hidden;
    text-indent: -99999px;
    %(background-position)s
}
''' % {
        'height': options.resy, 
        'width': options.resx, 
        'image': options.image,
        'background-position': default_background_position
        })

    for (name, x, y) in flag_styles:
        print (".flag-%s { background-position: -%dpx -%dpx; }" % (name, x, y))

elif options.cmd == "html":
    print ('<link rel="stylesheet" type="text/css" href="%s">' % options.css)
    for f in args:
        name, _ = splitext(basename(f))
        print ('<p>%(name)s <span class="flag flag-%(name)s"></span></p>' % {'name': name})
    print ('<p>empty <span class="flag"></span></p>')

else:
    print ("unknown command")
