EXES = ../unix/tlang ../unix/tlang-min ../unix/prj

all: $(EXES)
	@echo >> /dev/null

clean:
	@-rm $(EXES) 

../unix/prj: PRJ.T
	cp PRJ.T ../unix/prj.t
	cd ../unix/; tx0 -t unix prj
	rm ../unix/prj.t

../unix/tlang: ../unix/prj $(wildcard TLANG/*)
	../unix/prj TSRCCOM.PRJ TSOURCE.T t3x0
	cp TSOURCE.T ../unix/tsource.t
	cp ../BIN/LIB.BIN ../unix/lib.bin
	cd ../unix; ./mklib
	cd ../unix; tx0 -t unix t
	mv ../unix/t ../unix/tlang
	rm ../unix/*.t
	rm TSOURCE.T


../unix/tlang-min: ../unix/prj $(wildcard TLANG/*)
	../unix/prj TSRCMIN.PRJ TSOURCE.T t3x0
	cp TSOURCE.T ../unix/tsource.t
	cp ../BIN/LIBMIN.BIN ../unix/lib.bin
	cd ../unix; ./mklib
	cd ../unix; tx0 -t unix t
	mv ../unix/t ../unix/tlang-min
	rm ../unix/*.t
	rm TSOURCE.T
