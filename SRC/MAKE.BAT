if exist ..\bin\t1.com del ..\bin\t1.com
if exist ..\bin\t0.com ren ..\bin\t0.com ..\bin\t1.com >NUL
ren ..\bin\t.com ..\bin\t0.com >NUL
..\bin\t0 t
ren t.com ..\bin\t.com >NUL
