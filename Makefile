all: png-country-4x3 png-country-squared

png-country-4x3: svg-country-4x3
	scripts/png-country-4x3.sh

svg-country-4x3:
	scripts/svg-country-4x3.sh

png-country-squared: svg-country-squared
	scripts/png-country-squared.sh

svg-country-squared:
	scripts/svg-country-squared.sh

xplanet:
	scripts/build.pl --cmd example xplanet --json iso-3166-1.json --out build --res 16x16 --lang all

clean:
	/bin/rm -rf build/svg-*/*.svg
	/bin/rm -rf build/png-*/*.png

