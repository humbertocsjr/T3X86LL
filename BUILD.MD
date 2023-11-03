TLang
=====


Build on UNIX
=============

- Install gcc-multilib
- Install T3X/0 Compiler from http://t3x.org/t3x/
    - Edit Makefile replacing:
        ```
        tcvm: tcvm.c
            cc -O2 -g -o tcvm tcvm.c
        ```
        by:
        ```
        tcvm: tcvm.c
            cc -m32 -O2 -g -o tcvm tcvm.c
        ```
        and config BINDIR variable in Makefile
    - Run make
    - Run make all-native 
    - Run sudo make install-native
- Run 'make all' in shell
- Install running 'make install' in shell

Binaries output: unix/

Build on DOS
============

- Run 'MAKE.BAT'

Binaries output: BIN/
