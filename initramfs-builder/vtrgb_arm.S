.globl _start
_start:
	mov r7, #54
	mov r0, #0
	mov r1, #0x4b71
	adds r2, pc, #.vtrgb-._x
	svc 0
._x:
	mov r7, #1
	neg r0, r0
	svc 0
x:	wfi
	b x
.vtrgb:
	.byte 1,1,1,222,56,43,57,181,74,255,199,6,0,111,184,118,38,113,44,181,233,204,204,204,128,128,128,255,0,0,0,255,0,255,255,0,0,0,255,255,0,255,0,255,255,255,255,255
.section .note.GNU-stack
