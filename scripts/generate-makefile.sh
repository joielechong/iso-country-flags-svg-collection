#!/bin/bash
if [ ! -d "svg/" ]; then
	echo "Sorry, this script can only be run from the root folder."
	exit
fi

find svg/ -name '*.svg' -type f | perl -pi -e 's/^([^\/]+)\/([^\/]+)\/(.*).svg/\1 \2 \3/' > /tmp/svg_list
RESOLUTIONS_DEFAULT="256x256 128x128 96x96 72x72 64x64 48x48 36x36 32x32 24x24 16x16"
RESOLUTIONS=""
STYLES="fancy flat glossy simple"
DIRS=`cat /tmp/svg_list | awk '{print $2}' | sort | uniq`

GENMAKEFILE="build/Makefile.svg2png"

# generate source png files from svg Makefile.
./scripts/generate-makefile-headers.sh > $GENMAKEFILE

COUNT=`cat /tmp/svg_list | wc -l`

printf "T := $COUNT\n\n" >> $GENMAKEFILE

MESSAGE="Converting .svg files to png (step 1/4) ..."

printf "all: finish\n\nfolders:\n" >> $GENMAKEFILE
for DIR in $DIRS
do
	printf "\t@mkdir -p build/$DIR/orig\n" >> $GENMAKEFILE
done
printf "\nfinish: svg2png\n\t@\$(DONE)\n\t@printf \" $MESSAGE\\\\n\"\n\nsvg2png: folders" >> $GENMAKEFILE

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
		./scripts/generate-makefile-masks.sh build/$DIR $STYLE > build/$DIR-$STYLE/Makefile.masks
		RESOLUTIONS=$RESOLUTIONS_DEFAULT
		if [ -f "svg/$DIR.resolutions" ]; then
			RESOLUTIONS=`cat svg/$DIR.resolutions`
		fi
		for RES in $RESOLUTIONS
		do
			./scripts/generate-makefile-style.sh build/$DIR $STYLE $RES > build/$DIR-$STYLE/Makefile.$RES
			./scripts/generate-makefile-sheets.sh build/$DIR $STYLE $RES > build/$DIR-$STYLE/Makefile.sheets.$RES
		done
	done
	rm -rf build/$DIR/index
done

# entry point Makefile

GENMAKEFILE="build/Makefile.sources"

printf "all: resize\n" > $GENMAKEFILE

for DIR in $DIRS
do
	for STYLE in $STYLES
	do
		RESOLUTIONS=$RESOLUTIONS_DEFAULT
		if [ -f "svg/$DIR.resolutions" ]; then
			RESOLUTIONS=`cat svg/$DIR.resolutions`
		fi
		for RES in $RESOLUTIONS
		do
			printf "\t@\$(MAKE) --no-print-directory -f build/$DIR-$STYLE/Makefile.sheets.$RES\n" >> $GENMAKEFILE
		done
	done
done

printf "\nresize: masks\n" >> $GENMAKEFILE

for DIR in $DIRS
do
	for STYLE in $STYLES
	do
		RESOLUTIONS=$RESOLUTIONS_DEFAULT
		if [ -f "svg/$DIR.resolutions" ]; then
			RESOLUTIONS=`cat svg/$DIR.resolutions`
		fi
		for RES in $RESOLUTIONS
		do
			printf "\t@\$(MAKE) --no-print-directory -f build/$DIR-$STYLE/Makefile.$RES\n" >> $GENMAKEFILE
		done
	done
done

printf "\nmasks: sources\n" >> $GENMAKEFILE

for DIR in $DIRS
do
	for STYLE in $STYLES
	do
		printf "\t@\$(MAKE) --no-print-directory -f build/$DIR-$STYLE/Makefile.masks\n" >> $GENMAKEFILE
	done
done

printf "\nsources:\n\t@\$(MAKE) --no-print-directory -f build/Makefile.svg2png\n" >> $GENMAKEFILE

