
		bits	32
		global	coroutine_init
		global	coroutine_resume
		global	coroutine_yield
		extern	abort
		extern	syslog

;***************************************************************************

		struc	co
			.base:		resd	1
			.size:		resd	1
			.csp:		resd	1
			.cbp:		resd	1
			.ysp:		resd	1
			.ybp:		resd	1
		endstruc

;***************************************************************************

%macro	SYSLOG	1
	section	.rodata
%%text		db	%1,0
	section	.text
		pusha
		push	%%text
		push	7
		call	syslog
		add	esp,8
		popa
%endmacro

%macro	SYSLOG	2
	section	.rodata
%%text		db	%1,0
	section	.text
		pusha
		push	%2
		push	%%text
		push	7
		call	syslog
		add	esp,12
		popa
%endmacro

%macro	SYSLOG	3
	section	.rodata
%%text		db	%1,0
	section	.text
		pusha
		push	%3
		push	%2
		push	%%text
		push	7
		call	syslog
		add	esp,16
		popa
%endmacro

%macro	SYSLOG	4
	section	.rodata
%%text		db	%1,0
	section	.text
		pusha
		push	%4
		push	%3
		push	%2
		push	%%text
		push	7
		call	syslog
		add	esp,20
		popa
%endmacro
			
;***************************************************************************
		section	.text

;===========================================================================

%assign L_co		-4
%assign L_fun		-8

start_it_up:	push	eax
		push	dword [ebp + L_co]
		call	[ebp + L_fun]

		push	eax
		push	dword [ebp + L_co]
		call	coroutine_yield
		jmp	abort

;===========================================================================

%assign	P_fun		12
%assign P_co		8

coroutine_init:
		enter	0,0

		mov	edx,[ebp + P_co]
		
		SYSLOG	"init: stack=%08X",dword [edx + co.base]

		mov	eax,[edx + co.base]
		add	eax,[edx + co.size]

	;------------------------------------------------------------
	; Create the stack for resuming to start_it_up().  The stack
	; is set up as:
	;
	;       EAX ->
	;		+--------------------------+
	;		| L_co                     |
	;		+--------------------------+
	;		| L_fun                    |
	;		+--------------------------+
	;		| start_it_up              |
	;		+--------------------------+
	;     co.cbp -> | EBP of start_it_up (EAX) |
	;		+--------------------------+
	;		| "saved" EBX (0)          |
	;		+--------------------------+
	;		| "saved" ESI (0)          |
	;		+--------------------------+
	;     co.csp -> | "saved" EDI (0)          |
	;		+--------------------------+
	;
	; The code in coroutine.resume() will pop the three registers off
	; the stack, then restore EBP/ESP and "return" to start_it_up.
	;------------------------------------------------------------

		lea	ecx,[eax - 16]

		mov	[ecx],eax		; "previous" EBP
		mov	dword [ecx + 4],start_it_up
		mov	eax,[ebp + P_fun]
		mov	[ecx + 8],eax
		mov	[ecx + 12],edx

		mov	[edx + co.cbp],ecx	; coroutine EBP
		sub	ecx,12			; three "saved" registers
		mov	[edx + co.csp],ecx	; coroutine ESP
		xor	eax,eax			; zero out "saved" registers
		mov	[ecx],eax
		mov	[ecx + 4],eax
		mov	[ecx + 8],eax

		leave
		ret

;===========================================================================

%assign	P_param		12
%assign P_co		8

coroutine_resume:
		enter	0,0
		push	ebx
		push	esi
		push	edi

		mov	eax,[ebp + P_param]
		mov	edx,[ebp + P_co]

		SYSLOG	"resume: co=%08X FROM=%08X TO=%08X",edx,ebp,dword [edx + co.cbp]

		mov	[edx + co.ysp],esp
		mov	[edx + co.ybp],ebp
		mov	esp,[edx + co.csp]
		mov	ebp,[edx + co.cbp]

		SYSLOG	"resume: RET=%08X",dword [ebp + 4]

		pop	edi
		pop	esi
		pop	ebx
		leave
		ret

;===========================================================================

%assign	P_param		12
%assign	P_co		8

coroutine_yield:
		enter	0,0
		push	ebx
		push	esi
		push	edi

		mov	eax,[ebp + P_param]
		mov	edx,[ebp + P_co]	; return parameter

		SYSLOG	"yield: co=%08X FROM=%08X TO=%08X",edx,ebp,dword [edx + co.ybp]

		mov	[edx + co.csp],esp
		mov	[edx + co.cbp],ebp
		mov	esp,[edx + co.ysp]
		mov	ebp,[edx + co.ybp]

		SYSLOG	"yield: RET=%08X",dword [ebp + 4]

		pop	edi
		pop	esi
		pop	ebx
		leave
		ret

;***************************************************************************

