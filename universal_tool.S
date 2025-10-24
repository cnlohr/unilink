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
	.short 0x02 # Number of program headers
	.short 0x00 # Size of section headers
	.short 0x00 # Number of section headers
	.short 0x00 # Section header string table index:

// Program header
elf_pgm_hdr:

	// PT_LOAD
	.int   0x01 # p_type = PT_LOAD
	.int   0x05 # p_flags
	.quad  0    # p_offset (we load the ELF header too)
	.quad  _text_vma # p_vaddr
	.quad  0    # p_paddr
	.quad _binary_end # p_filesz
	.quad _binary_end # p_memsz
	.int 0x00 # p_flags
	.int 0x20 # p_align
	// Size 0x38
	.int 0x02  # p_type = PT_DYNAMIC
	.int 0x05  # p_flags
	.quad 0    # 	


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

