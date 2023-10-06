
const   MAXTBL   = 128;
const   MAXLOOP  = 100;

var     Retlab;
var     Rettype;
var     Frame;
var     Loop0;
var     Leaves[MAXLOOP], Lvp;
var     Loops[MAXLOOP], Llp;

expect(tok, s) do var b::100;
	if (tok = Tk) return;
	str_copy(b, s);
	str_append(b, " expected");
	aw(b, Str);
end

expect2(tok1, tok2, s) do var b::100;
	if (tok1 = Tk) return;
	if (tok2 = Tk) return;
	str_copy(b, s);
	str_append(b, " expected");
	aw(b, Str);
end

xeqsign() do
	if (Tk \= BINOP \/ Oid \= Equal_op)
		expect(BINOP, "'='");
	Tk := scan();
end

xsemi() do
	expect(SEMI, "';'");
	Tk := scan();
end

xlparen() do
	expect(LPAREN, "'('");
	Tk := scan();
end

xrparen() do
	expect(RPAREN, "')'");
	Tk := scan();
end

xsymbol() expect(SYMBOL, "symbol");

constfac() do var v, y;
	if (Tk = INTEGER) do
		v := Val;
		Tk := scan();
		return v;
	end
	if (Tk = SYMBOL) do
		y := lookup(Str, CNST);
		Tk := scan();
		return y[SVALUE];
	end
	aw("constant value expected", Str);
end

constval() do var v;
	v := constfac();
	ie (Tk = BINOP /\ Oid = Mul_op) do
		Tk := scan();
		v := v * constfac();
	end
	else if (Tk = BINOP /\ Oid = Add_op) do
		Tk := scan();
		v := v + constfac();
	end
	return v;
end

checklocal(y)
	if (y[SVALUE] > 126 \/ y[SVALUE] < -126)
		aw("local storage exceeded", y[SNAME]);

vardecl(glb) do var y, size, a, farflag;
	Tk := scan();
	while (1) do
		size := 1;
		farflag := 0;
		if (Tk = KFAR) do
			size := PTRSZ;
			farflag := 1;
			Tk := scan();
		end
		xsymbol();
		ie (glb & GLOB) do
			a := globaddr();
			y := add(Str, glb, a);
		end
		else do
			y := add(Str, 0, Lp);
		end
		Tk := scan();
		ie (Tk = LBRACK) do
			if(farflag) 
				aw("invalid size [far]", 0);
			Tk := scan();
			size := constval();
			if (size < 1)
				aw("invalid size", 0);
			y[SFLAGS] := y[SFLAGS] | VECT;
			expect(RBRACK, "']'");
			Tk := scan();
		end
		else if (Tk = BYTEOP) do
			if(farflag) 
				aw("invalid size [far]", 0);
			Tk := scan();
			size := constval();
			if (size < 1)
				aw("invalid size", 0);
			size := (size + BPW-1) / BPW;
			y[SFLAGS] := y[SFLAGS] | VECT;
		end
		ie (glb & GLOB) do
			if (y[SFLAGS] & VECT) do
				gen(CG_STACK, -(size*BPW));
				Dp := Dp + size*BPW;
				gen(CG_GLOBVEC, a);
			end
		end
		else do
			ie (y[SFLAGS] & VECT) do
				gen(CG_STACK, -((Ls+size)*BPW));
				Lp := Lp - size*BPW;
				Ls := 0;
				gen(CG_LOCLVEC, 0);
			end
			else do
				Ls := Ls + 1;
			end
			Lp := Lp - BPW;
			y[SVALUE] := Lp;
			! checklocal(y);
		end
		if (Tk \= COMMA) leave;
		Tk := scan();
	end
	xsemi();
end

constdecl(glb) do var y;
	Tk := scan();
	while (1) do
		xsymbol();
		y := add(Str, glb|CNST, 0);
		Tk := scan();
		xeqsign();
		y[SVALUE] := constval();
		if (Tk \= COMMA) leave;
		Tk := scan();
	end
	xsemi();
end

stcdecl(glb) do var y, i;
	Tk := scan();
	xsymbol();
	y := add(Str, glb|CNST, 0);
	Tk := scan();
	xeqsign();
	i := 0;
	while (1) do
		xsymbol();
		add(Str, glb|CNST, i);
		i := i+1;
		Tk := scan();
		if (Tk \= COMMA) leave;
		Tk := scan();
	end
	y[SVALUE] := i;
	xsemi();
end

fwddecl() do var y, n, l1, l2;
	Tk := scan();
	l1 := newlab();
	gen(CG_JUMP, findlab(l1));
	while (1) do
		xsymbol();
		l2 := newlab();
		commit();
		addfwd(l2, Tp);
		y := add(Str, GLOB|FORW, Tp);
		gen(CG_JUMP, findlab(l2));
		Tk := scan();
		xlparen();
		n := constval();
		if (n < 0) aw("invalid arity", 0);
		y[SFLAGS] := y[SFLAGS] | (n << 8);
		xrparen();
		if (Tk \= COMMA) leave;
		Tk := scan();
	end
	resolve(l1);
	xsemi();
end

decl    stmt(1);

impdecl() do
	Tk := scan();
	Line := 0;
	str_copy(Inname, Str);
	if (Verbose) do
		if(Incount > 0) writes("[ OK ]");
		nl();
		writes(" ");
		writes(Str);
		writes(":");
	end
	Incount := Incount + 1;
	Tk := scan();
end

fundecl() do
	var     l_base, l_addr;
	var     i, na, oyp, onp;
	var     y, l;

	if (Verbose) do
		!writes(Str);
		!nl();
		writes(".");
	end
	l_addr := 2*BPW;
	na := 0;
	l := newlab();
	gen(CG_JUMP, findlab(l));
	commit();
	y := add(Str, GLOB|FUNC, Tp);
	Tk := scan();
	oyp := Yp;
	onp := Np;
	l_base := Yp;
	xlparen();
	while (Tk = SYMBOL) do
		add(Str, 0, l_addr);
		l_addr := l_addr + BPW;
		na := na+1;
		Tk := scan();
		if (Tk \= COMMA) leave;
		Tk := scan();
	end
	xrparen();
	Rettype := KEND;
	if (Tk = KFAR) do
	    y[SFLAGS] := y[SFLAGS] | FUNCF;
	    Rettype := KFAR;
	    Tk := scan();
	end
	if (Tk = KFINT) do
	    y[SFLAGS] := y[SFLAGS] | FUNCI;
	    Rettype := KFINT;
	    Tk := scan();
	end
	for (i = l_base, Yp, SYM) do
	    ie (Rettype = KFAR)
		Syms[i+SVALUE] := 8+na*BPW - Syms[i+SVALUE];
	    else ie (Rettype = KFINT)
		Syms[i+SVALUE] := 2 - Syms[i+SVALUE];
	    else
		Syms[i+SVALUE] := 6+na*BPW - Syms[i+SVALUE];
	end
	if (y[SFLAGS] & FORW) do
		if (na \= y[SFLAGS] >> 8)
			aw("function does not match DECL", y[SNAME]);
		y[SFLAGS] := y[SFLAGS] & ~FORW | FUNC;
		resolve_fwd(y[SVALUE]);
		y[SVALUE] := Tp;
	end
	y[SFLAGS] := y[SFLAGS] | (na << 8);
	if (na) gen(CG_MKFRAME, 0);
	Frame := na;
	Retlab := newlab();
	if (Rettype = KFINT) do
	    gen(CG_PUSHA, 0);
	    Lp := Lp - 20;
	end
	stmt(1);
	ie (Rettype = KFAR) do
	    if (Retlab) resolve(Retlab);
	    Retlab := 0;
	    if (Frame) gen(CG_DELFRAME, 0);
	    Frame := 0;
	    gen(CG_RETF, 0);
	end
	else ie (Rettype = KFINT) do
	    if (Retlab) resolve(Retlab);
	    Retlab := 0;
	    if (Frame) do
		gen(CG_POPA, 0);
		gen(CG_DELFRAME, 0);
	    end
	    Frame := 0;
	    gen(CG_IRET, 0);
	end
	else do
	    if (Retlab) resolve(Retlab);
	    Retlab := 0;
	    if (Frame) gen(CG_DELFRAME, 0);
	    Frame := 0;
	    gen(CG_RET, 0);
	end
	resolve(l);
	Yp := oyp;
	Np := onp;
	Lp := 0;
end

declaration(glb)
	ie(Tk = KIMPORTED) do
		impdecl();
	end
	else ie (Tk = KVAR)
		vardecl(glb);
	else ie (Tk = KCONST)
		constdecl(glb);
	else ie (Tk = KSTRUCT)
		stcdecl(glb);
	else ie (Tk = KDECL)
		fwddecl();
	else
		fundecl();

decl    expr(1);

load(y) ie (y[SFLAGS] & GLOB)
		gen(CG_LDGLOB, y[SVALUE]);
	else
		gen(CG_LDLOCL, y[SVALUE]);

store(y)
	ie (y[SFLAGS] & GLOB)
		gen(CG_STGLOB, y[SVALUE]);
	else
		gen(CG_STLOCL, y[SVALUE]);

fncall(fn, ind) do var i , msg;
	msg := "call of non-function";
	Tk := scan();
	if (fn = 0) aw(msg, 0);
	if (\ind /\ fn[SFLAGS] & (FUNC|FORW) = 0) aw(msg, fn[SNAME]);
	i := 0;
	while (Tk \= RPAREN) do
		expr(0);
		i := i+1;
		if (Tk \= COMMA) leave;
		Tk := scan();
		if (Tk = RPAREN)
			aw("syntax error", Str);
	end
	if (\ind /\ i \= fn[SFLAGS] >> 8)
		aw("wrong number of arguments", fn[SNAME]);
	expect(RPAREN, "')'");
	if (fn[SFLAGS] & (FUNCI))
		aw("wrong function type", fn[SNAME]);
	Tk := scan();
	if (active()) spill();
	ie (ind = 2) do
	    if (fn[SFLAGS] & FUNC)
		aw("wrong variable type", fn[SNAME]);
	    load(fn);
	    gen(CG_CALRF, 0);
	end 
	else do 
	    if (fn[SFLAGS] & FUNCF)
		aw("wrong function type", fn[SNAME]);
	    ie (fn[SFLAGS] & (FUNC|FORW))
		    gen(CG_CALL, fn[SVALUE]);
	    else do
		    load(fn);
		    gen(CG_CALR, 0);
	    end
	end
	if (i \= 0) gen(CG_UNSTACK, i*BPW);
	activate();
end

mkstring(s) do var i, a, k, l;
	k := str_length(s);
	l := newlab();
	gen(CG_JUMP, findlab(l));
	commit();
	a := Tp;
	for (i=0, k+1) emit(s::i);
	resolve(l);
	return a;
end

mkbytevec() do var a, l, k;
	Tk := scan();
	expect(LBRACK, "'['");
	Tk := scan();
	l := newlab();
	gen(CG_JUMP, findlab(l));
	commit();
	a := Tp;
	while (1) do
		k := constval();
		if (k > 255 \/ k < 0)
			aw("byte vector member out of range", Str);
		emit(k);
		if (Tk \= COMMA) leave;
		Tk := scan();
	end
	expect(RBRACK, "']'");
	Tk := scan();
	resolve(l);
	return a;
end

var     gtbl[MAXTBL*3], gaf[MAXTBL*3];

mktable2(depth) do
	var     n, i, a, l, y;
	var     tbl, af;
	var     dynamic;

	if (depth > 2) aw("table nesting too deep", 0);
	tbl := @gtbl[depth*128];
	af := @gaf[depth*128];
	Tk := scan();
	dynamic := 0;
	n := 0;
	while (Tk \= RBRACK) do
		if (n >= MAXTBL)
			aw("table too big", 0);
		ie (Tk = LPAREN /\ \dynamic) do
			Tk := scan();
			dynamic := 1;
			loop;
		end
		else ie (dynamic) do
			expr(1);
			l := newlab();
			gen(CG_STGLOB, findlab(l));
			tbl[n] := 0;
			af[n] := l;
			if (Tk = RPAREN) do
				Tk := scan();
				dynamic := 0;
			end
		end
		else ie (Tk = INTEGER \/ Tk = SYMBOL) do
			tbl[n] := constval();
			af[n] := 0;
		end
		else ie (Tk = STRING) do
			tbl[n] := mkstring(Str);
			af[n] := 0;
			Tk := scan();
		end
		else ie (Tk = LBRACK) do
			tbl[n] := mktable2(depth+1);
			af[n] := 0;
		end
		else ie (Tk = KPACKED) do
			tbl[n] := mkbytevec();
			af[n] := 0;
		end
		else ie (Tk = ADDROF) do
			Tk := scan();
			xsymbol();
			y := lookup(Str, FUNC);
			tbl[n] := y[SVALUE];
			af[n] := 0;
			Tk := scan();
		end
		else do
			aw("invalid table element", Str);
		end
		n := n+1;
		if (Tk \= COMMA) leave;
		Tk := scan();
		if (Tk = RBRACK)
			aw("syntax error", Str);
	end
	if (dynamic)
		aw("missing ')' in dynamic table", 0);
	expect(RBRACK, "']'");
	if (n = 0) aw("empty table", 0);
	Tk := scan();
	l := newlab();
	gen(CG_JUMP, findlab(l));
	commit();
	a := Tp;
	for (i=0, n) do
		if (af[i]) resolve(af[i]);
		emitw(tbl[i]);
	end
	resolve(l);
	return a;
end

mktable() return mktable2(0);

decl    factor(0);

address(lv, bp) do var y;
	y := lookup(Str, 0);
	Tk := scan();
	ie (y[SFLAGS] & CNST) do
		if (lv > 0) aw("invalid location", y[SNAME]);
		spill();
		gen(CG_LDVAL, y[SVALUE]);
	end
	else ie (y[SFLAGS] & (FUNC|FORW)) do
		! Don't load
	end
	else if (lv = 0 \/ Tk = LBRACK \/ Tk = BYTEOP) do
		spill();
		load(y);
	end
	if (Tk = LBRACK \/ Tk = BYTEOP)
		if (y[SFLAGS] & (FUNC|FORW|CNST))
			aw("bad subscript", y[SNAME]);
	while (Tk = LBRACK) do
		Tk := scan();
		bp[0] := 0;
		expr(0);
		expect(RBRACK, "']'");
		Tk := scan();
		y := 0;
		gen(CG_INDEX, 0);
		if (lv = 0 \/ Tk = LBRACK  \/ Tk = BYTEOP)
			gen(CG_DEREF, 0);
	end
	if (Tk = BYTEOP) do
		Tk := scan();
		bp[0] := 1;
		factor();
		y := 0;
		gen(CG_INDXB, 0);
		if (lv = 0) gen(CG_DREFB, 0);
	end
	return y;
end

factor() do var y, op, b;
	ie (Tk = INTEGER) do
		spill();
		gen(CG_LDVAL, Val);
		Tk := scan();
	end
	else ie (Tk = SYMBOL) do
		y := address(0, @b);
		if (Tk = LPAREN) fncall(y, 0);
	end
	else ie (Tk = STRING) do
		spill();
		gen(CG_LDADDR, mkstring(Str));
		Tk := scan();
	end
	else ie (Tk = LBRACK) do
		spill();
		gen(CG_LDADDR, mktable());
	end
	else ie (Tk = KPACKED) do
		spill();
		gen(CG_LDADDR, mkbytevec());
	end
	else ie (Tk = ADDROF) do
		Tk := scan();
		y := address(2, @b);
		ie (y = 0) do
			;
		end
		else ie (y[SFLAGS] & GLOB) do
			spill();
			gen(CG_LDADDR, y[SVALUE]);
		end
		else do
			spill();
			gen(CG_LDLREF, y[SVALUE]);
		end
	end
	else ie (Tk = BINOP) do
		if (Oid \= Minus_op)
			aw("syntax error", Str);
		Tk := scan();
		factor();
		gen(CG_NEG, 0);
	end
	else ie (Tk = UNOP) do
		op := Oid;
		Tk := scan();
		factor();
		gen(Ops[op][OCODE], 0);
	end
	else ie (Tk = LPAREN) do
		Tk := scan();
		expr(0);
		xrparen();
	end
	else ie (Tk = KCALL) do
		Tk := scan();
		xsymbol();
		y := lookup(Str, 0);
		Tk := scan();
		if (Tk \= LPAREN) aw("incomplete CALL", 0);
		fncall(y, 1);
	end
	else ie (Tk = KCALLFAR) do
		Tk := scan();
		xsymbol();
		y := lookup(Str, 0);
		Tk := scan();
		if (Tk \= LPAREN) aw("incomplete CALLFAR", 0);
		fncall(y, 2);
	end
	else do
		aw("syntax error", Str);
	end
end

emitop(stk, p) do
	gen(Ops[stk[p-1]][OCODE], 0);
	return p-1;
end

arith() do var stk[10], p;
	factor();
	p := 0;
	while (Tk = BINOP) do
		while (p /\ Ops[Oid][OPREC] <= Ops[stk[p-1]][OPREC])
			p := emitop(stk, p);
		stk[p] := Oid;
		p := p+1;
		Tk := scan();
		factor();
	end
	while (p > 0)
		p := emitop(stk, p);
end

logop(conop) do var l;
	ie (conop)
		arith();
	else
		logop(%1);
	l := 0;
	while (Tk = (conop-> CONJ: DISJ)) do
		Tk := scan();
		if (\l) l := newlab();
		commit();
		gen(conop-> CG_JMPFALSE: CG_JMPTRUE, findlab(l));
		clear();
		ie (conop)
			arith();
		else
			logop(%1);
	end
	if (l) resolve(l);
end

expr(clr) do var l1, l2;
	if (clr) clear();
	logop(0);
	if (Tk = COND) do
		Tk := scan();
		l1 := newlab();
		l2 := newlab();
		gen(CG_JMPFALSE, findlab(l1));
		expr(1);
		expect(COLON, "':'");
		Tk := scan();
		gen(CG_JUMP, findlab(l2));
		resolve(l1);
		expr(1);
		resolve(l2);
	end
end

halt_stmt() do var r;
	Tk := scan();
	r := Tk = SEMI-> 0: constval();
	gen(CG_HALT, r);
	xsemi();
end

return_stmt() do
	Tk := scan();
	if (Retlab = 0)
		aw("cannot return from main body", 0);
	ie (Tk = SEMI)
		gen(CG_CLEAR, 0);
	else
		expr(1);
	ie (Frame /\ Lp /\ Lp0 = Lp) do
		gen(CG_JUMP, findlab(Retlab));
	end
	else do
		if (Lp \= 0) gen(CG_UNSTACK, -Lp);
		ie (Rettype = KFAR) do
		    if (Frame) gen(CG_DELFRAME, 0);
		    gen(CG_RETF, 0);
		end
		else ie (Rettype = KFINT) do
		    if (Frame) do
			gen(CG_POPA, 0);
			gen(CG_DELFRAME, 0);
		    end
		    gen(CG_IRET, 0);
		end
		else do
		    if (Frame) gen(CG_DELFRAME, 0);
		    gen(CG_RET, 0);
		end
	end
	xsemi();
end

if_stmt(alt) do var l1, l2;
	Tk := scan();
	xlparen();
	expr(1);
	l1 := newlab();
	gen(CG_JMPFALSE, findlab(l1));
	xrparen();
	stmt(0);
	if (alt \/ Tk = KELSE) do
		l2 := newlab();
		gen(CG_JUMP, findlab(l2));
		resolve(l1);
		l1 := l2;
		expect(KELSE, "ELSE");
		Tk := scan();
		stmt(0);
	end
	resolve(l1);
end

while_stmt() do var olp, olv, l, a0;
	Tk := scan();
	commit();
	olp := Loop0;
	olv := Lvp;
	a0 := Tp;
	Loop0 := Tp;
	xlparen();
	expr(1);
	xrparen();
	l := newlab();
	gen(CG_JMPFALSE, findlab(l));
	stmt(0);
	gen(CG_JUMP, a0);
	resolve(l);
	while (Lvp > olv) do
		resolve(Leaves[Lvp-1]);
		Lvp := Lvp-1;
	end
	Loop0 := olp;
end

for_stmt() do
	var     y, l, a0;
	var     step;
	var     oll, olp, olv;
	var     test;

	Tk := scan();
	oll := Llp;
	olv := Lvp;
	olp := Loop0;
	Loop0 := 0;
	xlparen();
	xsymbol();
	y := lookup(Str, 0);
	if (y[SFLAGS] & (CNST|FUNC|FORW))
		aw("unexpected type", y[SNAME]);
	Tk := scan();
	xeqsign();
	expr(1);
	store(y);
	expect2(COMMA, SEMI, "','");
	Tk := scan();
	commit();
	a0 := Tp;
	test := Tp;
	load(y);
	expr(0);
	ie (Tk = COMMA) do
		Tk := scan();
		step := constval();
	end
	else do
		step := 1;
	end
	l := newlab();
	gen(step<0-> CG_FORDOWN: CG_FOR, findlab(l));
	xrparen();
	stmt(0);
	while (Llp > oll) do
		resolve(Loops[Llp-1]);
		Llp := Llp-1;
	end
	ie (y[SFLAGS] & GLOB) do
		ie (step = 1) do
			gen(CG_INCGLOB, y[SVALUE]);
		end
		else do
			gen(CG_LDGLOB, y[SVALUE]);
			gen(CG_INCR, step);
			gen(CG_STGLOB, y[SVALUE]);
		end
	end
	else do
		ie (step = 1) do
			gen(CG_INCLOCL, y[SVALUE]);
		end
		else do
			gen(CG_LDLOCL, y[SVALUE]);
			gen(CG_INCR, step);
			gen(CG_STLOCL, y[SVALUE]);
		end
	end
	gen(CG_JUMP, a0);
	resolve(l);
	while (Lvp > olv) do
		resolve(Leaves[Lvp-1]);
		Lvp := Lvp-1;
	end
	Loop0 := olp;
end

leave_stmt() do var l;
	Tk := scan();
	if (Loop0 < 0)
		aw("LEAVE not in loop context", 0);
	xsemi();
	if (Lvp >= MAXLOOP)
		aw("too many LEAVEs", 0);
	l := newlab();
	Leaves[Lvp] := l;
	if (Lbp0 \= Lp) gen(CG_UNSTACK, Lbp0-Lp);
	gen(CG_JUMP, findlab(l));
	Lvp := Lvp+1;
end

loop_stmt() do var l;
	Tk := scan();
	if (Loop0 < 0)
		aw("LOOP not in loop context", 0);
	xsemi();
	ie (Loop0 > 0) do
		gen(CG_JUMP, Loop0);
	end
	else do
		if (Llp >= MAXLOOP)
			aw("too many LOOPs", 0);
		l := newlab();
		Loops[Llp] := l;
		if (Lbp0 \= Lp) gen(CG_UNSTACK, Lbp0-Lp);
		gen(CG_JUMP, findlab(l));
		Llp := Llp+1;
	end
end

asg_or_call() do var y, b;
	clear();
	y := address(1, @b);
	ie (Tk = LPAREN) do
		fncall(y, 0);
	end
	else ie (Tk = ASSIGN) do
		Tk := scan();
		expr(0);
		ie (y = 0)
			gen(b-> CG_STINDB: CG_STINDR, 0);
		else ie (y[SFLAGS] & (FUNC|FORW|CNST|VECT))
			aw("bad location", y[SNAME]);
		else
			store(y);
	end
	else do
		aw("syntax error", Str);
	end
	xsemi();
end

decl    compound(2);

stmt(body) ie (Tk = KFOR)
		for_stmt();
	else ie (Tk = KHALT)
		halt_stmt();
	else ie(Tk = KIMPORTED) do
		impdecl();
	end
	else ie (Tk = KIE)
		if_stmt(1);
	else ie (Tk = KIF)
		if_stmt(0);
	else ie (Tk = KELSE)
		aw("ELSE without IE", 0);
	else ie (Tk = KLEAVE)
		leave_stmt();
	else ie (Tk = KLOOP)
		loop_stmt();
	else ie (Tk = KRETURN)
		return_stmt();
	else ie (Tk = KWHILE)
		while_stmt();
	else ie (Tk = KDO)
		compound(body, 0);
	else ie (Tk = SYMBOL)
		asg_or_call();
	else ie (Tk = KCALL) do
		clear();
		factor();
	end
	else ie (Tk = KCALLFAR) do
		clear();
		factor();
	end
	else ie (Tk = SEMI)
		Tk := scan();
	else
		expect(%1, "statement");

compound(body, main) do var oyp, olp, olbp, onp, ols, msg;
	msg := "unexpected end of compound statement";
	Tk := scan();
	oyp := Yp;
	onp := Np;
	olp := Lp;
	ols := Ls;
	olbp := Lbp0;
	Ls := 0;
	Lbp0 := Lp;
	while (Tk = KVAR \/ Tk = KCONST \/ Tk = KSTRUCT) do
		if (Tk = KVAR /\ \Frame) do
			gen(CG_MKFRAME, 0);
			Frame := 1;
		end
		declaration(0);
	end
	if (Ls) gen(CG_STACK, -(Ls*BPW));
	if (body) Lp0 := Lp;
	if (main) Lbp0 := Lp;
	while (Tk \= KEND) do
		if (Tk = ENDFILE) aw(msg, 0);
		stmt(0);
	end
	Tk := scan();
	if (body) do
		gen(CG_CLEAR, 0);
		resolve(Retlab);
		Retlab := 0;
	end
	if (olp \= Lp) gen(CG_UNSTACK, olp-Lp);
	if (body /\ Frame) do
		if (Rettype = KFINT) gen(CG_POPA, 0);
		gen(CG_DELFRAME, 0);
		Frame := 0;
	end
	Yp := oyp;
	Np := onp;
	Lp := olp;
	Ls := ols;
	Lbp0 := olbp;
end

checkclass()
	if (\str_equal(Str, "t3x"))
		aw("class name must be T3X", Str);

module_decl() do
	Tk := scan();
	xsymbol();
	Tk := scan();
	xlparen();
	xsymbol();
	checkclass();
	Tk := scan();
	xrparen();
	xsemi();
end

use_decl() do
	Tk := scan();
	expect(SYMBOL, "symbol");
	checkclass();
	Tk := scan();
	expect(COLON, "':'");
	Tk := scan();
	xsymbol();
	if (\str_equal(Str, "t"))
		aw("object name must be T", Str);
	Tk := scan();
	xsemi();
end

object_decl() do
	Tk := scan();
	xsymbol();
	if (\str_equal(Str, "t"))
		aw("object name must be T", Str);
	Tk := scan();
	expect(LBRACK, "'['");
	Tk := scan();
	expect(SYMBOL, "symbol");
	checkclass();
	Tk := scan();
	expect(RBRACK, "']'");
	Tk := scan();
	xsemi();
end

program() do var i;
	Tk := scan();
	if(Tk = KIMPORTED) do
		impdecl();
	end
	if (Tk = KMODULE) module_decl();
	if (Tk = KUSE) use_decl();
	if (Tk = KOBJECT) object_decl();
	while ( Tk = KVAR \/ Tk = KCONST \/ Tk = SYMBOL \/
		Tk = KDECL \/ Tk = KSTRUCT \/ Tk = KIMPORTED
	)
		declaration(GLOB);
	if (Tk \= KDO)
		aw("DO or declaration expected", 0);
	compound(0, 1);
	if (Tk \= ENDFILE)
		aw("trailing characters", Str);
	gen(CG_HALT, 0);
	for (i=0, Yp, SYM)
		if (Syms[i+SFLAGS] & FORW /\ Syms[i+SVALUE])
			aw("undefined function", Syms[i+SNAME]);
end
