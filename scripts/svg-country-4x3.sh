#!/bin/sh

scripts/build.pl --cmd svg2png --out build --res 640x480 \
                 --svgdir svg/country-4x3

STYLE="simple flat fancy glossy"

for f in $(cd svg/country-4x3; ls -1 *.svg); do
    echo -n " build/svg-country-4x3-* $f";

    for s in $STYLE; do 
	PNG=`echo $f | sed s/.svg$/.png/`;
	echo -n " $s";
	scripts/build.pl --cmd template --out build/svg-country-4x3-$s \
	    --res  1280x960 \
	    --mask 109x109+65x65+1065x742 \
	    --geo  77x77+1129x807 \
	    --back back.png \
	    --flag $PNG \
	    --fore fore.png \
	    --svgdir ../svg-country-4x3-res-640x480 --svg $f; \
    done
    echo " ok.";
done
