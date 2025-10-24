.intel_syntax noprefix

.extern _text_vma
.extern _binary_end


.global _start

.section .init
# https://dxrgrabowski.github.io/2024/09/27/3-tiniest-elf/
# https://nathanotterness.com/2021/10/tiny_elf_modernized.html
	.byte  0x7f, 0x45, 0x4c, 0x46, 0x02, 0x01, 0x01, 0x00

	// 8 free bytes
. = 0x10
	.byte  0x02, 0x00, 0x3e, 0x00
	.long  0x01
	.quad  _start
	.quad  0x40 //  elf_pgm_hdr

	// 12 free bytes (Unused area in ELF header) (Could put stuff here)
	.quad 0x00
	.int 0x00

	.short 0x40 # Size of this header
	.short 0x38 # Size of program headers
	.short 0x01 # Number of program headers
	.short 0x00 # Size of section headers
	.short 0x00 # Number of section headers
	.short 0x00 # Section header string table index:

// Program header
elf_pgm_hdr:
	.int   0x01
	.int   0x05
	.quad  0
	.quad  _text_vma

. = 0x60
	.quad _binary_end
	.quad _binary_end
	.quad 0x200000

// Could do section header (For DLL)

.section .text

_start:
	mov eax, 1     # write(
	mov edi, 1     #  STDOUT
	mov esi, offset msg
	mov edx, 14
	syscall        # );

	# how do we call XOpenDisplay?

	mov eax, 60    # exit(
	mov edi, 0     #   EXIT_SUCCESS
	syscall        # );

.section .rodata
msg:
	.ascii "Hello, world!\n"
	.set msglen, . - msg

x11lib:
	.ascii "/usr/lib/x86_64-linux-gnu/libX11.so\0"
	

