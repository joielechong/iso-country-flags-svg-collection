#
# *DOCUMENTATION*
# To see a list of typical targets execute "make help"
#

# Do not:
# o  use make's built-in rules and variables
#    (this increases performance and avoids hard-to-debug behaviour);
# o  print "Entering directory ...";
MAKEFLAGS += -rR --no-print-directory

# Avoid funny character set dependencies
unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC

# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands

ifeq ("$(origin V)", "command line")
  BUILD_VERBOSE = $(V)
endif
ifndef BUILD_VERBOSE
  BUILD_VERBOSE = 0
endif

# That's our default target when none is given on the command line
PHONY := _all
_all:

# Cancel implicit rules on top Makefile
$(CURDIR)/Makefile Makefile: ;

ifeq ($(BUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @
endif

# If the user is running make -s (silent mode), suppress echoing of
# # commands

ifneq ($(findstring s,$(MAKEFLAGS)),)
  quiet=silent_
endif

export quiet Q BUILD_VERBOSE

PHONY += clean xplanet sheets png-country-squared png-country-4x2

_all: all

all: local pngs

SVG2SVG_EXTRA = Makefike scripts/build.pl

PHONY += $(SVG2SVG_EXTRA)

SVG2SVG_11 = scripts/build.pl --cmd svg2svg --res 512x512 --back back.png --fore fore.png --svgs svg/country-squared --mask 57x57+35x35+398x398 --geo 57x57+512x512 --geoscale 0.7775

SVG2SVG_43 = scripts/build.pl --cmd svg2svg --res 1280x960 --back back.png --fore fore.png --svgs svg/country-4x3 --mask 107x107+67x67+1065x745 --geo 106x75+1280x960 --geoscale 1.667

SVGS_11 = $(shell cd svg/country-squared; ls -1 *.svg)

SVGS_11_FANCY  = ${SVGS_11:%.svg=build/svg-country-squared-fancy/%.svg}
SVGS_11_SIMPLE = ${SVGS_11:%.svg=build/svg-country-squared-simple/%.svg}
SVGS_11_FLAT   = ${SVGS_11:%.svg=build/svg-country-squared-flat/%.svg}
SVGS_11_GLOSSY = ${SVGS_11:%.svg=build/svg-country-squared-glossy/%.svg}

PNGS_11_FANCY  = ${SVGS_11:%.svg=build/png-country-squared-fancy/%.png}
PNGS_11_SIMPLE = ${SVGS_11:%.svg=build/png-country-squared-simple/%.png}
PNGS_11_FLAT   = ${SVGS_11:%.svg=build/png-country-squared-flat/%.png}
PNGS_11_GLOSSY = ${SVGS_11:%.svg=build/png-country-squared-glossy/%.png}

SVGS_43 = $(shell cd svg/country-4x3; ls -1 *.svg)

SVGS_42_FANCY  = ${SVGS_43:%.svg=build/svg-country-4x2-fancy/%.svg}
SVGS_42_SIMPLE = ${SVGS_43:%.svg=build/svg-country-4x2-simple/%.svg}
SVGS_42_FLAT   = ${SVGS_43:%.svg=build/svg-country-4x2-flat/%.svg}
SVGS_42_GLOSSY = ${SVGS_43:%.svg=build/svg-country-4x2-glossy/%.svg}

PNGS_42_FANCY  = ${SVGS_43:%.svg=build/png-country-4x2-fancy/%.png}
PNGS_42_SIMPLE = ${SVGS_43:%.svg=build/png-country-4x2-simple/%.png}
PNGS_42_FLAT   = ${SVGS_43:%.svg=build/png-country-4x2-flat/%.png}
PNGS_42_GLOSSY = ${SVGS_43:%.svg=build/png-country-4x2-glossy/%.png}

SVGS_11ALL=$(SVGS_11_FANCY) $(SVGS_11_SIMPLE) $(SVGS_11_FLAT) $(SVGS_11_GLOSSY)
SVGS_42ALL=$(SVGS_42_FANCY) $(SVGS_42_SIMPLE) $(SVGS_42_FLAT) $(SVGS_42_GLOSSY)

svgs: $(SVGS_11ALL) $(SVGS_42ALL)
	$(Q)echo "Finished building svgs."

pngs: png-country-squared png-country-4x2
	$(Q)echo "Finished building pngs."

## svg2svg squared
build/svg-country-squared-fancy/%.svg: svg/country-squared/%.svg
	$(Q)$(SVG2SVG_11) --out $(dir $@) \
			  --flag $(notdir ${<}) \
			  --svg $(notdir ${<})

build/svg-country-squared-simple/%.svg: svg/country-squared/%.svg
	$(Q)$(SVG2SVG_11) --out $(dir $@) \
			  --flag $(notdir ${<}) \
			  --svg $(notdir ${<})

build/svg-country-squared-flat/%.svg: svg/country-squared/%.svg
	$(Q)$(SVG2SVG_11) --out $(dir $@) \
                          --flag $(notdir ${<}) \
                          --svg $(notdir ${<})

build/svg-country-squared-glossy/%.svg: svg/country-squared/%.svg
	$(Q)$(SVG2SVG_11) --out $(dir $@) \
                          --flag $(notdir ${<}) \
                          --svg $(notdir ${<})

## svg2svg 4x2
build/svg-country-4x2-fancy/%.svg: svg/country-4x3/%.svg
	$(Q)$(SVG2SVG_43) --out $(dir $@) \
			  --flag $(notdir ${<}) \
			  --svg $(notdir ${<})

build/svg-country-4x2-simple/%.svg: svg/country-4x3/%.svg
	$(Q)$(SVG2SVG_43) --out $(dir $@) \
			  --flag $(notdir ${<}) \
			  --svg $(notdir ${<})

build/svg-country-4x2-flat/%.svg: svg/country-4x3/%.svg
	$(Q)$(SVG2SVG_43) --out $(dir $@) \
                          --flag $(notdir ${<}) \
                          --svg $(notdir ${<})

build/svg-country-4x2-glossy/%.svg: svg/country-4x3/%.svg
	$(Q)$(SVG2SVG_43) --out $(dir $@) \
                          --flag $(notdir ${<}) \
                          --svg $(notdir ${<})

png-country-4x2: $(SVGS_42ALL)
	$(Q)scripts/png-country-4x2.sh

png-country-squared: $(SVGS_11ALL)
	$(Q)scripts/png-country-squared.sh

sheets:
	$(Q)scripts/sheets.sh

xplanet:
	$(Q)scripts/build.pl --cmd example xplanet --json iso-3166-1.json --out build --res 16x16 --lang all

kml:
	$(Q)scripts/build.pl --cmd example kml --json iso-3166-1.json --out build --res 16x16 --lang all

distclean: clean

clean:
	$(Q)/bin/rm -rvf build/svg-*/*.svg
	$(Q)/bin/rm -rvf build/png-*/res-*
	$(Q)/bin/rm -rvf build/xplanet
	$(Q)echo "Finished cleaning up build."

help:
	@echo  'Cleaning targets:'
	@echo  '  clean              - Remove most generated files'
	@echo  '  distclean          - Remove all generated files.'
	@echo  ''
	@echo  'Generic targets:'
	@echo  '  all                - Build all targets marked with [*].'
	@echo  '  svgs [*]           - Build the svg variants.'
	@echo  '  pngs [*]           - Build the png variants.'
	@echo  '  sheets             - Build sheets for the png variants.'
	@echo  ''
	@echo  'Example targets:'
	@echo  '  kml                - Build kml example file.'
	@echo  '  kmz                - Build kmz example file (wip).'
	@echo  '  poster             - Build svg flags of the world poster (wip).'
	@echo  '  xplanet            - Build xplanet marker files.'
	@echo  ''
	@echo  '  make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build'
	@echo  ''
	@echo  ''
	@echo  'Execute "make" or "make all" to build all targets marked with [*] '
	@echo  'For further info see the ./README.md file'

-include Makefile.local

# Dummies...
PHONY += scripts
scripts: ;
PHONY += FORCE
FORCE:

.PHONY: $(PHONY)
