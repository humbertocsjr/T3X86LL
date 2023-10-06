var Aout16;
var Origin;


emitlib() do var i, j, k, lib, stack_top;
	lib :=
	!LIBRARY!
    if(Aout16) do
        ! MAGIC
        emit(0xca);
        emit(0xfe);
        ! TEXT
        emitw(TotTp - Origin);
        ! DATA
        emitw(0);
        ! BSS
        stack_top := 0xfffe;
        if(CalcStackTop \= 0) do
            stack_top := TotTp + TotDp + CalcStackTop;
            stack_top := stack_top & 0xfffe;
            if((stack_top & 0xf000) = 0xf000) do
                stack_top := 0xfffe;
            end
        end
        StackTop := stack_top;
        emitw(stack_top);
        ! SYMS
        emitw(0);
        ! ENTRY
        emitw(Origin);
        ! TEXT REALOC
        emitw(0);
        ! DATA REALOC
        emitw(0);
    end
    Tp := Origin;
	i := 0;
	while (lib[i]) do
		k := lib[i];
		i := i+1;
		for (j=0, k) emit(lib[i]::j);
		i := i+1;
	end
    ! TLang COM Header
	emit(0xeb);
	emit(10);
	emit('S');
	emit('I');
	emit('Z');
	emit('E');
	stack_top := 0xfffe;
	if(CalcStackTop \= 0) do
		stack_top := TotTp + TotDp + CalcStackTop;
		stack_top := stack_top & 0xfffe;
		if((stack_top & 0xf000) = 0xf000) do
			stack_top := 0xfffe;
		end
	end
	StackTop := stack_top;
	emitw(stack_top);
	emitw(TotTp);
	emitw(TotDp);
end



init(p) do var i, b::10;
    Origin := 0x100;
	Pass := p;
	Rejected := 0;
	Incount := 0;
	Ip := 0;
	Ep := 0;
	Gp := 0;
	Gtop := 0;
	Outp := 0;
	TotTp := Tp;
	TotDp := Dp;
	Tp := Origin;
	Dp := 0;
	Lp := 0;
	Yp := 0;
	Np := 0;
	Fwp := 0;
	Lab := 0;
	Line := 1;
	Acc := 0;
	Retlab := 0;
	Frame := 0;
	Loop0 := %1;
	Lvp := 0;
	Llp := 0;
	Qi := CG_NULL;
	Codetbl := [
		[ CG_NULL,      ""              ],
		[ CG_PUSH,      "50"            ], ! push ax
		[ CG_CLEAR,     "31c0"          ], ! xor ax,ax
		[ CG_DROP,      "5b"            ], ! pop bx
		[ CG_LDVAL,     "b8,w"          ], ! mov ax,W
		[ CG_LDADDR,    "b8,w"          ], ! mov ax,W
		[ CG_LDLREF,    "8d86,w"        ], ! lea ax,[bp+W]
		[ CG_LDGLOB,    "a1,w"          ], ! mov ax,[W]
		[ CG_LDLOCL,    "8b86,w"        ], ! mov ax,[bp+W]
		[ CG_STGLOB,    "a3,w"          ], ! mov [W],ax
		[ CG_STLOCL,    "8986,w"        ], ! mov [bp+W],ax
		[ CG_STINDR,    "5b8907"        ], ! pop bx; mov [bx],ax
		[ CG_STINDB,    "5b8807"        ], ! pop bx; mov [bx],al
		[ CG_INCGLOB,   "ff06,w"        ], ! inc word [W]
		[ CG_INCLOCL,   "ff86,w"        ], ! inc word [bp+W]
		[ CG_INCR,      "05,w"          ], ! add ax,W
		[ CG_STACK,     "81c4,w"        ], ! add sp,W
		[ CG_UNSTACK,   "81c4,w"        ], ! add sp,W
		[ CG_LOCLVEC,   "89e050"        ], ! mov ax,sp; push ax
		[ CG_GLOBVEC,   "8926,w"        ], ! mov [W],sp
		[ CG_INDEX,     "d1e05b01d8"    ], ! shl ax,1;pop bx;add ax,bx
		[ CG_DEREF,     "89c38b07"      ], ! mov bx,ax; mov ax,[bx]
		[ CG_INDXB,     "5b01d8"        ], ! pop bx; add ax,bx
		[ CG_DREFB,     "89c331c08a07"  ], ! mov bx,ax; xor ax,ax
						   ! mov ax,[bx]
		[ CG_CALL,      "e8,r"          ], ! call R
		[ CG_CALR,      "ffd0"          ], ! call ax
		[ CG_CALRF,     "89c3ff1f"      ], ! mov bx,ax; call far [bx]
		[ CG_JUMP,      "e9,r"          ], ! jmp R
		[ CG_RJUMP,     "eb,b"          ], ! jmps R
		[ CG_JMPFALSE,  "09c07503e9,r"  ], ! or ax,ax; jne +3; jmp R
		[ CG_JMPTRUE,   "09c07403e9,r"  ], ! or ax,ax; je +3; jmp R
		[ CG_FOR,       "5b39c37c03e9,r"], ! pop bx; cmp bx,ax; jl +3
						   ! jmp R
		[ CG_FORDOWN,   "5b39c37f03e9,r"], ! pop bx; cmp bx,ax; jg +3
						   ! jmp R
		[ CG_MKFRAME,   "5589e5"        ], ! push bp; mov bp,sp
		[ CG_DELFRAME,  "5d"            ], ! pop bp
		[ CG_RET,       "c3"            ], ! ret
		[ CG_RETF,      "cb"            ], ! retf
		[ CG_IRET,      "cf"            ], ! iret
		[ CG_HALT,      "b8004ccd21"    ], ! mov ax,4c00h; int 21H
		[ CG_NEG,       "f7d8"          ], ! neg ax
		[ CG_INV,       "f7d0"          ], ! not ax
		[ CG_LOGNOT,    "f7d819c0f7d0"  ], ! neg ax; sbb ax,ax; not ax
		[ CG_ADD,       "5b01d8"        ], ! pop bx; add ax,bx
		[ CG_SUB,       "89c35829d8"    ], ! mov bx,ax;pop ax;sub ax,bx
		[ CG_MUL,       "59f7e9"        ], ! pop cx; imul cx
		[ CG_DIV,       "89c15899f7f9"  ], ! mov cx,ax; pop ax; cwd;
						   ! idiv cx
		[ CG_MOD,       "89c15831d2f7f189d0"], ! mov ax,cx; pop ax
						   ! xor dx,dx; div cx
						   ! mov ax,dx
		[ CG_AND,       "5b21d8"        ], ! pop bx; and ax,bx
		[ CG_OR,        "5b09d8"        ], ! pop bx; or ax,bx
		[ CG_XOR,       "5b31d8"        ], ! pop bx; xor ax,bx
		[ CG_SHL,       "89c158d3e0"    ], ! mov cx,ax;pop ax;shl ax,cl
		[ CG_SHR,       "89c158d3e8"    ], ! mov cx,ax;pop ax;shr ax,cl
!               [ CG_EQ,        "31d25b39c375014a89d0"  ], ! xor dx,dx; pop bx
!               [ CG_NE,        "31d25b39c374014a89d0"  ], ! cmp bx,ax; j?? +3
!               [ CG_LT,        "31d25b39c37d014a89d0"  ], ! dec dx; mov ax,dx
!               [ CG_GT,        "31d25b39c37e014a89d0"  ], ! ??=ne,e,ge,le,g,l
!               [ CG_LE,        "31d25b39c37f014a89d0"  ],
!               [ CG_GE,        "31d25b39c37c014a89d0"  ],
		[ CG_EQ,        "e8,R2f01"      ], ! call $12f
		[ CG_NE,        "e8,R3201"      ], ! call $132
		[ CG_LT,        "e8,R3501"      ], ! call $135
		[ CG_GT,        "e8,R3801"      ], ! call $138
		[ CG_LE,        "e8,R3b01"      ], ! call $13b
		[ CG_GE,        "e8,R3e01"      ], ! call $13e
		[ CG_JMPEQ,     "5b39c37503e9,r"], ! pop bx; cmp bx,ax; jne +3
						   ! jmp R
		[ CG_JMPNE,     "5b39c37403e9,r"], ! ... je +3 ...
		[ CG_JMPLT,     "5b39c37d03e9,r"], ! ... jge +3 ...
		[ CG_JMPGT,     "5b39c37e03e9,r"], ! ... jle +3 ...
		[ CG_JMPLE,     "5b39c37f03e9,r"], ! ... jg +3 ...
		[ CG_JMPGE,     "5b39c37c03e9,r"], ! ... jl +3 ...
		[ CG_PUSHA,"505351521e5606571689e0404050"],
						   ! push ax,bx,cx,dx,ds,si,es
						   ! push di,ss;mov ax,sp;
						   ! inc ax;inc ax;push ax
		[ CG_POPA,
"8b5e06539d83f8007403f9eb01f89c5b895e065b58fa8ed089dcfb5f075e1f5a595b58"],
						   ! mov bx,[bp+6];push bx;popf
						   ! cmp ax,0;jz +3;stc;jmps+1
						   ! clc;pushf;pop bx;
						   ! mov [bp+6],bx
						   ! pop ax,bx;cli;mov ss,ax
						   ! mov sp,bx;sti;pop di,es
						   ! pop si,ds,dx,cx,bx,ax
		[ CG_DIVU,       "89c15831d2f7f1"], ! mov ax,cx; pop ax
						   ! xor dx,dx; div cx
		[ %1,           ""              ] ];
	Opttbl := [
		[ CG_EQ,        0,      CG_JMPFALSE,    CG_JMPNE        ],
		[ CG_NE,        0,      CG_JMPFALSE,    CG_JMPEQ        ],
		[ CG_LT,        0,      CG_JMPFALSE,    CG_JMPGE        ],
		[ CG_GT,        0,      CG_JMPFALSE,    CG_JMPLE        ],
		[ CG_LE,        0,      CG_JMPFALSE,    CG_JMPGT        ],
		[ CG_GE,        0,      CG_JMPFALSE,    CG_JMPLT        ],
		[ CG_LOGNOT,    0,      CG_JMPFALSE,    CG_JMPTRUE      ],
		[ %1,           %1,     %1,             %1              ],
		[ CG_LDVAL,     0,      CG_ADD,         CG_DROP         ],
		%1 ];
	Ops := [[ 7, 3, "mod",  BINOP,  CG_MOD          ],
		[ 0, 1, ".",    DOT,    0               ],
		[ 7, 2, "./",   BINOP,  CG_DIVU         ],
		[ 6, 1, "+",    BINOP,  CG_ADD          ],
		[ 7, 1, "*",    BINOP,  CG_MUL          ],
		[ 0, 1, ";",    SEMI,   0               ],
		[ 0, 1, ",",    COMMA,  0               ],
		[ 0, 1, "(",    LPAREN, 0               ],
		[ 0, 1, ")",    RPAREN, 0               ],
		[ 0, 1, "[",    LBRACK, 0               ],
		[ 0, 1, "]",    RBRACK, 0               ],
		[ 3, 1, "=",    BINOP,  CG_EQ           ],
		[ 5, 1, "&",    BINOP,  CG_AND          ],
		[ 5, 1, "|",    BINOP,  CG_OR           ],
		[ 5, 1, "^",    BINOP,  CG_XOR          ],
		[ 0, 1, "@",    ADDROF, 0               ],
		[ 0, 1, "~",    UNOP,   CG_INV          ],
		[ 0, 1, ":",    COLON,  0               ],
		[ 0, 2, "::",   BYTEOP, 0               ],
		[ 0, 2, ":=",   ASSIGN, 0               ],
		[ 0, 1, "\\",   UNOP,   CG_LOGNOT       ],
		[ 1, 2, "\\/",  DISJ,   0               ],
		[ 3, 2, "\\=",  BINOP,  CG_NE           ],
		[ 4, 1, "<",    BINOP,  CG_LT           ],
		[ 3, 2, "<>",   BINOP,  CG_NE           ],
		[ 4, 2, "<=",   BINOP,  CG_LE           ],
		[ 5, 2, "<<",   BINOP,  CG_SHL          ],
		[ 4, 1, ">",    BINOP,  CG_GT           ],
		[ 4, 2, ">=",   BINOP,  CG_GE           ],
		[ 5, 2, ">>",   BINOP,  CG_SHR          ],
		[ 6, 1, "-",    BINOP,  CG_SUB          ],
		[ 0, 2, "->",   COND,   0               ],
		[ 7, 1, "/",    BINOP,  CG_DIV          ],
		[ 2, 2, "/\\",  CONJ,   0               ],
		[ 2, 3, "and",  CONJ,   0               ],
		[ 2, 3, "or",   DISJ,   0               ],
		[ 0, 3, "not",  UNOP,   CG_LOGNOT       ],
		[ 0, 0, 0,      0,      0               ] ];
	Equal_op := findop("=");
	Minus_op := findop("-");
	Mul_op := findop("*");
	Add_op := findop("+");
	i := 0;
	while (Codetbl[i][0] \= %1) do
		if (Codetbl[i][0] \= i) do
			str_copy(b, ntoa(i));
			oops("bad code table entry", b);
		end
		i := i+1;
	end
	add("t3x.sysin", GLOB|CNST, 0);
	add("t3x.sysout", GLOB|CNST, 1);
	add("t3x.syserr", GLOB|CNST, 2);
	add("t3x.oread", GLOB|CNST, 0);
	add("t3x.owrite", GLOB|CNST, 1);
	add("t3x.oappnd", GLOB|CNST, 3);
	add("t3x.ptrsize", GLOB|CNST, PTRSZ);
	add("t.sysin", GLOB|CNST, 0);
	add("t.sysout", GLOB|CNST, 1);
	add("t.syserr", GLOB|CNST, 2);
	add("t.oread", GLOB|CNST, 0);
	add("t.owrite", GLOB|CNST, 1);
	add("t.oappnd", GLOB|CNST, 3);
	add("t.ptrsize", GLOB|CNST, PTRSZ);
	add("regs86", GLOB|CNST, 9);
	add("regs86.ax", GLOB|CNST, 0);
	add("regs86.bx", GLOB|CNST, 1);
	add("regs86.cx", GLOB|CNST, 2);
	add("regs86.dx", GLOB|CNST, 3);
	add("regs86.ds", GLOB|CNST, 4);
	add("regs86.si", GLOB|CNST, 5);
	add("regs86.es", GLOB|CNST, 6);
	add("regs86.di", GLOB|CNST, 7);
	add("regs86.cf", GLOB|CNST, 8);
	builtin("t.bpw", 0,     0x0108);
	builtin("t.newline", 1, 0x010b);
	builtin("t.memcomp", 3, 0x010e);
	builtin("t.memcopy", 3, 0x0111);
	builtin("t.memfill", 3, 0x0114);
	builtin("t.memscan", 3, 0x0117);
	builtin("t.getarg", 3,  0x011a);
	builtin("t.open", 2,    0x011d);
	builtin("t.close", 1,   0x0120);
	builtin("t.read", 3,    0x0123);
	builtin("t.write", 3,   0x0126);
	builtin("t.rename", 2,  0x0129);
	builtin("t.remove", 1,  0x012c);
	builtin("t.local", 0,   0x0168);
	builtin("t.int86c", 7,  0x0153);
	builtin("t.int86ax", 7, 0x0156);
	builtin("t.int86z", 7,  0x0159);
	builtin("t.int86" , 2,  0x015c);
	emitlib();
end
