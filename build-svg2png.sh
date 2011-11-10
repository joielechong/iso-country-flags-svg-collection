#!/bin/bash

IN=$1
OUT=$2
RES=$3
CC=$4

function pro () {
  echo -n "."
}

function usage () {
  echo "usage: $0 in out cc resolution"
  exit 0
}

echo -n "svn2png $RES "

[ "$IN" = "" ] && usage
[ "$OUT" = "" ] && usage
[ "$CC" = "" ] && usage
[ "$RES" = "" ] && usage

if [ -f "$IN/$CC.svg" ]
then
  pro
else
  echo "missing file: $IN/$CC.svg, Exiting."
  exit 1
fi

if [ -f "$OUT-$RES/$CC.png" ]
then
  if [ "$IN/$CC.svg" -nt "$OUT-$RES/$CC.png" ]
  then
    pro
  else
    echo " skipping $IN/$CC.svg."
    exit 0
  fi
fi

mkdir -p $OUT-$RES && pro

inkscape -a 0:0:512:512 -w $RES -h $RES --export-png=$OUT-$RES/$CC.png $IN/$CC.svg

pro

echo " ok. "

