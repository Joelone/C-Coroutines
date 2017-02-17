
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

%assign	P_fun		16
%assign	P_param		12
%assign P_co		8

coroutine_init:
		enter	0,0

		SYSLOG	"init: RET=%08X",dword [ebp + 4]

		mov	edx,[ebp + P_co]
		mov	[edx + co.ysp],esp	; save ESP/EBP
		mov	[edx + co.ybp],ebp	; to yield to
		mov	eax,[edx + co.base]	; get new stack
		add	eax,[edx + co.size]
		mov	esp,eax

		push	dword [ebp + P_fun]	; move stack frame from
		push	dword [ebp + P_param]	; parent stack to
		push	dword [ebp + P_co]	; coroutine stack
		push	dword [ebp + 4]
		enter	0,0

		mov	[edx + co.csp],esp	; save ESP/EBP on coroutine
		mov	[edx + co.cbp],ebp	; stack

		SYSLOG	"init: co=%08X FROM=%08X TO=%08X",edx,dword [edx + co.ybp],dword [edx + co.cbp]
		
		push	edx			; save pointer to _co
		push	dword [ebp + P_param]	; call passed in function
		push	edx
		call	[ebp + P_fun]
		add	esp,8
		pop	edx			; get _co

	;-------------------------------------------------------------------
	; Coroutine finished, so let's yield its result one more time.  Only
	; this time, the code to yield will call abort if it's resumed.
	; We won't return from this.
	;-------------------------------------------------------------------

		push	eax
		push	edx
		call	coroutine_yield
		jmp	abort

;===========================================================================

%assign	P_param		12
%assign P_co		8

coroutine_resume:
		enter	0,0
		mov	eax,[ebp + P_param]
		mov	edx,[ebp + P_co]

		SYSLOG	"resume: co=%08X FROM=%08X TO=%08X",edx,ebp,dword [edx + co.cbp]

		mov	[edx + co.ysp],esp
		mov	[edx + co.ybp],ebp
		mov	esp,[edx + co.csp]
		mov	ebp,[edx + co.cbp]

		SYSLOG	"resume: RET=%08X",dword [ebp + 4]
		leave
		ret

;===========================================================================

%assign	P_param		12
%assign	P_co		8

coroutine_yield:
		enter	0,0
		mov	eax,[ebp + P_param]
		mov	edx,[ebp + P_co]	; return parameter

		SYSLOG	"yield: co=%08X FROM=%08X TO=%08X",edx,ebp,dword [edx + co.ybp]

		mov	[edx + co.csp],esp
		mov	[edx + co.cbp],ebp
		mov	esp,[edx + co.ysp]
		mov	ebp,[edx + co.ybp]

		SYSLOG	"yield: RET=%08X",dword [ebp + 4]
		leave
		ret

;***************************************************************************
