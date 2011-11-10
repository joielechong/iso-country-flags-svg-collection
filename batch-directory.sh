#!/bin/bash

DIR=$1
CMD=$2

if [ "$CMD" = "" ]
then
  echo "usage: $0 [directory] [command]"
  exit 1
fi

for file in $(cd $DIR; ls -1 *); do $CMD $(echo ${file/.png/} | sed "s/.svg//") ; done
