if exist ..\bin\t1.com del ..\bin\t1.com
if exist ..\bin\t0.com ren ..\bin\t0.com ..\bin\t1.com >NUL
copy ..\bin\lib.bin lib.bin >NUL
..\base\prj tsrccom.prj tsource.t tlang
..\base\mklib
ren ..\bin\t.com ..\bin\t0.com >NUL
..\bin\t0 t /V
ren t.com ..\bin\t.com >NUL
..\bin\t prj /V
ren prj.com ...\bin\prj.com >NUL
del tsource.t
copy ..\bin\libmin.bin lib.bin >NUL
..\base\prj tsrcmin.prj tsource.t tlang
..\base\mklib
..\base\t t /V
ren t.com ..\bin\tmin.com >NUL
del lib.bin
del tsource.t