.globl _start
_start:
	mov $54, %eax
	xor %ebx, %ebx
	mov $0x4b71, %ecx
	mov $vtrgb, %edx
	int $0x80
	xor %ebx, %ebx
	sub %eax, %ebx
	xor %eax, %eax
	inc %eax
	int $0x80
x:	hlt
	jmp x
vtrgb:
	# This is the color setup from Ubuntu
	.byte 1,1,1,222,56,43,57,181,74,255,199,6,0,111,184,118,38,113,44,181,233,204,204,204,128,128,128,255,0,0,0,255,0,255,255,0,0,0,255,255,0,255,0,255,255,255,255,255
