
struct  SYM = SNAME, SFLAGS, SVALUE;

const   GLOB = 1;
const   CNST = 2;
const   VECT = 4;
const   FORW = 8;
const   FUNC = 16;
const   FUNCF = 32;
const   FUNCI = 64;

var     Syms[SYM*SYMTBL_SIZE];
var     Labels[LABEL_SIZE];
Var     Lab;
var     Nlist::NLIST_SIZE;

var     Yp, Np;

var     Fwlab[FWDCL_SIZE],
	Fwaddr[FWDCL_SIZE];
var     Fwp;

find(s) do var i;
	i := Yp-SYM;
	while (i >= 0) do
		if (str_equal(Syms[i+SNAME], s))
			return @Syms[i];
		i := i - SYM;
	end
	return 0;
end

lookup(s, f) do var y;
	y := find(s);
	if (y = 0) aw("undefined", s);
	if (y[SFLAGS] & f \= f)
		aw("unexpected type", s);
	return y;
end

newname(s) do var k, new;
	k := str_length(s)+1;
	if (Np+k >= NLIST_SIZE)
		aw("name pool overflow", s);
	new := @Nlist::Np;
	t.memcopy(new, s, k);
	Np := Np+k;
	return new;
end

add(s, f, v) do var y;
	y := find(s);
	if (y \= 0) do
		ie (y[SFLAGS] & FORW /\ f & FUNC)
			return y;
		else
			aw("redefined", s);
	end
	if (Yp+SYM >= SYMTBL_SIZE*SYM)
		aw("too many symbols", 0);
	y := @Syms[Yp];
	Yp := Yp+SYM;
	y[SNAME] := newname(s);
	y[SFLAGS] := f;
	y[SVALUE] := v;
	return y;
end

addfwd(l, a) do
	if (Fwp >= FWDCL_SIZE)
		aw("too many forward declarations", 0);
	Fwlab[Fwp] := l;
	Fwaddr[Fwp] := a;
	Fwp := Fwp+1;
end
