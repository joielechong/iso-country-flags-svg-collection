#!/bin/sh

STYLE="simple flat fancy glossy"

for s in $STYLE; do 
    echo -n " $s";
    scripts/build.pl --cmd svg2png --out build --res 512x512 \
        --svgdir build/svg-country-squared-$s
done
echo " ok.";
