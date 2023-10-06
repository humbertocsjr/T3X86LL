

info() do
	if(Verbose) do
		writes("Text = ");
		writes(ntoa(Tp - Origin));
		writes(", Data = ");
		writes(ntoa(Dp+622));
		writes(", Symbols = ");
		writes(ntoa(Yp/SYM));
		writes(", Nlist = ");
		writes(ntoa(Np));
		writes(", Labels = ");
		writes(ntoa(Lab));
		nl();
	end
	if(CalcStackTop \= 0) do
		writes("Stack Top = ");
		writes(ntoa(StackTop >> 10));
		writes(" KiB");
		nl();
	end
end

phase(in, n) do
	if (Verbose) do
		writes(n-> "Pass 2:": "Pass 1:");
		! nl();
	end
	Infile := t.open(in, T3X.OREAD);
	if (Infile < 0) aw("no such file", in);
	Outfile := t.open(Outname, T3X.OWRITE);
	if (Outfile < 0) aw("cannot create", Outname);
	init(n);
	program();
	commit();
	t.close(Infile);
	flush();
	t.close(Outfile);
	if (Verbose) do
		writes("[ OK ]");
		nl();
	end
end

upcase(s) do var i;
	i := 0;
	while (s::i) do
		if ('a' <= s::i /\ s::i <= 'z')
			s::i := s::i-'a'+'A';
		i := i+1;
	end
	return s;
end

do var in::75, k, i, next;
	Outname::0 := 0;
	Verbose := 0;
	CalcStackTop := 0;
    Aout16 := 0;
    Origin := 0; ! ARCH.T will define
	k := -1;
	next := 1;
	i := 1;
	while(next) do
		next := 0;
		if (t.getarg(i, in, 75) \= %1) do
			next := 1;
			upcase(in);
			ie (str_equal(in, "/V"))
				Verbose := 1;
			else ie (str_equal(in, "/AOUT16"))
				Aout16 := 1;
			else ie (str_equal(in, "/STACK1K"))
				CalcStackTop := 1024;
			else ie (str_equal(in, "/STACK2K"))
				CalcStackTop := 2048;
			else ie (str_equal(in, "/STACK4K"))
				CalcStackTop := 4096;
			else ie (str_equal(in, "/STACK8K"))
				CalcStackTop := 8168;
			else ie (str_equal(in, "/STACK16K"))
				CalcStackTop := 16384;
			else ie (str_equal(in, "/?") \/ str_equal(in, "-h")) do
				writes("Usage: t [filename without extension] [options]");
				nl();
				writes(" /?       Show Help");
				nl();
				writes(" /V       Verbose mode");
				nl();
				writes(" /AOUT16  Set output format to A.out (16)");
				nl();
				writes(" /STACKxK Set stack size manually (1,2,4,8,16)");
				nl();
				writes("          E.g.: /STACK16K");
				nl();
				halt 1;
			end
			else k := i;
		end
		i := i +1;
	end
	if (k < 0) aw("missing file name [Use /? for help]", 0);
	k := t.getarg(k, in, 72);
	t.memcopy(@in::k, ".t", 3);
	str_copy(Inname, in);
	str_copy(Outname, in);
    ie(Aout16)
	    t.memcopy(@Outname::k, ".app", 5);
    else
        t.memcopy(@Outname::k, ".com", 5);
	TotTp := 0;
	TotDp := 0;
	phase(in, 0);
	phase(in, 1);
	info();
end
