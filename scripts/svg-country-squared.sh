#!/bin/sh

scripts/build.pl --cmd  svg2png --out build --res 512x512 \
                 --svgs svg/country-squared

STYLE="simple flat fancy glossy"

for f in $(cd svg/country-squared; ls -1 *.svg); do
    echo -n " build/svg-country-squared-* $f";

    for s in $STYLE; do 
	echo -n " $s";
	PNG=`echo $f | sed s/.svg$/.png/`;
	scripts/build.pl --cmd template --out build/svg-country-squared-$s \
	    --res 512x512 \
	    --mask 57x57+35x35+398x398 \
	    --geo  57x57+400x400 \
	    --back back.png \
	    --flag $PNG \
	    --fore fore.png \
	    --svgs ../svg-country-squared-res-512x512 --svg $f; \
    done
    echo " ok.";
done
