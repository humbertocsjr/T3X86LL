EXES = ../unix/s86

all: $(EXES)
	@echo >> /dev/null

clean:
	@-rm $(EXES) 

../unix/s86: S86.T
	cp S86.T ../unix/s86.t
	cd ../unix; tx0 -t unix s86
	rm ../unix/*.t
