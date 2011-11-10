#!/bin/bash

function pro () {
  echo -n "."
}

PROJ=$1
FG=$2
BG=$3

echo -n "Sheets " && pro

if [ -e "$PROJ" ]
then
  pro
else
  echo "Error: no such directory: $PRO, exiting."
  exit 1
fi

RES=$(ls -d1 $PROJ/res-*)

#echo $RES

for R in $RES; do
R1=$(echo $R | sed "s/.*\/res-//g" )
F1=$(echo $R | sed "s/.*\/res-.*x//g" )

  echo -n " $R1 "

  montage -font DroidSans-Bold.ttf -pointsize $(echo "$F1 * 0.125 + 8" | bc) $R/*.png -geometry $R1 -fill $FG -background $BG $PROJ/Sheet-$BG-$R1.png && pro;
done

echo " ok"
