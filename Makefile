all:
	@/bin/mkdir -p build
	@echo Generating makefiles for sources
	@./generate-makefile.sh
	@$(MAKE) --no-print-directory -f Makefile.sources
	@echo Done, everything is built. Just cleaning up makefiles.
	@rm build/Makefile.* build/*/Makefile.* Makefile.sources
	@rsync -a --del build/ /var/www/serverpackages.mtk.lan/icons/

clean:
	/bin/rm -rf build Makefile.sources

