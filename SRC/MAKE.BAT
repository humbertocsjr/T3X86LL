if exist ..\bin\t1.com del ..\bin\t1.com
if exist ..\bin\t0.com move ..\bin\t0.com ..\bin\t1.com >NUL
move ..\bin\t.com ..\bin\t0.com >NUL
..\bin\t0 t
move t.com ..\bin\t.com >NUL
