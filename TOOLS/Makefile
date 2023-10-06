EXES = ../unix/mklib ../unix/dosfile

all: $(EXES)
	@echo >> /dev/null

clean: 
	@-rm $(EXES)

../unix/mklib: MKLIB.T
	cp $^ tmp.t
	tx0 -t unix tmp $@
	rm tmp.t
../unix/dosfile: DOSFILE.T
	cp $^ tmp.t
	tx0 -t unix tmp $@
	rm tmp.t