MAKE = make --no-print-directory

all clean: unix
	@cd TOOLS; $(MAKE) $@
	@cd SRC; $(MAKE) $@
	@cd S86; $(MAKE) $@

dosmake:
	dosbox -C "mount C: ./" -C "c:" -C "make.bat"

unix:
	mkdir unix

install:
	sudo cp unix/tlang /usr/local/bin/tlang
	sudo cp unix/tlang-min /usr/local/bin/tlang-min
	sudo cp unix/s86 /usr/local/bin/tlang-s86
	sudo cp unix/prj /usr/local/bin/tlang-prj

uninstall:
	-sudo rm /usr/local/bin/tlang
	-sudo rm /usr/local/bin/tlang-min
	-sudo rm /usr/local/bin/tlang-s86
	-sudo rm /usr/local/bin/tlang-prj