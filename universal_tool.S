#include "elf_helpers.h"

.intel_syntax noprefix

.extern _text_vma
.extern _binary_end

.global _start

.section .init
# https://dxrgrabowski.github.io/2024/09/27/3-tiniest-elf/
# https://nathanotterness.com/2021/10/tiny_elf_modernized.html
init_start:

#define PHYS( x ) ( x - init_start)
#define STRLK( x ) (x - string_table)

// Debug this with "readelf -a"

elf_header:
	Elf64_Ehdr( ET_EXEC, EM_X86_64, 1,	/* version */
		_start, 						/* e_entry */
		PHYS(elf_pgm_hdr),				/* e_phoff */
		PHYS(elf_section_headers),		/* e_shoff */
		0,								/* e_flags */
		PHYS( elf_pgm_hdr ),			/* e_ehsize */
		0x38,							/* e_phentsize (Platform-specific) */
		(elf_pgm_hdr_end-elf_pgm_hdr)/0x38,	/* e_phnum */
		0x40,							/* e_shentsize (Platform-specific) */
		(elf_section_headers_end-elf_section_headers)/0x40, /* e_shnum */
		0x01							/* e_shstrndx */ );

// Program header
elf_pgm_hdr:
	// PT_LOAD
	Elf64_Phdr( PT_LOAD,    PF_X | PF_R, 0,                     init_start,      0,                     _binary_end, _binary_end, 0 );
	Elf64_Phdr( PT_DYNAMIC, PF_W | PF_R, PHYS(dynamic_section), dynamic_section, PHYS(dynamic_section), dynamic_end-dynamic_section, dynamic_end-dynamic_section, 8 );
	Elf64_Phdr( PT_INTERP,  PF_R,        PHYS(str_interp), str_interp, PHYS(str_interp), str_interp_end-str_interp, str_interp_end-str_interp, 1 );
elf_pgm_hdr_end:

elf_section_headers:
	Elf64_Shdr( STRLK(str_dynamic),  SHT_DYNAMIC, SHF_ALLOC|SHF_WRITE, PHYS(elf_header), dynamic_section-elf_header, dynamic_end-dynamic_section,   1, 0, 8, 0x10 )
	Elf64_Shdr( STRLK(str_shstrtab), SHT_STRTAB,  0,                   PHYS(elf_header), string_table-elf_header,    string_table_end-string_table, 0, 0, 1, 0x00 )
	Elf64_Shdr( STRLK(str_dynstr),   SHT_STRTAB,  0,                   PHYS(elf_header), dynstr_start-elf_header,    dynstr_end-dynstr_start,       0, 0, 8, 0x00 )
	Elf64_Shdr( STRLK(str_dynsym),   SHT_DYNSYM,  0,                   PHYS(elf_header), dynsym_start-elf_header,    0x18,       2, (dynsym_end-dynsym_start)/0x18, 8, 0x18 )
	Elf64_Shdr( STRLK(str_plt),      SHT_PROGBITS,  0,                 PHYS(elf_header), plt_table_start-elf_header, plt_table_end-plt_table_start, 0x10, (plt_table_end-plt_table_start)/0x10, 0x00, 0x00 )
	Elf64_Shdr( STRLK(str_got),      SHT_PROGBITS,  0,                 PHYS(elf_header), got_table_start-elf_header, got_table_end-got_table_start, 0x08, 0, 0x08, 0x00 )

	// for nix
	Elf64_Shdr( STRLK(str_interp_title), SHT_PROGBITS,  0,             PHYS(elf_header), str_interp-elf_header, str_interp_end-str_interp, 0, 0, 0x01, 0x00 )
elf_section_headers_end:

#define DYNAMICENTRY( type, addr ) \
	.quad type;\
	.quad addr;\

dynamic_section:
	DYNAMICENTRY( DT_NEEDED, str_libX11 - dynstr_start );
	DYNAMICENTRY( DT_STRTAB, dynstr_start );
	DYNAMICENTRY( DT_SYMTAB, symtab_start );
	DYNAMICENTRY( DT_STRSZ, dynstr_end-dynstr_start );

	DYNAMICENTRY( DT_RELA, dt_rela_start )
	DYNAMICENTRY( DT_RELASZ, dt_rela_end - dt_rela_start )
	DYNAMICENTRY( DT_RELAENT, 24 );  // ???

	DYNAMICENTRY( DT_FLAGS, 8 /* Bind now */ );

	//DYNAMICENTRY( DT_PLTGOT, got_table_start - elf_header );
dynamic_end:

symtab_start:
	.Elf64_Addr 0
	.Elf64_Addr 0
	.Elf64_Addr 0
symtab_end:

string_table:
str_dynamic:	.ascii ".dynamic\0"
str_shstrtab:	.ascii ".shstrtab\0"
str_dynstr:     .ascii ".dynstr\0"
str_dynsym:     .ascii ".dynsym\0"
str_plt:        .ascii ".plt\0"
str_got:        .ascii ".got\0"
str_interp_title: .ascii ".interp\0"
str_interp:     .ascii "/lib64/ld-linux-x86-64.so.2\0"; str_interp_end:
string_table_end:

plt_table_start:
	.Elf64_Addr 0
	.Elf64_Addr 0
plt_table_end:

got_table_start:
	.Elf64_Xword dynamic_section
	.Elf64_Xword 0
	.Elf64_Xword 0
	.Elf64_Xword 0 //plt_table_start-elf_header+0x10 //???? 16 bytes into the PLT? (TODO remove me)
	.Elf64_Xword 0
	.Elf64_Xword 0
	.Elf64_Xword 0
	.Elf64_Xword 0
	.Elf64_Xword 0
got_table_end:

dt_rela_start:
	.Elf64_Xword 0 // Start location?
	.Elf64_Xword 0 // Number of entries?
	//.Elf64_Xword 0 // ???
	// I think this is important?
dt_rela_end:

dynstr_start:
str_libX11:       .ascii "libX11.so.6\0"
str_XOpenDisplay: .ascii "XOpenDisplay\0"
dynstr_end:

#define DYNSYM( str, typebind, visibility, Ndx, Value, Size ) \
	.int str-dynstr_start;\
	.byte typebind;\
	.byte visibility;\
	.short Ndx;\
	.quad Value;\
	.quad Size;

dynsym_start:
	DYNSYM( str_XOpenDisplay, 0x12, 0x00, 0, 0, 0 );
dynsym_end:



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

