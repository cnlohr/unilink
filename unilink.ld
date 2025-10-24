ENTRY( _start )

MEMORY
{
	BINARY (rx) : ORIGIN = 0x00000000, LENGTH = 64M
	EXECRO (rx) : ORIGIN = 0x08000000, LENGTH = 1M
	RAM (xrw)	: ORIGIN = 0x20000000, LENGTH = 2K
}

# TODO
# .note.GNU-stack

SECTIONS
{
	.eroa :
	{
		. = ALIGN(4);
		PROVIDE(_text_vma = .);
	} > EXECRO AT>EXECRO

	.init :
	{ 
		_sinit = .;
		. = ALIGN(4);
		KEEP(*(SORT_NONE(.init)));
		*(.init*)
		. = ALIGN(4);
		_einit = .;
	} >EXECRO AT>BINARY

	.text :
	{
		. = ALIGN(4);
		*(.text*)
		*(.start)
		*(.rodata)
		*(.rodata*)
		*(.gnu.linkonce.t.*)
		. = ALIGN(4);
	} >EXECRO AT>BINARY

	.dlalign :
	{
		. = ALIGN(4); 
		PROVIDE(_data_lma = .);
	} >BINARY AT>BINARY

	.dalign :
	{
		. = ALIGN(4);
		PROVIDE(_data_vma = .);
	} >RAM AT>BINARY  

	.data :
	{
		. = ALIGN(4);
		*(.data)
		*(.data.*)
		. = ALIGN(4);
		PROVIDE(_edata = .);
	} >RAM AT>BINARY

	.binary_end :
	{
		. = ALIGN(4); 
		PROVIDE(_binary_end = .);
	} >BINARY AT>BINARY

	.bss :
	{
		. = ALIGN(4);
		PROVIDE( _sbss = .);
		*(.bss*)
		. = ALIGN(4);
		PROVIDE( _ebss = .);
	} >RAM AT>RAM
}

