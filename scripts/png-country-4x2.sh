#!/bin/sh

RESOS="640x480,320x240,160x120,80x60,40x30,20x15"
STYLE="none simple flat fancy glossy"

for s in $STYLE; do 
    echo "Processing style $s ..";
    scripts/build.pl \
	--cmd svg2png \
	--out build \
	--res 1280x960 \
        --svgs build/svg-country-4x2-$s

    echo "Processing style $s ..";
    scripts/build.pl \
	--cmd png2png \
        --out build \
	--res $RESOS \
        --pngs build/png-country-4x2-$s/res-1280x960
done

echo " ok.";
