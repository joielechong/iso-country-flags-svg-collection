all: svg-country-4x3 svg-country-squared

svg-country-4x3:
	scripts/svg-country-4x3.sh

svg-country-squared:
	scripts/svg-country-squared.sh

clean:
	/bin/rm -rf build/svg-*/*.svg
	/bin/rm -rf build/png-*/*.png

