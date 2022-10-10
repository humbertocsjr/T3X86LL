
localexample() do
    ! Call Video BIOS, writing 'B\r\n' on screen
    t.int86c(0x10, 0xe42,0,0,0,0,0);
    t.int86c(0x10, 0xe0d,0,0,0,0,0);
    t.int86c(0x10, 0xe0a,0,0,0,0,0);
end

farexample() far do
    ! Call Video BIOS, writing 'C\r\n' on screen
    t.int86c(0x10, 0xe43,0,0,0,0,0);
    t.int86c(0x10, 0xe0d,0,0,0,0,0);
    t.int86c(0x10, 0xe0a,0,0,0,0,0);
end

int79(ax,bx,cx,dx,ds,si,es,di,ss,sp) farint do
    ! Return ax = %5
    ax := %5;
    ! Call Video BIOS, writing 'D\r\n' on screen
    t.int86c(0x10, 0xe44,0,0,0,0,0);
    t.int86c(0x10, 0xe0d,0,0,0,0,0);
    t.int86c(0x10, 0xe0a,0,0,0,0,0);
end

do var k, buf::20, old79, old79seg, ptr[T3X.PTRSIZE];
	! Call Video BIOS, writing 'A\r\n' on screen
	t.int86c(0x10, 0xe41,0,0,0,0,0);
	t.int86c(0x10, 0xe0d,0,0,0,0,0);
	t.int86c(0x10, 0xe0a,0,0,0,0,0);
	! Call local function
	localexample();
	! Call far function
	t.setptr(ptr, t.local(), @farexample);
	callfar ptr();
	! Store old 0x79
	old79 := t.fargetw(0, 0x79*4);
	old79seg := t.fargetw(0, 0x79*4+2);
	! Set new int 0x79
	t.farsetw(0, 0x79*4, @int79);
	t.farsetw(0, 0x79*4+2, t.local());
	! Call new int 0x79
	t.int86ax(0x79, 0,0,0,0, 0,0);
	! Restore old 0x79
	t.farsetw(0, 0x79*4, old79);
	t.farsetw(0, 0x79*4+2, old79seg);
	! Write a green 'AAA' on 3rd line of screen
	t.farsetw(0xb800, 320, 0xa41);
	t.farsetw(0xb800, 322, 0xa41);
	t.farsetw(0xb800, 324, 0xa41);
	! Use Library calls to write on screen
	t.write(T3X.SYSOUT, "Enter your name: ", 17);
	k := t.read(T3X.SYSIN, buf, 20);
	ie (k < 3) do
		t.write(T3X.SYSOUT, "Goodbye!\r\n", 10);
	end
	else do
		t.write(T3X.SYSOUT, "Hello, ", 7);
		t.write(T3X.SYSOUT, buf, k-2);
		t.write(T3X.SYSOUT, "!\r\n", 3);
	end
end
