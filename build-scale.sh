#!/bin/bash

function pro () {
  echo -n "."
}

IN=$1
OUT=$2
RES=$3
LABEL=$4

echo -n " $RES "

convert -label $LABEL -scale $RES $IN $OUT && pro
