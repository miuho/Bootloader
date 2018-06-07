# @file  boot0.S
# @brief Zeroth stage bootloader that loads the first stage
#        bootloader.
#
#
# @author HingOn Miu (hmiu)
# @author An Wu (anwu)

#include "boot.h"

	.file	"boot0.S"
	.text

	.code16
	.global	_start
_start:
    MOVB    $0xc2,              %AH                 
    MOVB    $DISABLE_AL,        %AL
    MOVB    $0,                 %BH
    MOVW    $0,                 %SI                 # Pass "error code"
    INT     $SYSTEM_INT                             # Disable interrupts
    JC      fail_print

    LJMP    $0,                 $next_line          # Canonicalize %CS:%EIP


next_line:
    MOVW    $0,                 %AX
    MOVW    %AX,                %DS                 # Load %DS
    MOVW    %AX,                %FS                 # Load %FS
    MOVW    %AX,                %GS                 # Load %GS
    MOVW    %AX,                %SS                 # Load %SS
    MOVW    %AX,                %ES                 # Load %ES
    
    MOVW    $RM_STACK_TOP,      %SP                 # Set stack pointer
   
    MOVB    $0xc2,              %AH
    MOVB    $ENABLE_AL,         %AL
    MOVW    $1,                 %SI                 # Pass "error code"
    INT     $SYSTEM_INT                             # Enable interrupts
    JC      fail_print
    
    MOVB    $RESET_DISK_SYS_AH, %AH
    MOVW    $2,                 %SI                 # Pass "error code"
    INT     $DISK_INT                               # Reset disk controller
    JC      fail_print
    
    MOVB    $READ_SECTORS_AH,   %AH
    MOVB    $BOOT1_SECTORS,     %AL
    MOVB    $0,                 %CH
    MOVB    $BOOT1_START_SEC,   %CL
    MOVB    $0,                 %DH
    MOVB    $0,                 %DL
    MOVW    $BOOT1_START_ADDR,  %BX
    MOVW    $3,                 %SI                 # Pass "error code"
    INT     $DISK_INT                               # Read boot1 from floppy
    JC      fail_print
    
    JMP     BOOT1_START_ADDR                        # Jumps to boot1 code   


fail_print:
    # Restore registers first
    MOVW    $0,                 %AX
    MOVW    %AX,                %DS                 # Load %DS
    MOVW    %AX,                %FS                 # Load %FS
    MOVW    %AX,                %GS                 # Load %GS
    MOVW    %AX,                %SS                 # Load %SS
    MOVW    %AX,                %ES                 # Load %ES
    
    MOVW    $RM_STACK_TOP,      %SP                 # Set stack pointer

    CMP     $0,                 %SI
    JZ      disable_fail_print
    CMP     $1,                 %SI
    JZ      enable_fail_print   
    CMP     $2,                 %SI
    JZ      disk_init_fail_print   
    CMP     $3,                 %SI
    JZ      disk_read_fail_print   
    JMP     fail_handle
    

disable_fail_print:
    MOVW    $disable_fail_str,  %BP
    MOVZBW  disable_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


enable_fail_print:
    MOVW    $enable_fail_str,  %BP
    MOVZBW  enable_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


disk_init_fail_print:
    MOVW    $disk_init_fail_str,  %BP
    MOVZBW  disk_init_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


disk_read_fail_print:
    MOVW    $disk_read_fail_str,  %BP
    MOVZBW  disk_read_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


fail_handle:
    MOVB    $0xc2,              %AH
    MOVB    $DISABLE_AL,        %AL
    MOVB    $0,                 %BH
    INT     $SYSTEM_INT                             # Disable interrupts
    JMP     halt                                    # Suspend execution


print_str:
    PUSHA                   # Saves only the lower 16 bits of registers.

    # Get the current cursor position.
    MOVB    $READ_CURSOR_POS_AH,%AH
    XORB    %bh,                %BH        # Page 0.
    INT     $VIDEO_INT      # Clobbers %cx & %dx (cursor type & pos).

    # Write %si characters of the string pointed to by %bp.
    MOVB    $WRITE_STRING_AH,   %AH
    MOVB    $MOVE_CURSOR_AL,    %AL
    MOVB    $LGRAY_ATTRIB,      %BL
    XORB    %bh,                %BH        # Page 0.
    MOVW    %si,                %CX        # Character count.
    INT     $VIDEO_INT          # %dx: String location, %es:%bp: String ptr.

    POPA
    RET


halt:
    HLT
    JMP halt


disable_fail_str: .ascii "\r\nDisable interrupts failed.\r\n"
disable_fail_len: .byte . - disable_fail_str

enable_fail_str: .ascii "\r\nEnable interrupts failed.\r\n"
enable_fail_len: .byte . - enable_fail_str

disk_init_fail_str: .ascii "\r\nInit floppy disk controller failed.\r\n"
disk_init_fail_len: .byte . - disk_init_fail_str

disk_read_fail_str: .ascii "\r\nRead from floppy disk failed.\r\n"
disk_read_fail_len: .byte . - disk_read_fail_str

    .org    0x1fe
    .byte   0x55
    .byte   0xaa
