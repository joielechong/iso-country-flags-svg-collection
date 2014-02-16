#!/bin/sh
set -e

BGS="lightgrey white black transparent"

echo "Generating sheets .."

TILE=15

for f in $(cd build; ls -d1 png-*); do

    for res in $(cd build/$f; ls -d1 res-*); do
	echo " processing build/$f/$res";

	OUTPD="build/$f/sheets";
	FLAGS="build/$f/$res/??.png";

	RES=`echo $res | sed s/^res-//g`
	RESX=`echo $RES | sed s/x.*$//g`
	RESY=`echo $RES | sed s/^.*x//g`

	if [ "$RESX" = "1280" ]; then
	    echo "  skipping big resolution $RES.";
	else
	    for bg in $BGS; do
#	    echo "   $bg";
		SHEET="$OUTPD/$res-$bg.png";
		CSS="$OUTPD/$res-$bg.css";
		HTML="$OUTPD/$res-$bg.html";

		mkdir -p $OUTPD;
		echo "  $SHEET";

		montage \
		    -limit memory 512 -limit map 512 \
		    -font DroidSans-Bold.ttf \
		    -pointsize 8 \
		    -tile ${TILE}x \
		    -geometry $RES! \
		    $FLAGS \
		    -label "%f" \
		    -fill Black \
		    -background $bg \
		    $SHEET;

		echo "  $CSS"
		./scripts/css.py --cmd css --tile $TILE --resx $RESX --resy $RESY --image $res-$bg.png $FLAGS > $CSS
		echo "  $HTML"
		./scripts/css.py --cmd html --css $res-$bg.css $FLAGS > $HTML

	    done
	fi
    done
done
echo "done."
