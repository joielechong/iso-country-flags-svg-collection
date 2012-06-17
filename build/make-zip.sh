#!/bin/sh
mkdir -p zip

for d in $(ls -d1 png-country-squared-* png-country-4x2-*); do
  for r in $(ls -d1 $d/res-*); do
    cp -r $r zip/`echo $r | sed -e s#/#-#`;
    cd zip
    zip -r `echo $r | sed -e s#/#-#`.zip `echo $r | sed -e s#/#-#`;
    cd ..
    rm -r zip/`echo $r | sed -e s#/#-#`;
  done;
done
