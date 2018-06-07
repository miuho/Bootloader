/**
 * @file  debug.h
 * @brief Simics debugging macros.
 *
 * Each debug macro may be called from assembly.  They do not trounce on
 * any registers, so none need to be saved before caling them.  However,
 * each macro does require a valid stack.
 *
 * If you wish to debug a portion of code where you do not have a valid
 * stack, crop out the relevant lines of assembly and insert them directly.
 * This will, however, trounce on registers.
 *
 * @author Mike Kasick <mkasick@andrew.cmu.edu>
 */

#ifndef DEBUG_H
#define DEBUG_H

/* Enable 15-410 Simics logging (i.e., declare BIOS is done).
 *
 * sim_booted() expects a string argument, but there is no name
 * for the file that contains this code with gdb symbols, so we
 * will claim our "kernel name" string is "[NO]".
 */
#define BOOTED \
	pushl	%ebx; \
	pushl	%ecx; \
	movl	$0x04100008, %ebx; \
	pushl	$0; \
	pushl	$0x5D4F4E5B; \
	movl	%esp, %ecx; \
	xchgl	%ebx, %ebx; \
	addl	$8,%esp; \
	popl	%ecx; \
	popl	%ebx

/* Break simulation. */
#define MAGIC_BREAK \
	pushl	%ebx; \
	movl	$0x04100003, %ebx; \
	xchgl	%ebx, %ebx; \
	popl	%ebx

/* Print a null-terminated string to the Simics console. */
#define LPUTS(s) \
	pushl	%ebx; \
	pushl	%ecx; \
	movl	$0x04100002, %ebx; \
	movl	$(s), %ecx; \
	xchgl	%ebx, %ebx; \
	popl	%ecx; \
	popl	%ebx

/* Print n bytes of a string to the Simics console. */
#define LPUTSN(s, n) \
	pushl	%ebx; \
	pushl	%ecx; \
	pushl	%edx; \
	movl	$0x0410800B, %ebx; \
	movl	$(s), %ecx; \
	movl	$(n), %edx; \
	xchgl	%ebx, %ebx; \
	popl	%edx; \
	popl	%ecx; \
	popl	%ebx

/* Print the 32-bit long in hexadecimal to the Simics console. */
#define LPUTX(x) \
	pushl	%ebx; \
	pushl	%ecx; \
	movl	$0x0410800C, %ebx; \
	movl	$(x), %ecx; \
	xchgl	%ebx, %ebx; \
	popl	%ecx; \
	popl	%ebx

#endif
