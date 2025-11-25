.data
	S: .space 100
	C: .space 4

	msg1: .asciz "Enter string S: "
	msg2: .asciz "Enter character C: "
	msg3: .asciz "Occurrence count: "

.text
	# prompt and read string S
	li a7, 4
	la a0, msg1
	ecall
	li a7, 8
	la a0, S
	li a1, 100
	ecall

	# prompt and read character C
	li a7, 4
	la a0, msg2
	ecall
	li a7, 8
	la a0, C
	li a1, 4
	ecall

	# print result message
	li a7, 4
	la a0, msg3
	ecall

	# initialize registers
	la t0, S
	la t3, C
	lb t1, 0(t3) #t1 holds the character we are searching for
	li t6, 0 # t6 will be our counter, initialized to 0

	# character bounds for case conversion
	li t4, 'A'
	li t5, 'Z'


normalize_search_char:
	blt t1, t4, search_loop  # if char < 'A', it's not uppercase, so skip
	bgt t1, t5, search_loop  # if char > 'Z', it's not uppercase, so skip

	addi t1, t1, 32          # if uppercase, so convert to lowercase


search_loop:
	lb t2, 0(t0)   
	beq t2, zero, res

	add t3, t2, zero	  # copy t2 to t3
	blt t2, t4, search       # if char < 'A', not uppercase, skip conversion
	bgt t2, t5, search       # if char > 'Z', not uppercase, skip conversion
	addi t3, t3, 32		#if uppercase, convert to lowercase

search:

	bne t1, t3, next_char     # if they don't match, move to the next char

	# if they match, increment the counter
	addi t6, t6, 1

next_char:
	addi t0, t0, 1            # move pointer to the next character in the string
	j search_loop             # jump back to the top of the loop


res:
	li a7, 1
	add a0, t6, zero  
	ecall
	
	li a7, 10
	ecall
