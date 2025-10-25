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
	Elf64_Phdr( PT_LOAD,    PF_X | PF_R | PF_W, 0,           init_start,      0,                     _binary_end, _binary_end, 0 );
	Elf64_Phdr( PT_DYNAMIC, PF_W | PF_R, PHYS(dynamic_section), dynamic_section, PHYS(dynamic_section), dynamic_end-dynamic_section, dynamic_end-dynamic_section, 8 );
	Elf64_Phdr( PT_INTERP,  PF_R,        PHYS(str_interp), str_interp, PHYS(str_interp), str_interp_end-str_interp, str_interp_end-str_interp, 1 );
elf_pgm_hdr_end:

elf_section_headers:
	Elf64_Shdr( STRLK(str_dynamic),  SHT_DYNAMIC, SHF_ALLOC|SHF_WRITE,
		(dynamic_section), dynamic_section-elf_header, dynamic_end-dynamic_section,   0x02 /* Point to .dynstr */, 0, 8, 0x10 )

	Elf64_Shdr( STRLK(str_shstrtab), SHT_STRTAB,  0,
		(string_table), string_table-elf_header,    string_table_end-string_table, 0, 0, 1, 0x00 )

	Elf64_Shdr( STRLK(str_dynstr),   SHT_STRTAB,  0,
		(dynstr_start), dynstr_start-elf_header,    dynstr_end-dynstr_start,       0, 0, 8, 0x00 )

	Elf64_Shdr( STRLK(str_rela_dyn),   SHT_RELA,  SHF_ALLOC,
		(rela_dyn_start), rela_dyn_start-elf_header, rela_dyn_end-rela_dyn_start,  0x07 /* Point to .dynsym */, 0, 8, 0x18 )

	Elf64_Shdr( STRLK(str_plt),      SHT_PROGBITS,  SHF_ALLOC|SHF_EXECINSTR,
		(plt_table_start), plt_table_start-elf_header, plt_table_end-plt_table_start, 0x00, 0, 0x10, 0x10 )

	Elf64_Shdr( STRLK(str_got),      SHT_PROGBITS,  SHF_ALLOC|SHF_WRITE,
		(got_table_start), got_table_start-elf_header, got_table_end-got_table_start, 0x00, 0, 0x08, 0x08 )

	Elf64_Shdr( STRLK(str_got_plt),  SHT_PROGBITS,  SHF_ALLOC,
		(gotplt_table_start), gotplt_table_start-elf_header, gotplt_table_end-gotplt_table_start, 0x00, 0, 0x08, 0x08 )

sh_dynsym_def:
	Elf64_Shdr( STRLK(str_dynsym),   SHT_DYNSYM,  0,
		(dynsym_start), dynsym_start-elf_header,    dynsym_end-dynsym_start,   0x02 /* Point to .dynstr */, (dynsym_end-dynsym_start)/0x18, 8, 0x18 )

	Elf64_Shdr( STRLK(str_interp_title), SHT_PROGBITS,  0,
		(str_interp), str_interp-elf_header, str_interp_end-str_interp, 0, 0, 0x01, 0x00 ) 	// for nix
elf_section_headers_end:

#define DYNAMICENTRY( type, addr ) \
	.quad type;\
	.quad addr;\

dynamic_section:
	DYNAMICENTRY( DT_NEEDED, str_libX11 - dynstr_start );
	DYNAMICENTRY( DT_STRTAB, dynstr_start );
	DYNAMICENTRY( DT_SYMTAB, symtab_start );
	DYNAMICENTRY( DT_STRSZ, dynstr_end-dynstr_start );

	DYNAMICENTRY( DT_RELA, rela_dyn_start )
	DYNAMICENTRY( DT_RELASZ, rela_dyn_end - rela_dyn_start )
	DYNAMICENTRY( DT_RELAENT, 24 ); // Size of each relaent.

	DYNAMICENTRY( DT_FLAGS, 8 /* Bind now */ );

	//DYNAMICENTRY( DT_PLTGOT, gotplt_table_start - elf_header );
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
str_got_plt:    .ascii ".plt.got\0"
str_rela_dyn:   .ascii ".rela.dyn\0"
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
//	.Elf64_Xword dynamic_section //dynamic_section (Originally)
//	.Elf64_Xword gotplt_table_start //plt_table_start-elf_header+0x10 //???? 16 bytes into the PLT? (TODO remove me)
//	.Elf64_Xword dynamic_section //dynamic_section (Originally)
//	.Elf64_Xword plt_table_start //plt_table_start-elf_header+0x10 //???? 16 bytes into the PLT? (TODO remove me)
//	.Elf64_Xword plt_table_start // Address
//	.Elf64_Xword 0x000100000006 // Info
//	.Elf64_Xword gotplt_table_start //????
//	.Elf64_Xword dynamic_section
	.Elf64_Xword 0
//	.Elf64_Xword str_XOpenDisplay
//	.Elf64_Xword 0

got_table_end:


rela_dyn_start:  // Also DT_RELA
	.Elf64_Xword got_table_start // Address  (Should this be plt_table_start or got_table_Start)?
	.Elf64_Xword 0x000100000006 // Info
	.Elf64_Xword 0 //gotplt_table_start //????

rela_dyn_end:

dynstr_start:
dynstr_empty:     .ascii "\0"
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
	// Dunno why - need a empty entry first
	DYNSYM( dynstr_empty, 0x00, 0x00, 0, 0, 0 );
	DYNSYM( str_XOpenDisplay, 0x12, 0x00, 0, 0, 0 );
dynsym_end:

gotplt_table_start:
	.byte 0xf3, 0x0f, 0x1e, 0xfa, 0xe9, 0x77, 0xff, 0xff
	.byte 0x00, 0x00, 0x66, 0x0f, 0x1f, 0x44, 0x00, 0x00
gotplt_table_end:



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

