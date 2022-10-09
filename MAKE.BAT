@echo off
echo Remove current build
cd bin
if exist *.bin del *.bin
if exist *.com del *.com
cd ..
echo Building S86 Assembler (Temporary)
cd s86
call prepare.bat
cd ..
echo Building LIB (Temporary)
cd lib
call make.bat
cd ..
echo Building T3X Compiler (Temporary)
cd src
call prepare.bat
cd ..
echo Building T3X Compiler (Intermediary)
cd src
call make.bat
cd ..
echo Building S86 Assembler
cd s86
call make.bat
cd ..
echo Building Tools (Temporary)
cd tools
call make.bat
cd ..
echo Building LIB (Final)
cd lib
call make.bat
cd ..
echo Building T3X Compiler (Final)
cd src
call make.bat
cd ..
echo Building S86 Assembler (Final)
cd s86
call make.bat
cd ..
echo Building Tools (Final)
cd tools
call make.bat
cd ..
echo Building Samples
cd samples
call make.bat
cd ..
del bin\t0.com
del bin\t1.com
