# @file  boot1.S
# @brief First stage bootloader that loads the kernel.
#
#
# @author HingOn Miu (hmiu)
# @author An Wu (anwu)

#include "boot.h"
#include "inc.h"

	.file	"boot1.S"
	.text

	.code16
	.global	_start
_start:
    
    MOVW    $RM_STACK_TOP,          %SP             # Set stack pointer
    
    # Get mem_lower
    MOVW    $0,                     %AX
    MOVW    $0,                     %SI             # Pass "error code"
    INT     $LOW_MEM_SIZE_INT                       # Query size of lower mem
    JC      print
    
    MOVW    $1,                     %SI             # Pass "error code"
    CMP     $636,                   %AX             # Make sure we have at
                                                    # least 636K
    JL      print
    # Put mem_lower in memory
    MOVW    $mem_lower_addr,        %BX
    MOVW    %AX,                    (%BX)
    ADDW    $2,                     %BX
    MOVW    $0,                     (%BX)              

 
    # Get mem_upper
    MOVW    $EISA_MEM_SIZE_AX,      %AX   
    MOVW    $2,                     %SI             # Pass "error code"
    INT     $SYSTEM_INT                             # Query size of upper mem
    JC      print

    # Put mem_uppder in memory
    MOVW    %BX,                    %CX
    SHL     %BX
    SHL     %BX
    SHL     %BX
    SHL     %BX
    SHL     %BX
    SHL     %BX
    ADDW    %BX,                    %AX

    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX
    SHR     %CX

    MOVW    $mem_upper_addr,        %BX
    MOVW    %AX,                    (%BX)
    ADDW    $2,                     %BX
    MOVW    %CX,                    (%BX)    

    # Initialize CH (Cylinder number) and CL (Sector number)
    MOVB    $KERNEL_START_CYL,      %CH
    MOVB    $1,                     %CL

    # Use BP as ES value holder
    MOVW    $KERNEL_PRELOAD_ADDR_ES,%BP


    # In loop_cylinder, only use registers AX, BX, DX, SI for temp
loop_cylinder:
    # Check cylinder < KERNEL_START_CYL + KERNEL_CYLINDERS
    MOVB    $KERNEL_CYLINDERS,      %AH             # Record length
    ADDB    $KERNEL_START_CYL,      %AH             # Check if all cylinders
    CMP     %CH,                    %AH             # are loaded already
    JLE     loop_cylinder_done

    MOVB    $0,                     %DH
    MOVB    $0,                     %DL 

    # In loop_head, only use register AX, BX, or SI for temp
loop_head:
    # Check head (DH) < HEADS
    CMP     $HEADS,                 %DH
    JGE     loop_head_done

    # Set inputs
    MOVB    $READ_SECTORS_AH,       %AH             
    MOVB    $SECTORS_PER_TRACK,     %AL             # Read full cylinder
    MOVW    $DISK_BUFFER_ADDR,      %BX

    MOVW    $3,                     %SI             # Pass "error code"
    INT     $DISK_INT                               # Load head 0
    JC      print

    MOVW    $DISK_BUFFER_ADDR,      %SI
    MOVW    $0,                     %BX             # init kernel base
    MOVW    %BP,                    %ES             # load ES from BP

    # In loop_load_kernel, only use register AX, BX or SI for temp
    # Use BX as kernel address, SI as disk buffer address, AX as temp
loop_load_kernel:
    # Check BX (Kernel address pointer) < KERNEL_PRELOAD_ADDR + BYTES_PER_TRACK
    CMP     $BYTES_PER_TRACK,       %BX
    JGE     loop_load_kernel_done

    # Copy and paste data
    MOVW    (%SI),                  %AX
    MOVW    %AX,                    %ES:(%BX)

    # Increment pointers
    ADDW    $2,                     %SI
    ADDW    $2,                     %BX
    JMP     loop_load_kernel

loop_load_kernel_done:
    INC     %DH                                     # Increment head count
    MOVW    $0,                     %AX             # Restore ES
    MOVW    %AX,                    %ES 
    ADDW    $BYTES_PER_TRACK_ES,     %BP             # Increment ES value
    JMP     loop_head

loop_head_done:
    INC     %CH                                     # Increment cylinder index
    JMP     loop_cylinder

loop_cylinder_done:
    # Enable A20 Gate
    MOVB    $A20_GATE_AH,           %AH
    INT     $SYSTEM_INT                             # Enable A20 gate
    JNC     a20_enabled

# Reference: http://www.win.tue.nl/~aeb/linux/kbd/A20.html
a20_control_port_a:
    INB     $0x92,                  %AL                      
    TESTB   $02,                    %AL
    JNZ     a20_enabled
    ORB     $02,                    %AL             # "fast A20" version
    ANDB    $0xfe,                  %AL
    OUTB    %AL,                    $0x92           # some chips have only this

a20_enabled:
    # Make sure A20 is enabled
    INB     $0x92,                  %AL      
    MOVW    $4,                     %SI             # Pass "error code"
    TESTB   $02,                    %AL
    JZ      print
    
    MOVB    $0xc2,                  %AH
    MOVB    $DISABLE_AL,            %AL
    MOVB    $0,                     %BH
    MOVW    $5,                     %SI             # Pass "error code"
    INT     $SYSTEM_INT                             # Disable interrupts
    JC      print

    # Retrieve current row position to use later in protected mode
    MOVB    $READ_CURSOR_POS_AH,    %AH
    XORB    %BH,                    %BH             # Page 0.
    INT     $VIDEO_INT
    MOVW    $console_row_addr,      %BX
    MOVB    %DH,                    (%BX)
    ADDW    $1,                     %BX
    MOVB    $0,                     (%BX)
    ADDW    $1,                     %BX
    MOVW    $0,                     (%BX)

    # Set up GDT
    MOVW    $gdt_null_addr,         %BX

    # NULL Segment descriptor
    MOVW    $0,                     %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX
    MOVW    %AX,                    (%BX)


    # A 4 GB, 32-bit, DPL 0, “non-conforming” type, code segment descriptor
    MOVW    $gdt_code_addr,         %BX

    # 1st word
    # Segment limit 15:00 are all 1's
    MOVW    $SEGDES_W1_SET,         %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX

    # 2nd word
    # bug: decide base address 15:00
    MOVW    $0,                     %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX

    # 3rd word
    MOVW    $0,                     %AX
    # Set type
    ORW     $SEGDES_W3_TYPE_CODE,   %AX
    ORW     $SEGDES_W3_TYPE_CODE_RE,%AX
    # ORW     $SEGDES_W3_TYPE_CODE_AC,%AX
    # Set other flags
    ORW     $SEGDES_W3_S,           %AX
    ORW     $SEGDES_W3_P,           %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX
    
    # 4th word
    MOVW    $0,                     %AX
    ORW     $SEGDES_W4_SEGLIM_SET,  %AX
    ORW     $SEGDES_W4_DB,          %AX
    ORW     $SEGDES_W4_G,           %AX
    MOVW    %AX,                    (%BX)


    # A 4 GB, 32-bit, DPL 0, “expand-up” type, data segment descriptor
    MOVW    $gdt_data_addr,         %BX

    # Segment limit 15:00 are all 1's
    MOVW    $SEGDES_W1_SET,         %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX

    # 2nd word
    # bug: decide base address 15:00
    MOVW    $0,                     %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX

    # 3rd word
    MOVW    $0,                     %AX
    # Set type
    ORW     $SEGDES_W3_TYPE_DATA,   %AX
    ORW     $SEGDES_W3_TYPE_DATA_EU,%AX
    ORW     $SEGDES_W3_TYPE_DATA_WE,%AX
    ORW     $SEGDES_W3_TYPE_DATA_AC,%AX
    # Set other flags
    ORW     $SEGDES_W3_S,           %AX
    ORW     $SEGDES_W3_P,           %AX
    MOVW    %AX,                    (%BX)
    ADD     $2,                     %BX
    
    # 4th word
    MOVW    $0,                     %AX
    ORW     $SEGDES_W4_SEGLIM_SET,  %AX
    ORW     $SEGDES_W4_DB,          %AX
    ORW     $SEGDES_W4_G,           %AX
    MOVW    %AX,                    (%BX)
    ADDW    $2,                     %BX

    # Load GDTR
    MOVW    $gdtr_addr,             %BX
    # Load GDT Limit
    MOVW    $24,                    %AX
    MOVW    %AX,                    (%BX)
    # Load GDT Base Addr
    ADDW    $2,                     %BX
    MOVW    $gdt_null_addr,         (%BX)
    ADDW    $2,                     %BX
    MOVW    $0,                     (%BX)

    LGDT    gdtr_addr

    # Switch to protection mode
    # set cr0
    MOVL    %CR0,                   %EAX
    ORL     $CR0_PROTECTION_ENABLE, %EAX
    MOVL    %EAX,                   %CR0

    # long jump to code segment
    LJMP    $0x8,                   $protection_enabled

protection_enabled:
        .code32
    MOVL    $0x10,                  %EAX
    MOVL    %EAX,                   %DS
    MOVL    %EAX,                   %ES
    MOVL    %EAX,                   %FS
    MOVL    %EAX,                   %GS
    MOVL    %EAX,                   %SS

    MOVL    $PM_STACK_TOP,          %ESP

    # find and parse multiboot header
    PUSHL   mem_upper_addr
    PUSHL   mem_lower_addr
    PUSHL   $mb_info_addr
    CALL    invoke_multiboot

    # Check return value
    CMP     $0,                     %EAX
    JZ      multiboot_fail

    # Start the kernel
    MOVL    %EAX,                   %ECX
    MOVL    $0x2BADB002,            %EAX
    MOVL    $mb_info_addr,          %EBX
    JMP     %ECX

multiboot_fail:
    CLI
    PUSHL   $0                                      # Use 0 as column
    PUSHL   console_row_addr                        # Previously saved row
    CALL    multiboot_panic

    JMP     halt32

halt32:
    HLT
    JMP halt32

        .code16
# If fail, print the failure message and then halt
print:
    # Restore registers first
    MOVW    $0,                 %AX
    MOVW    %AX,                %DS                 # Load %DS
    MOVW    %AX,                %FS                 # Load %FS
    MOVW    %AX,                %GS                 # Load %GS
    MOVW    %AX,                %SS                 # Load %SS
    MOVW    %AX,                %ES                 # Load %ES
    
    MOVW    $RM_STACK_TOP,      %SP                 # Set stack pointer

    CMP     $0,                 %SI
    JZ      low_fail_print
    CMP     $1,                 %SI
    JZ      small_low_fail_print   
    CMP     $2,                 %SI
    JZ      up_fail_print   
    CMP     $3,                 %SI
    JZ      disk_read_fail_print   
    CMP     $4,                 %SI
    JZ      a20_fail_print
    CMP     $5,                 %SI
    JZ      disable_fail_print   
    CMP     $6,                 %SI
    JZ      disable_fail_print   
    CMP     $10,                 %SI
    JZ      success_print      
    
    JMP     fail_handle

low_fail_print:
    MOVW    $low_fail_str,  %BP
    MOVZBW  low_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


small_low_fail_print:
    MOVW    $small_low_fail_str,  %BP
    MOVZBW  small_low_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


up_fail_print:
    MOVW    $up_fail_str,  %BP
    MOVZBW  up_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


disk_read_fail_print:
    MOVW    $disk_read_fail_str,  %BP
    MOVZBW  disk_read_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


a20_fail_print:
    MOVW    $a20_fail_str,  %BP
    MOVZBW  a20_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle


disable_fail_print:
    MOVW    $disable_fail_str,  %BP
    MOVZBW  disable_fail_len,   %SI
    CALL    print_str
    JMP     fail_handle

success_print:
    MOVW    $success_str,  %BP
    MOVZBW  success_len,   %SI
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
    MOVB    $READ_CURSOR_POS_AH,    %AH
    XORB    %BH, %BH                                # Page 0.
    INT     $VIDEO_INT      # Clobbers %cx & %dx (cursor type & pos).

    # Write %si characters of the string pointed to by %bp.
    MOVB    $WRITE_STRING_AH,   %AH
    MOVB    $MOVE_CURSOR_AL,    %AL
    MOVB    $LGRAY_ATTRIB,      %BL
    XORB    %BH, %BH        # Page 0.
    MOVW    %SI, %CX        # Character count.
    INT     $VIDEO_INT      # %dx: String location, %es:%bp: String ptr.

    POPA
    RET


halt:
    HLT
    JMP halt

# Fail info
low_fail_str: .ascii "\r\nQuery lower memory failed.\r\n"
low_fail_len: .byte . - low_fail_str

small_low_fail_str: .ascii "\r\nLower memory region too small.\r\n"
small_low_fail_len: .byte . - small_low_fail_str

up_fail_str: .ascii "\r\nQuery upper memory failed.\r\n"
up_fail_len: .byte . - up_fail_str

disk_read_fail_str: .ascii "\r\nRead from floppy disk failed.\r\n"
disk_read_fail_len: .byte . - disk_read_fail_str

a20_fail_str: .ascii "\r\nEnable A20 gate failed.\r\n"
a20_fail_len: .byte . - a20_fail_str

disable_fail_str: .ascii "\r\nDisable interrupts failed.\r\n"
disable_fail_len: .byte . - disable_fail_str

success_str: .ascii "\r\nSuccess!\r\n"
success_len: .byte . - success_str

# current console role
        .align 4
console_row_addr:
        .space 4


# memory to store mem_lower and mem_upper
        .align 4
mem_lower_addr:
        .space 4

mem_upper_addr:
        .space 4


# gdt should be 8 byte aligned
        .align 8
gdt_null_addr:
        .space 8
gdt_code_addr:
        .space 8
gdt_data_addr:
        .space 8

# put gdtr after gdt
gdtr_addr:
        .space 24


# multiboot_info struct addr
        .align 4
mb_info_addr:
