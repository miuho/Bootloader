# @file  boot0.S
# @brief Zeroth stage bootloader.
#
# FIXME: Write some documentation here.
#
# @author HingOn Miu (hmiu)
# @author An Wu (anwu)

#include "boot.h"

	.file	"boot0.S"
	.text

	.code16
	.global	_start
_start:
    MOVW    $one_str,           %BP
    MOVZBW  one_len,            %SI
    CALL    print_str
    HLT

print_str:
    PUSHA

    MOVB    $WRITE_STRING_AH,   %AH
    MOVB    $MOVE_CURSOR_AL,    %AL
    MOVB    $0x7,               %BL
    XORB    %BH,                %BH
    MOVW    %SI,                %CX
    MOVB    $0,                 %DH
    MOVB    $0,                 %DL
    INT     $VIDEO_INT

    POPA
    RET

one_str: .ascii "\r\nHello World.\r\n"
one_len: .byte  . - one_str

.org    0x1fe
.byte   0x55
.byte   0xaa
