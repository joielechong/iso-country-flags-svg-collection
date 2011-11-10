#!/bin/bash

function pro () {
  echo -n "."
}

function usage () {
  echo "usage: $0 directory project foreground logo.png resolution cc"
  exit 0
}

function scale () {
PROJ=$1
FORE=$2
CC=$3
RES=$4

  mkdir -p build/$PROJ-$FORE/res-$RES && pro
  ./build-scale.sh build/$PROJ-$FORE/web/$CC.png build/$PROJ-$FORE/res-$RES/$CC.png $RES "$CC" && pro
}

IN=$1
PROJ=$2
FORE=$3
LOGO=$4
RES=$5
CC=$6

[ "$IN" = "" ] && usage
[ "$PROJ" = "" ] && usage
[ "$FORE" = "" ] && usage
[ "$LOGO" = "" ] && usage
[ "$RES" = "" ] && usage
[ "$CC" = "" ] && usage

echo -n "$CC ($PROJ-$FORE) "

if [ -f "$IN/$CC.png" ]
then
  pro
else
  echo "missing file: $IN/$CC.png, Exiting."
  exit 1
fi

if [ -f "artwork/fore-$FORE.png" ]
then
  pro
else
  echo "missing file: artwork/fore-$FORE.png, Exiting."
  exit 1
fi

mkdir -p build/$PROJ-$FORE/web && pro
mkdir -p build/$PROJ-$FORE/web-noshadow && pro

convert $IN/$CC.png -alpha set -gravity center -scale 403x403 -extent 512x512 artwork/mask.png -compose DstIn -composite artwork/fore-$FORE.png -compose Over -gravity South-East -composite \( -scale $RES artwork/$LOGO \) -compose Over -composite artwork/back-shadow.png -compose DstOver -composite build/$PROJ-$FORE/web/$CC.png

convert $IN/$CC.png -alpha set -gravity center -scale 403x403 -extent 512x512 artwork/mask.png -compose DstIn -composite artwork/fore-$FORE.png -compose Over -gravity South-East -composite \( -scale $RES artwork/$LOGO \) -compose Over -composite artwork/back-empty.png -compose DstOver -composite build/$PROJ-$FORE/web-noshadow/$CC.png

pro

if [ -f "build/$PROJ-$FORE/web/$CC.png" ]
then
  pro
else
  echo "convert failed, exiting."
  exit 1
fi

scale $PROJ $FORE $CC 256x256
scale $PROJ $FORE $CC 128x128
scale $PROJ $FORE $CC 96x96
scale $PROJ $FORE $CC 72x72
scale $PROJ $FORE $CC 64x64
scale $PROJ $FORE $CC 48x48
scale $PROJ $FORE $CC 36x36
scale $PROJ $FORE $CC 32x32
scale $PROJ $FORE $CC 24x24
scale $PROJ $FORE $CC 16x16

echo " ok"

