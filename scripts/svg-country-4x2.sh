#!/bin/sh

STYLE="simple flat fancy glossy"

for f in $(cd svg/country-4x3; ls -1 *.svg); do
    echo "build/svg-country-4x2-* $f";

    for s in $STYLE; do 
	scripts/build.pl --cmd svg2svg \
	    --out build/svg-country-4x2-$s \
	    --res 1280x960 \
	    --back back.png \
	    --flag $f \
	    --fore fore.png \
	    --svgs svg/country-4x3 \
	    --svg $f \
	    --mask 107x107+67x67+1065x745 \
	    --geo 106x75+1280x960 --geoscale 1.667
    done
done
echo "ok.";
