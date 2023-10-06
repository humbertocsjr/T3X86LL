
const   META     = 256;

const   TOKEN_LEN = 128;

var     Infile;
var     Inbuf::BUFLEN;
var     Ip, Ep;
var     Rejected;
var     Tk;
var     Str::TOKEN_LEN;
var     Val;
var     Oid;

var     Equal_op, Minus_op, Mul_op, Add_op;

struct  OPER = OPREC, OLEN, ONAME, OTOK, OCODE;

var     Ops;

struct  TOKENS =
	SYMBOL, INTEGER, STRING,
	ADDROF, ASSIGN, BINOP, BYTEOP, COLON, COMMA, COND,
	CONJ, DISJ, LBRACK, LPAREN, RBRACK, RPAREN, SEMI, UNOP,
	KCALL, KCONST, KDECL, KDO, KELSE, KEND, KFOR, KHALT, KIE,
	KIF, KLEAVE, KLOOP, KMODULE, KUSE, KOBJECT, KPACKED, KRETURN,
	KSTRUCT, KVAR, KWHILE, KFAR, KFINT, KCALLFAR, KIMPORTED, DOT;

readrc() do var c;
	if (Rejected) do
		c := Rejected;
		Rejected := 0;
		return c;
	end
	if (Ip >= Ep) do
		Ep := t.read(Infile, Inbuf, BUFLEN);
		Ip := 0;
	end
	if (Ip >= Ep) return ENDFILE;
	c := Inbuf::Ip;
	Ip := Ip+1;
	return c;
end

readc() do var c;
	c := readrc();
	return 'A' <= c /\ c <= 'Z'-> c-'A'+'a': c;
end

readec() do var c;
	c := readrc();
	if (c \= '\\') return c;
	c := readrc();
	if (c = 'a') return '\a';
	if (c = 'b') return '\b';
	if (c = 'e') return '\e';
	if (c = 'f') return '\f';
	if (c = 'n') return '\n';
	if (c = 'q') return '"' | META;
	if (c = 'r') return '\r';
	if (c = 's') return '\s';
	if (c = 't') return '\t';
	if (c = 'v') return '\v';
	return c;
end

reject(c) Rejected := c;

skip() do var c;
	c := readc();
	while (1) do
		while (c = ' ' \/ c = '\t' \/ c = '\n' \/ c = '\r') do
			if (c = '\n') Line := Line+1;
			c := readc();
		end
		if (c \= '!')
			return c;
		while (c \= '\n' /\ c \= ENDFILE)
			c := readc();
	end
end

findkw(s) do
	if (s::0 = 'a') do
		if (str_equal(s, "and")) return CONJ;
		return 0;
	end
	if (s::0 = 'c') do
		if (str_equal(s, "callfar")) return KCALLFAR;
		if (str_equal(s, "call")) return KCALL;
		if (str_equal(s, "const")) return KCONST;
		return 0;
	end
	if (s::0 = 'd') do
		if (str_equal(s, "do")) return KDO;
		if (str_equal(s, "decl")) return KDECL;
		return 0;
	end
	if (s::0 = 'e') do
		if (str_equal(s, "else")) return KELSE;
		if (str_equal(s, "end")) return KEND;
		return 0;
	end
	if (s::0 = 'f') do
		if (str_equal(s, "for")) return KFOR;
		if (str_equal(s, "farint")) return KFINT;
		if (str_equal(s, "far")) return KFAR;
		return 0;
	end
	if (s::0 = 'h') do
		if (str_equal(s, "halt")) return KHALT;
		return 0;
	end
	if (s::0 = 'i') do
		if (str_equal(s, "if")) return KIF;
		if (str_equal(s, "ie")) return KIE;
		if (str_equal(s, "imported")) return KIMPORTED;
		return 0;
	end
	if (s::0 = 'l') do
		if (str_equal(s, "leave")) return KLEAVE;
		if (str_equal(s, "loop")) return KLOOP;
		return 0;
	end
	if (s::0 = 'm') do
		if (str_equal(s, "mod")) return BINOP;
		if (str_equal(s, "module")) return KMODULE;
		return 0;
	end
	if (s::0 = 'n') do
		if (str_equal(s, "not")) return UNOP;
		return 0;
	end
	if (s::0 = 'o') do
		if (str_equal(s, "object")) return KOBJECT;
		if (str_equal(s, "or")) return DISJ;
		return 0;
	end
	if (s::0 = 'p') do
		if (str_equal(s, "packed")) return KPACKED;
		return 0;
	end
	if (s::0 = 'r') do
		if (str_equal(s, "return")) return KRETURN;
		return 0;
	end
	if (s::0 = 's') do
		if (str_equal(s, "struct")) return KSTRUCT;
		return 0;
	end
	if (s::0 = 'u') do
		if (str_equal(s, "use")) return KUSE;
		return 0;
	end
	if (s::0 = 'v') do
		if (str_equal(s, "var")) return KVAR;
		return 0;
	end
	if (s::0 = 'w') do
		if (str_equal(s, "while")) return KWHILE;
		return 0;
	end
	return 0;
end

scanop(c) do var i, j;
	i := 0;
	j := 0;
	Oid := %1;
	while (Ops[i][OLEN] > 0) do
		ie (Ops[i][OLEN] > j) do
			if (Ops[i][ONAME]::j = c) do
				Oid := i;
				Str::j := c;
				c := readc();
				j := j+1;
			end
		end
		else do
			leave;
		end
		i := i+1;
	end
	if (Oid = %1) do
		Str::j := c;
		j := j+1;
		Str::j := 0;
		aw("unknown operator", Str);
	end
	Str::j := 0;
	reject(c);
	return Ops[Oid][OTOK];
end

findop(s) do var i;
	i := 0;
	while (Ops[i][OLEN] > 0) do
		if (str_equal(s, Ops[i][ONAME])) do
			Oid := i;
			return Oid;
		end
		i := i+1;
	end
	oops("operator not found", s);
end

symbolic(c) return alphabetic(c) \/ c = '_' \/ c = '.';
start_symbolic(c) return alphabetic(c) \/ c = '_';

scan() do var c, i, k, sgn, base;
	c := skip();
	if (c = ENDFILE \/ c = EOFCHAR) do
		str_copy(Str, "end of file");
		return ENDFILE;
	end
	if (start_symbolic(c)) do
		i := 0;
		while (symbolic(c) \/ numeric(c)) do
			if (i >= TOKEN_LEN-1) do
				Str::i := 0;
				aw("symbol too long", Str);
			end
			Str::i := c;
			i := i+1;
			c := readc();
		end
		Str::i := 0;
		reject(c);
		k := findkw(Str);
		if (k \= 0) do
			if (k = BINOP) findop(Str);
			if (k = UNOP) findop(Str);
			if (k = CONJ) findop(Str);
			if (k = DISJ) findop(Str);
			return k;
		end
		return SYMBOL;
	end
	if (numeric(c) \/ c = '%') do
		sgn := 1;
		i := 0;
		if (c = '%') do
			sgn := %1;
			c := readc();
			Str::i := c;
			i := i+1;
			if (\numeric(c))
				aw("missing digits after '%'", 0);
		end
		base := 10;
		if (c = '0') do
			c := readc();
			if (c = 'x') do
				base := 16;
				c := readc();
				if (\numeric(c) /\ (c < 'a' \/ c > 'f'))
					aw("missing digits after '0x'", 0);
			end
		end
		Val := 0;
		while ( numeric(c) \/
			base = 16 /\ 'a' <= c /\ c <= 'f'
		) do
			if (i >= TOKEN_LEN-1) do
				Str::i := 0;
				aw("integer too long", Str);
			end
			Str::i := c;
			i := i+1;
			c := c >= 'a'-> c-'a'+10: c-'0';
			Val := Val * base + c;
			c := readc();
		end
		Str::i := 0;
		reject(c);
		Val := Val * sgn;
		return INTEGER;
	end
	if (c = '\'') do
		Val := readec();
		if (readc() \= '\'')
			aw("missing ''' in character", 0);
		return INTEGER;
	end
	if (c = '"') do
		i := 0;
		c := readec();
		while (c \= '"' /\ c \= ENDFILE) do
			if (i >= TOKEN_LEN-1) do
				Str::i := 0;
				aw("string too long", Str);
			end
			Str::i := c & (META-1);
			i := i+1;
			c := readec();
		end
		Str::i := 0;
		return STRING;
	end
	return scanop(c);
end
