copy ..\bin\lib.bin lib.bin >NUL
..\base\mklib
..\base\t t
del lib.bin
ren t.com ..\bin\t.com >NUL