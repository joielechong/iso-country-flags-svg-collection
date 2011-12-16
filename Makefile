all:
	@/bin/mkdir -p build
	@echo Generating makefiles for sources
	@./scripts/generate-makefile.sh
	@$(MAKE) --no-print-directory -f build/Makefile.sources
	@echo Done, everything is built. Just cleaning up makefiles.
	@rm build/Makefile.* build/*/Makefile.*

clean:
	/bin/rm -rf build

