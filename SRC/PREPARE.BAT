copy ..\bin\lib.bin lib.bin >NUL
..\base\prj tsrccom.prj tsource.t tlang
..\base\mklib
..\base\t t /V
ren t.com ..\bin\t.com >NUL
del lib.bin
del tsource.t