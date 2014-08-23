.skip 800 /* prevent collision */

.global DEL_LOAD
/*
  Start of full program deletion, modifies 0x0 (reset) and replaces it with code
  to jump to the next stage of deletion. After doing so, it attempts to delete
  the stack, and then proceeds to DEL_LOAD_2 
*/
DEL_LOAD:
/* *DEL_START = jmpi DEL_LOAD_2 */
movia r2, DEL_START
ldw r3, 0(r2)
stw r3, 0(r0)
/* *0x0 = *DEL_START => *0x0 = jmpi DEL_LOAD_2 */

/* flush instruction cache and pipeline */
flushi r0
flushp

/* store the same at the interrupt handler */
stw r3, 0x20(r0)
call DEL_STACK

/* Second level of deletion, moves DEL_PROG into 0x20 */
DEL_LOAD_2:
movia r2, DEL_PROG
movia r3, DEL_PROG_END
movia r4, 0x20

/* r2 = DEL_PROG + OFFSET, r3 = DEL_PROG_END, r4 = 0x20 + OFFSET */
DEL_LOAD_2_LOOP:
ldw r5, 0(r2)
stw r5, 0(r4)
addi r2, r2, 4
addi r4, r4, 4
/* OFFSET += 4, r2 = DEL_PROG + OFFSET, r3 = DEL_PROG_END, r4 = 0x20 + OFFSET */
bne r2, r3, DEL_LOAD_2_LOOP /* while DEL_PROG + OFFSET != DEL_PROG_END */

/* not worth writing the loop proper (and this is fastest anyways) */
stw r0, 0x4(r0)
stw r0, 0x8(r0)
stw r0, 0xC(r0)
stw r0, 0x10(r0)
stw r0, 0x14(r0)
stw r0, 0x18(r0)
stw r0, 0x1C(r0)

/* New deletion program copied into 0x20, now change start point of program */
movia r2, DEL_START_2
ldw r2, 0(r2)
stw r2, 0(r0)
flushi r0
flushp
/* *0x0 = DEL_START_2 = jmpi 0x20 && *0x20 = DEL_PROG */

movia r4, delfrom /* Initialize deletion loop */
br DEL_PROG /* Delete everything */

/* Deletes the stack */
DEL_STACK:
movia r2, stack_start
addi r2, r2, 4

DEL_STACK_LOOP:
stw r0, 0(sp)
addi sp, sp, 4
bne sp, r2, DEL_STACK_LOOP
ret

/* DEL_START and DEL_START_2 are instructions to be put at 0x0 */
DEL_START: jmpi DEL_LOAD_2
DEL_START_2: jmpi 0x20



DEL_PROG: /* placed in the exception handler, repeatedly runs */

movia r2, SSEG_address
movia r3, 0xBFB987F1 /* D.C.T.F. = Don't Copy That Floppy */
stwio r3, 0(r2)

/*
  loop to delete the program from delfrom to DEL_PROG_END (and a little bit
  further), r4 must be at delfrom before DEL_PROG runs (which will 99.9% of the
  time be the case). One can also movia r4, delfrom beforehand. This has the
  benefit of deleting everything after "stw r0, 0(r4)" instead of only deleting
  "br DEL_PROGRAM_LOOP", leaving only the program to display our message and a
  single mysterious final instruction.
*/

DEL_PROGRAM_LOOP:
stw r0, 0(r4) /* delete what's at r4 */
subi r4, r4, 4 /* move r4 back by one word */
flushi r4 /* and flush */
flushp
br DEL_PROGRAM_LOOP

DEL_PROG_END:

.equ delfrom, 0x1000
.equ stack_start, 0x007FFFFC
.equ SSEG_address, 0x10000020
