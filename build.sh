#!/bin/bash

hash inkscape &> /dev/null
if [ $? -eq 1 ]; then
  echo >&2 "command 'inkscape' not found. Please install inkscape."
fi

hash convert &> /dev/null
if [ $? -eq 1 ]; then
  echo >&2 "executable 'convert' not found. Please install imagemagick."
fi

function pro () {
  echo -n "."
}

echo "Building"

function bat () {
  echo "Style: $2"
  ./batch-directory.sh  "./build-montage.sh $1 $2 $3 $4" && pro
  ./build-sheets.sh $1-$2 LightGrey
  ./build-sheets.sh $1-$2 black
  ./build-sheets.sh $1-$2 white
  echo " done."
}

function batII () {
PROJ=$1
RES=$2

  bat $PROJ flat   $PROJ.png $RES
  bat $PROJ simple $PROJ.png $RES
  bat $PROJ fancy  $PROJ.png $RES
  bat $PROJ glossy $PROJ.png $RES
}

#batII flags 250x250

function batIII () {
IN=$1
RES=$2
FORE=$3

./batch-directory.sh svg/$IN "./build-svg2png.sh svg/$IN build/$IN 403" && pro
./batch-directory.sh svg/$IN "./build-montage.sh build/$IN-403 $IN-403 $FORE logo.png $RESx$RES" && pro
./build-sheets.sh build/$IN-403-$FORE Black LightGrey
./build-sheets.sh build/$IN-403-$FORE Black White
./build-sheets.sh build/$IN-403-$FORE LightGrey Black
./build-sheets.sh build/$IN-403-$FORE Black Transparent
}

batIII country-squared 512 flat
batIII country-squared 512 simple
batIII country-squared 512 fancy
batIII country-squared 512 glossy
