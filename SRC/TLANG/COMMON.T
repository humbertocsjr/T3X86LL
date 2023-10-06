
! T3X -> DOS/8086 compiler
! Nils M Holm, 2017,2019,2020,2021,2022
! Humberto Costa dos Santos Junior, 2022
! Public Domain / 0BSD license

use t3x:t;

const   BPW = 2;
const   PTRSZ = 4;

const   GPOOL_SIZE = 7;

const   BUFLEN = 512;

const   SYMTBL_SIZE = 2048;
const   LABEL_SIZE = 2048;
const   NLIST_SIZE = 6144;
const   FWDCL_SIZE = 128;

var     Outname::80;
var     Inname::80;

var     Line;

var     Verbose;

var     Incount;

var     CalcStackTop;
var     StackTop;

const   ENDFILE = %1;
const   EOFCHAR = 0x1a;

var ntoa_buf::100;

ntoa(x) do var i, k;
	if (x = 0) return "0";
	i := 0;
	k := x<0-> -x: x;
	while (k > 0) do
		i := i+1;
		k := k/10;
	end
	i := i+1;
	if (x < 0) i := i+1;
	ntoa_buf::i := 0;
	k := x<0-> -x: x;
	while (k > 0) do
		i := i-1;
		ntoa_buf::i := '0' + k mod 10;
		k := k/10;
	end
	if (x < 0) do
		i := i-1;
		ntoa_buf::i := '-';
	end
	return @ntoa_buf::i;
end

str_length(s) return t.memscan(s, 0, 32767);

str_copy(sd, ss) t.memcopy(sd, ss, str_length(ss)+1);

str_append(sd, ss) t.memcopy(@sd::str_length(sd), ss, str_length(ss)+1);

str_equal(s1, s2) return t.memcomp(s1, s2, str_length(s1)+1) = 0;

writes(s) t.write(1, s, str_length(s));

nl() do var b::3;
	writes(t.newline(b));
end

aw(m, s) do
	writes("Error: ");
	writes(Inname);
	writes(": ");
	writes(ntoa(Line));
	writes(": ");
	writes(m);
	if (s \= 0) do
		writes(": ");
		writes(s);
	end
	nl();
	if (Outname::0) t.remove(Outname);
	halt 1;
end

oops(m, s) do
	writes("Internal error");
	nl();
	aw(m, s);
end

numeric(c) return '0' <= c /\ c <= '9';

alphabetic(c) return 'a' <= c /\ c <= 'z' \/
		     'A' <= c /\ c <= 'Z';
