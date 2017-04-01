/********************************************************************************
 * This program demonstrates use of the JTAG UART port
 *
 * It performs the following: 
 *	1. sends a text string to the JTAG UART
 * 	2. reads character data from the JTAG UART
 * 	3. echos the character data back to the JTAG UART
********************************************************************************/

.include "address_map_nios2.s"

	.text							/* executable code follows */
	.global	_start
_start:
	/* set up stack pointer */
	movia 	sp, SDRAM_END - 3		/* starts from largest memory address */

	movia	r6, JTAG_UART_BASE		/* JTAG UART base address */

	/* print a text string */
	movia	r8, TEXT_STRING
	
	ori		r10, r0, 0x41	/* 0x41 = 65 */
	ori		r11, r0, 0x5A	/* 0x5A = 90 */
	ori		r12, r0, 0x61	/* 0x61 = 97 */
	ori		r13, r0, 0x7A	/* 0x7A = 122 */
	ori		r14, r0, 0x30	/* 0x30 = 48 */
	ori		r15, r0, 0x39	/* 0x39 = 57 */
	ori		r17, r0, 0x9	/* 0x9 = 9 */
	
LOOP:
	ldb		r5, 0(r8)
	beq		r5, zero, GET_JTAG		/* string is null-terminated */
	call	PUT_JTAG
	addi	r8, r8, 1
	br		LOOP

	/* read and echo characters */
GET_JTAG:
	ldwio	r4, 0(r6)				/* read the JTAG UART data register */
	andi	r8, r4, 0x8000			/* check if there is new data */
	beq		r8, r0, GET_JTAG		/* if no data, wait */
	andi	r5, r4, 0x00ff			/* the data is in the least significant byte */
	
	call 		SHIFT
	call		PUT_JTAG			/* echo character */
	br			GET_JTAG

	
SHIFT:
	blt		r5, r10, ELSE			/* is char less than 65 */
	bgt		r5, r11, ELSE			/* is char greater than 90 */
	beq		r5, r11, UP				/* does char = 90 */
	addi	r5, r5, 1
	ret
	
UP:
	subi r5, r5, 25
	
	call		PUT_JTAG			/* echo character */
	br			GET_JTAG
	
ELSE:
	blt		r5, r12, ELSEIF			/* is char less than 97 */
	bgt		r5, r13, ELSEIF			/* is char greater than 122 */
	beq		r5, r13, UP				/* does char = 122 */
	addi	r5, r5, 1
	
	call		PUT_JTAG			/* echo character */
	br			GET_JTAG
	
ELSEIF:
	blt		r5, r14, LAST			/* is char less than 48 */
	bgt		r5, r15, LAST			/* is char greater than 57 */
	subi	r16, r5, 48				
	muli	r16, r16, 2
	sub		r16, r17, r16
	add		r5, r5, r16
	
	call		PUT_JTAG			/* echo character */
	br			GET_JTAG
	
LAST:
	call		PUT_JTAG			/* echo character */
	br			GET_JTAG
	
/********************************************************************************
 * Subroutine to send a character to the JTAG UART
 *		r5	= character to send
 *		r6	= JTAG UART base address
********************************************************************************/
	.global	PUT_JTAG
PUT_JTAG:
	/* save any modified registers */
	subi		sp, sp, 4			/* reserve space on the stack */
	stw		r4, 0(sp)				/* save register */

   ldwio		r4, 4(r6)			/* read the JTAG UART control register */
   andhi		r4, r4, 0xffff		/* check for write space */
   beq		r4, r0, END_PUT			/* if no space, ignore the character */
   stwio		r5, 0(r6)			/* send the character */

END_PUT:
	/* restore registers */
	ldw		r4, 0(sp)
	addi		sp, sp, 4

	ret

/*******************************************************************************/
	.data			

TEXT_STRING:
	.asciz	"\nJTAG UART example code\n> "

	.end
