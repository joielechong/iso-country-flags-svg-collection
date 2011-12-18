#!/bin/sh

BGS="LightGrey White Black Transparent"

echo "Generating sheets .."

for f in $(cd build; ls -d1 png-*); do
    echo -n " processing build/$f";

    for res in $(cd build/$f; ls -d1 res-*); do
	echo "/$res";

	for bg in $BGS; do
#	    echo "   $bg";
	    OUTPD="build/$f/sheets";
	    FLAGS="build/$f/$res/??.png";
	    SHEET="$OUTPD/Sheet-$bg-$res.png";

	    mkdir -p $OUTPD;
	    echo "  $SHEET";

	    montage \
		-limit memory 64 -limit map 128 \
		-font DroidSans-Bold.ttf \
		-pointsize 8 \
		$FLAGS \
		-label "%f" \
		-fill Black \
		-background $bg \
		$SHEET;
	done
    done
done
echo "done."