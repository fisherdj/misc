.text
.global _start
_start:
	movia sp, STACK_START
main_loop:
	call fib_result
	movia r8, SSEG_address
	stwio r2, 0(r8)
	br main_loop

fib_result: /* get next result of fib calculation */
	subi sp, sp, 4
	stw ra, 0(sp)

/* Some comments added about state to explain things a little bit.
   It's easier to write a less arcane version of this, but this way is more interesting */

/* Has the result we'll be returning, we'll move it into r2 early */
next_result: /* we're replacing the immediate value for the instruction at this label */
	movui r2, 1 /* r2 will contain the next result to be returned */

	movia r4, next_result
prev_result: /* as well as this label */
	addi r5, r2, 0 /* r5 = next_result + prev_result */
	/* replace next_result (*r4) with next returned result and the previous returned
	   result (r5) */
	call replaceImmed

	movia r4, prev_result
	mov r5, r2

/*
	tail-call replaceImmed to replace prev_result (*r4) with previous value
	of next_result (r5), equivalent to:

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
*/

	ldw ra, 0(sp)
	addi sp, sp, 4
	/* jmpi replaceImmed */ /* un-needed, replaceImmed follows this function immediately */

/* r4 is the instruction location to replace, and r5 is the new immediate value of interest,
   r2 is left preserved */
/* note also that this code will vary based on which specific architecture is being used */
replaceImmed:
	/* get instruction from r4 */
	ldw r8, 0(r4)

	/* Mask out immediate value */
	andhi r9, r8, %hi(IUNMASK)
	andi r8, r8, %lo(IUNMASK)
	or r8, r8, r9

	/* Get mask from new immediate value */
	andi r9, r5, 0xFFFF
	slli r9, r9, ISHIFT

	/* or it in, store result and return */
	or r8, r8, r9
	stw r8, 0(r4)
	ret

.equ IMASK, 0x003FFFC0
.equ IUNMASK, 0xFFC0003F
.equ ISHIFT, 6 /* amount to shift immediates left to align them in an I-type instruction */
.equ SSEG_address, 0x10000020
.equ STACK_START, 0x007FFFFC

.data
COUNT: .skip (4*0xFFFF)
