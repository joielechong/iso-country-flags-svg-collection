#!/bin/bash
DIR=$1
STYLE=$2
RES=$3

./scripts/generate-makefile-headers.sh

MESSAGE="Building $DIR-$STYLE/$RES Sheets (step 4/4) ..."

FILES=`cat $DIR/index`

COUNT=4

printf "T := $COUNT\n\n"

printf "all: finish\n\n"

printf "folders:\n"
printf "\t@mkdir -p $DIR-$STYLE/sheets\n\n"

printf "finish: sources\n"
printf "\t@\$(DONE)\n\t@printf \" $MESSAGE\\\\n\"\n\n"

echo -n "sources: folders"

BGS="LightGrey White Black Transparent"

for BG in $BGS
do
	# relative path from Makefile folder to build folder
	printf " $DIR-$STYLE/sheets/Sheet-$BG-$RES.png"
done
printf "\n\n"

function buildSheets () {
FOLDER=$1
RES=$2
FG=$3
BG=$4
SIZE=$(echo $RES | sed "s/.*x//g" )
POINTSIZE=`expr $SIZE / 8 + 8`
printf "$FOLDER/sheets/Sheet-$BG-$RES.png: $FOLDER/res-$RES/*.png\n";
printf "\t@\$(ECHO)\n\t@printf \" $MESSAGE\\\\r\"\n"
printf "\t@montage -font DroidSans-Bold.ttf -pointsize $POINTSIZE $FOLDER/res-$RES/*.png -geometry $RES -fill $FG -background $BG $FOLDER/sheets/Sheet-$BG-$RES.png\n\n";
}

buildSheets $DIR-$STYLE $RES Black LightGrey
buildSheets $DIR-$STYLE $RES Black White
buildSheets $DIR-$STYLE $RES LightGrey Black
buildSheets $DIR-$STYLE $RES Black Transparent
