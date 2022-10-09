
		################ ############ ######   ######
		##            ## ##        ##  ##  ## ##  ##
		######    ###### #######   ##   ##  ###  ##
		    ##    ##        ##    ##     ##     ##
		    ##    ##     #######   ##   ##  ###  ##
		    ##    ##     ##        ##  ##  ## ##  ##
		    ########     ############ ######   ######

		----==[ A MINIMAL PROCEDURAL LANGUAGE ]==----
		----------==[ LOW LEVEL EDITION ]==----------


	T3X/86 - A T3X compiler for 8086-based computers running DOS

	For a summary of the T3X language, see http://t3x.org/t3x/

	T3X/86 is a single-stage two-pass compiler for a superset of
	version 9 of the T3X programming language (T3X9). It cross-
	compiles in 0.1s on modern hardware and self-compiles in about
	35 seconds on an emulated 50MHz PC/XT. it is packaged in a
	single 29KB COM file and needs no additional programs or
	libraries. It compiles directly from T3X to 8086 machine code
	and should work on any x86-based DOS machine. Of course
	T3X/86 can be set up as a cross compiler to DOS on any system
	providing a pre-existing T3X implementation.

	The source code of T3X/86 is based on T3X9, but makes some
	improvements, like better T3X compatibility and slightly more
	efficient code generation. It consists of ~1906 lines of T3X
	plus ~890 lines of 8086 assembly language for the runtime
	library. It triple-tests successfully.

	A simple 8086 assembler for compiling the runtime library is
	contained in this archive. It is written in T3X and can be
	recompiled with the T3X/86 compiler.


	INSTALLING THE T3X/86 COMPILER

	Copy the contents of BIN folder to destination.


	COMPILING THE COMPILER

	This step requires the T3X/86 source code. If you downloaded a
	binary package, fetch it at the T3X homepage (see top of file).

	You need an existing T3X compiler in order to compile T3X/86.
	The provided binary (T.BIN) will do fine.

	The following instructions are for cross-compiling T3X/86 on
	Unix.

	First compile the S86 assembler and compile the runtime library:

	tx -ml s86.t
	./s86 lib.s86 lib.bin

	Then generate a version of the compiler source code that contains
	an image of the library:

	tx -ml mklib.t
	./mklib

	Finally, compile the compiler:

	tx -ml t.t

	and self-compile the compiler:

	./t t

	This last step will generate the final "t.com" file.


	RE-BUILDING THE COMPILER UNDER DOS

	The easiest way is to just extract the archive and run the
	BUILD.BAT file.

	To compile T3X/86 manually, you need the following files on your
	DOS machine:

	DOSFILE.COM (renamed DOSFILE.BIN)
	T.COM       (renamed T.BIN)
	T.SRC
	MKLIB.T
	S86.T
	LIB.S86

	The source files need to be in DOS text format, so you will have
	to convert them first (note: lower-case /r):

	DOSFILE T.SRC /r dos
	DOSFILE MKLIB.T /r dos
	DOSFILE S86.T /r dos
	DOSFILE LIB.S86 /r dos

	(Actually this step is not necessary, because the compiler will
	 happily process Unix text files. However, if you want to edit
	 these files on DOS, it may be helpful.)

	Next, compile the S86 assembler and assemble the runtime library:

	T S86 /v
	S86 LIB.S86 LIB.BIN

	Then, generate the actual compiler source code. This step will
	merge the files T.SRC and LIB.BIN and generate the file T.T:

	T MKLIB
	MKLIB

	The compiler is now ready to self-compile, but do rename it
	before bootstrapping, because it will erase the file T.COM in
	case of an error:

	COPY T.COM T0.COM
	T0 T /v

	This may take a moment, so the /v option will entertain you
	while you stand by. :)


	TESTING THE COMPILER

	There is a simple test suite in the file TEST.T. To test the
	compiler, compile and run that file. (Do not forget to convert
	TEST.T to DOS text format first!):

	T TEST
	TEST


	TRIPLE-TESTING THE COMPILER

	In order to triple-test the compiler, first install it on a DOS
	machine or emulator. If you did not generate the file T.T on DOS,
	you will also need the DOSFILE command (which is included in the
	T3X/86 archive) to convert the source code to DOS text format:

	DOSFILE T.T /r dos

	You can then run the triple test:

	COPY T.COM T0.COM
	T0 T /v
	COPY T.COM T1.COM
	T1 T /v

	At this point the files T1.COM and T.COM should be identical.


	USAGE

	T FILE     will compile FILE.T to FILE.COM.

	T FILE /v  will print function names while compiling; this is
		   intended as a progress indicator.


	GETTING STARTED

	The file T3X.TXT contains a very brief introduction to the T3X9
	language. There are some example programs and utilities in this
	archive. Then, there is the compiler source code in the file
	T.SRC. A lot of additional information can be found on the T3X
	homepage, mentioned at the top of this file.


	THE T3X/86 LANGUAGE AND COMPILER

	The T3X/86 compiler is derived from the T3X9 compiler, but
	implements a larger subset of the full T3X language. However,
	T3X/86 is still not a full T3X compiler. This is a summary of
	its limitations:

	* The only runtime class available is T3X, the core class.

	* Generated code is less efficient than that of the full T3X
	  optimizing compiler.

	With these differences in mind, the T3X documentation also
	applies to T3X/86. See, for instance, the T3X 7.x package at
	the T3X home page or, for a more scenic view, have a look at
	the T3X book: t3x.org/t3x/t3x.html

	FED HIGHLIGHT SYNTAX

	Replace FED.SYN file of Folding Text Editor with 
	EXTRAS\FED.SYN.

	LOW LEVEL EXTENSIONS

	* t.int86ax(int,ax,bx,cx,dx,si,di)
	    Call 8088 interrupt returning AX
	* t.int86z(int,ax,bx,cx,dx,si,di)
	    Call 8088 interrupt returning ZF
	* t.int86c(int,ax,bx,cx,dx,si,di)
	    Call 8088 interrupt returning CF
	* t.fargetw(segment,offset)
	    Return 16-bit value from far pointer
	* t.farsetw(segment,offser,value)
	    Set 16-bit value on far pointer
	* t.fargetb(segment,offset)
	    Return 8-bit value from far pointer
	* t.farsetb(segment,offser,value)
	    Set 8-bit value on far pointer
	* t.farcopy(segd, dest, sego, orig, len)
	    Copy LEN bytes from sego:orig to segd:dest
	* t.farcomp(seg1, ptr1, seg2, ptr2, len)
	    Compares LEN bytes from seg1:ptr1 with seg2:ptr2
	* t.farscan(segment,offset,value,len)
	    Scan VALUE in LEN bytes of far pointer
	* t.local()
	    Get local segment
	* var ptr[T3X.PTRSIZE]
	    Create new var with far pointer size
	* t.setptr(ptr,segment,offset)
	    Set far pointer.
	    Example: t.setptr(ptr,t.local(),@example);
	* callfar ptr()
	    Call far function on far pointer
	* example() far do end
	    Create far function
	* example_int(ax,bx,cx,dx,ds,si,es,si,ss,sp) farint do end
	    Create interrupt handler with direct manipulation of 
	    returning registers and CF.
	    Example: 
		my_int(ax,bx,cx,dx,ds,si,es,si,ss,sp) farint do
		    ax := 123;
		    cx := ax * 2;
		    return 1; ! Return CF = 1
		end

		do var old79, old79seg, ret;
		    ! Store old int 0x79
		    old79 := t.fargetw(0, 0x79*4);
		    old79seg := t.fargetw(0, 0x79*4+2);
		    ! Set new int 0x79
		    t.farsetw(0, 0x79*4, @my_int);
		    t.farsetw(0, 0x79*4+2, t.local());
		    ! Call int 0x79
		    ret := t.int86ax(0x79, 0,0,0,0, 0,0); ! ret=123
		    ! Restore old int 0x79
		    t.farsetw(0, 0x79*4, old79);
		    t.farsetw(0, 0x79*4+2, old79seg);
		end



