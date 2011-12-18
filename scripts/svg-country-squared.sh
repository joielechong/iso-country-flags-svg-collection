#!/bin/sh

STYLE="simple flat fancy glossy"

for f in $(cd svg/country-squared; ls -1 *.svg); do
    echo "build/svg-country-squared-* $f";
    for s in $STYLE; do 
	scripts/build.pl --cmd svg2svg --out build/svg-country-squared-$s \
	    --res 512x512 \
	    --back back.png \
	    --flag $f \
	    --fore fore.png \
	    --svgs svg/country-squared \
	    --svg $f \
	    --mask 57x57+35x35+398x398 --geo 55x55+512x512 --geoscale 0.782
    done
done
echo " ok.";
