
var     Pass;

var     Outfile;
var     Outbuf::BUFLEN;
var     Outp;

var     Gp, Gtop;

var     Tp, Dp, Lp, Ls, Lp0, Lbp0;
var     TotTp, TotDp;

var     Acc;

var     Codetbl;

struct  OPT = OINST1, OARG, OINST2, OREPL;

var     Opttbl;

struct  CG =    CG_NULL,
		CG_PUSH, CG_CLEAR, CG_DROP,
		CG_LDVAL, CG_LDADDR, CG_LDLREF, CG_LDGLOB,
		CG_LDLOCL,
		CG_STGLOB, CG_STLOCL, CG_STINDR, CG_STINDB,
		CG_INCGLOB, CG_INCLOCL, CG_INCR,
		CG_STACK, CG_UNSTACK, CG_LOCLVEC, CG_GLOBVEC,
		CG_INDEX, CG_DEREF, CG_INDXB, CG_DREFB,
		CG_CALL, CG_CALR, CG_CALRF, CG_JUMP, CG_RJUMP, CG_JMPFALSE,
		CG_JMPTRUE, CG_FOR, CG_FORDOWN, CG_MKFRAME,
		CG_DELFRAME, CG_RET, CG_RETF, CG_IRET, CG_HALT,
		CG_NEG, CG_INV, CG_LOGNOT, CG_ADD, CG_SUB,
		CG_MUL, CG_DIV, CG_MOD, CG_AND, CG_OR, CG_XOR,
		CG_SHL, CG_SHR, CG_EQ, CG_NE, CG_LT, CG_GT,
		CG_LE, CG_GE, CG_JMPEQ, CG_JMPNE, CG_JMPLT,
		CG_JMPGT, CG_JMPLE, CG_JMPGE, CG_PUSHA, CG_POPA, CG_DIVU;

findlab(id) return Labels[id];

newlab() do
	if (Lab >= LABEL_SIZE) aw("too many labels", 0);
	Lab := Lab+1;
	return Lab-1;
end

decl    commit(0);

resolve(id) do
	commit();
	Labels[id] := Tp;
end

resolve_fwd(a) do var i;
	i := 0;
	while (i < Fwp) do
		if (Fwaddr[i] = a) do
			resolve(Fwlab[i]);
			return;
		end
		i := i+1;
	end
	oops("unknown forward reference", 0);
end

flush() do
	if (\Outp) return;
	if (t.write(Outfile, Outbuf, Outp) \= Outp)
		aw("file write error", 0);
	Outp := 0;
end

emit(x) do
	Tp := Tp+1;
	if (Pass = 0) return;
	if (Outp >= BUFLEN) flush();
	Outbuf::Outp := x;
	Outp := Outp + 1;
end

emitw(x) do
	emit(255 & x);
	emit(255 & (x>>8));
end

hex(c)  ie (numeric(c))
		return c-'0';
	else
		return c-'a'+10;

byte(s) return 16*hex(s::0) + hex(s::1);

rgen(s, v) do var n;
	while (s::0) do
		ie (s::0 = ',') do
			ie (s::1 = 'w')
				emitw(v);
			else ie (s::1 = 'l')
				emit(v);
			else ie (s::1 = 'h')
				emit(v+1);
			else ie (s::1 = 'r')
				emitw(v-Tp-2);
			else ie (s::1 = 'R') do
				n := byte(s+4) << 8 | byte(s+2);
				emitw(n-Tp-2);
				s := s+4;
			end
			else ie (s::1 = 'b')
				emit(v);
			else
				oops("bad code", 0);
		end
		else do
			emit(byte(s));
		end
		s := s+2;
	end
end

var     Qi, Qa;

commit() do
	rgen(Codetbl[Qi][1], Qa);
	Qi := CG_NULL;
end

gen(id, a) do var i, skiparg;
	skiparg := %1;
	i := 0;
	while (Opttbl[i] \= %1) do
		ie (Opttbl[i][OINST1] = %1)
			skiparg := 0;
		else if (Qi = Opttbl[i][OINST1] /\
			 id = Opttbl[i][OINST2] /\
			 (skiparg \/ Qa = Opttbl[i][OARG]))
		do
			Qi := Opttbl[i][OREPL];
			Qa := a;
			return;
		end
		i := i+1;
	end
	if (Qi \= CG_NULL) commit();
	Qi := id;
	Qa := a;
end

spill() ie (Acc)
		gen(CG_PUSH, 0);
	else
		Acc := 1;

active() return Acc;

clear() Acc := 0;

activate() Acc := 1;

builtin(name, arity, a)
	add(name, GLOB|FUNC | (arity << 8), a);

globaddr() do var l, i, g;
	if (Gp >= Gtop) do
		gen(CG_RJUMP, GPOOL_SIZE*2);
		commit();
		Gp := Tp;
		for (i=0, GPOOL_SIZE) emitw(0);
		Gtop := Tp;
	end
	g := Gp;
	Gp := Gp+2;
	return g;
end

align(x, a) return (x+a) & ~(a-1);
