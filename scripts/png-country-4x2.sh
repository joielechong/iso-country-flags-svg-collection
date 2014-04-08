#!/bin/sh

RESOS="1280x960,640x480,320x240,160x120,80x60,40x30,20x15"
STYLE="none glossy simple flat fancy"

for s in $STYLE; do 
    echo "Processing style $s ..";
	scripts/build.pl \
		--cmd svg2png \
		--out build \
		--res $RESOS \
		--svgs build/svg-country-4x2-$s
done

echo " ok.";
