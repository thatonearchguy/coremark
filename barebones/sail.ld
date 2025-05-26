OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)

ENTRY(_start)

SECTIONS
{
	. = 0x00;
	.text . :
	{
		_text = . ;
		*(.text .text.*)
		. = 0x2000;
		*(.strings)
		_etext = . ;
	}

	.data . :
	{
		*(.data .data.*)
		*(.sdata .sdata.*)
		*(.rodata .rodata.* .srodata .srodata.*)
	}

	.bss . :
	{
		*(.bss .bss.*)
		*(.sbss .sbss.*)
	}

	/* ========== DISCARD UNNECESSARY SECTIONS ========== */
    /DISCARD/ : {
        *(.comment)         /* Debug comments */
        *(.debug*)          /* Debug symbols */
    }
}
