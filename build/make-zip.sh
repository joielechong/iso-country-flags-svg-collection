#!/bin/sh
mkdir -p zip

for d in $(ls -d1 png-country-squared-*); do for r in $(ls -d1 $d/res-*); do cp -r $r zip/`echo $r | sed -e s#/#-#`; zip -r zip/`echo $r | sed -e s#/#-#`.zip zip/`echo $r | sed -e s#/#-#`; rm -r $ zip/`echo $r | sed -e s#/#-#`; done; done
