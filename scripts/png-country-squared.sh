#!/bin/sh

RESOS="512x512,256x256,128x128,96x96,72x72,64x64,48x48,36x36,32x32,24x24,16x16"
STYLE="none simple flat fancy glossy"

for s in $STYLE; do 
    echo -n " $s";
    scripts/build.pl --cmd svg2png --out build --res $RESOS \
        --svgs build/svg-country-squared-$s
done
echo " ok.";
