#!/bin/bash
DIR=$1
STYLE=$2
RES=$3
./generate-makefile-headers.sh

FILES=`cat $DIR/index`

COUNT=0
for FILE in $FILES
do
	((COUNT++))
done

MESSAGE="Building $DIR-$STYLE/$RES graphics (step 3/4) ..."

printf "T := $COUNT\n\n"

printf "all: finish\n\n"

printf "folders:\n"
printf "\t@mkdir -p $DIR-$STYLE/res-$RES\n\n"

printf "finish: sources\n"
printf "\t@\$(DONE)\n\t@printf \" $MESSAGE\\\\n\"\n\n"

echo -n "sources: folders"

FILES=`cat $DIR/index`

for FILE in $FILES
do
	# relative path from Makefile folder to build folder
	printf " $DIR-$STYLE/res-$RES/$FILE"
done
printf "\n\n"

INDEX=0
for FILE in $FILES
do
	# relative path from Makefile folder to build folder
	printf "$DIR-$STYLE/res-$RES/$FILE: $DIR-$STYLE/web/$FILE\n"
	# -label %s: assigns label to image, removed as not used
	printf "\t@\$(ECHO)\n\t@printf \" $MESSAGE\\r\"\n\t@convert -scale $RES\! \$< \$@\n\n"
	((INDEX++))
done
