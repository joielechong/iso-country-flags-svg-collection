#!/bin/sh

STYLE="simple flat fancy glossy"

for s in $STYLE; do 
    echo -n " $s";
    scripts/build.pl --cmd svg2png --out build --res 1280x960 \
        --svgdir build/svg-country-4x3-$s
done
echo " ok.";
