#!/bin/bash
find svg/ -name '*.svg' -type f | perl -pi -e 's/^([^\/]+)\/([^\/]+)\/(.*).svg/\1 \2 \3/' > /tmp/svg_list
RESOLUTIONS="256x256 128x128 96x96 72x72 64x64 48x48 36x36 32x32 24x24 16x16"
STYLES="fancy flat glossy simple"
DIRS=`cat /tmp/svg_list | awk '{print $2}' | sort | uniq`

GENMAKEFILE="build/Makefile.sources"

# generate source png files from svg Makefile.
./generate-makefile-headers.sh > $GENMAKEFILE


COUNT=`cat /tmp/svg_list | wc -l`

printf "T := $COUNT\n\n" >> $GENMAKEFILE

MESSAGE="Converting .svg files to png (step 1/3) ..."

printf "all: finish\n\nfolders:\n" >> $GENMAKEFILE
for DIR in $DIRS
do
	printf "\t@mkdir -p build/$DIR/orig\n" >> $GENMAKEFILE
done
printf "\nfinish: sources\n\t@\$(DONE)\n\t@printf \" $MESSAGE\\\\n\"\n\nsources: folders" >> $GENMAKEFILE

cat /tmp/svg_list | awk '{printf " ./build/"$2"/orig/"$3".png"}' >> $GENMAKEFILE
printf "\n\n" >> $GENMAKEFILE
cat /tmp/svg_list | awk -v message="$MESSAGE" '{print "./build/"$2"/orig/"$3".png: ./"$1"/"$2"/"$3".svg\n\t@$(ECHO) \" "message"\\r\"\n\t@inkscape -w $(resolution) -h $(resolution) --export-png=$@ $< > /dev/null\n"}' >> $GENMAKEFILE

# generate secondary Makefiles for masks & resolutions
for DIR in $DIRS
do
	mkdir -p build/$DIR
	find svg/$DIR -type f -name '*.svg' | perl -pi -e 's/.*\///g' | perl -pi -e 's/\.svg$/.png/g' > build/$DIR/index
	for STYLE in $STYLES
	do
		mkdir -p build/$DIR-$STYLE
		./generate-makefile-masks.sh build/$DIR $STYLE > build/$DIR-$STYLE/Makefile.masks
		for RES in $RESOLUTIONS
		do
			printf "" > build/$DIR-$STYLE/Makefile.$RES
			./generate-makefile-style.sh build/$DIR $STYLE $RES >> build/$DIR-$STYLE/Makefile.$RES
		done
	done
	rm -rf build/$DIR/index
done

# entry point Makefile

printf "all: masks\n" > Makefile.sources

for DIR in $DIRS
do
	for STYLE in $STYLES
	do
		for RES in $RESOLUTIONS
		do
			printf "\t@\$(MAKE) --no-print-directory -f build/$DIR-$STYLE/Makefile.$RES\n" >> Makefile.sources
		done
	done
done

printf "\nmasks: sources\n" >> Makefile.sources

for DIR in $DIRS
do
	for STYLE in $STYLES
	do
		printf "\t@\$(MAKE) --no-print-directory -f build/$DIR-$STYLE/Makefile.masks\n" >> Makefile.sources
	done
done

printf "\nsources:\n\t@\$(MAKE) --no-print-directory -f build/Makefile.sources\n" >> Makefile.sources

