.data
A: .asciz "Enter side A: "
B: .asciz "Enter side B: "
C: .asciz "Enter side C: "
isTriangle: .asciz "A, B, C form a triangle\n"
isNotTriangle: .asciz "A, B, C don't form a triangle.\n"
isRight: .asciz "It's a right triangle.\n"
isNotRight: .asciz "It's not a right triangle.\n"
errorMsg: .asciz "Not a number. Try again: "
buffer: .space 20

.text
main:
	# prompt and read integer A
	li a7, 4
	la a0, A
	ecall
	
	jal ra, check
	mv s0, a0 # s0 = A

	# prompt and read integer B
	li a7, 4
	la a0, B
	ecall

	jal ra, check
	mv s1, a0 # s1 = B

	# prompt and read integer C
	li a7, 4
	la a0, C
	ecall
	
	jal ra, check
	mv s2, a0 # s2 = C

	# check triangle inequality: A + B > C, A + C > B, B + C > A
	add t0, s0, s1	 # t0 = A + B
	ble t0, s2, not_a_triangle  # if A + B <= C, not a triangle

	add t0, s0, s2	 # t0 = A + C
	ble t0, s1, not_a_triangle  # if A + C <= B, not a triangle

	add t0, s1, s2	 # t0 = B + C
	ble t0, s0, not_a_triangle  # if B + C <= A, not a triangle

	# if all checks pass, it is a triangle
	li a7, 4
	la a0, isTriangle
	ecall

	# Check for a right triangle
	mul s3, s0, s0	 # s3 = A*A
	mul s4, s1, s1	 # s4 = B*B
	mul s5, s2, s2	 # s5 = C*C

	add t0, s3, s4	 # t0 = A*A + B*B
	beq t0, s5, is_a_right_triangle # if A*A + B*B = C*C

	add t0, s3, s5	 # t0 = A*A + C*C
	beq t0, s4, is_a_right_triangle # if A*A + C*C = B*B

	add t0, s4, s5	 # t0 = B*B + C*C
	beq t0, s3, is_a_right_triangle # if B*B + C*C = A*A

	# if none of the right triangle conditions are met
	li a7, 4
	la a0, isNotRight
	ecall
	j exit

is_a_right_triangle:
	li a7, 4
	la a0, isRight
	ecall
	j exit

not_a_triangle:
	li a7, 4
	la a0, isNotTriangle
	ecall

exit:
	li a7, 10
	ecall

check:
	# read string into buffer
	li a7, 8
	la a0, buffer
	li a1, 20
	ecall

	la t1, buffer # t1 = Pointer to current char
	li t2, 0 # t2 = result
	li t3, 0 # t3 = sign flag (0 = pos, 1 = neg)
	
	lb t4, 0(t1) # load first byte
	
	# check for negative sign
	li t5, 45		   # t5 = '-'
	bne t4, t5, parse_loop
	li t3, 1			# set sign flag to negative
	addi t1, t1, 1	  # move pointer forward
	lb t4, 0(t1)		# load next char

parse_loop:
	# check for end of string (newline or null)
	li t5, 10 # t5 = '\n'
	beq t4, t5, end_parse
	beqz t4, end_parse  # Null terminator
	
	# digit must be from '0' to '9'
	li t5, 48
	blt t4, t5, invalid_input
	li t5, 57
	bgt t4, t5, invalid_input

	# convert string to integer
	# result = (result * 10) + (char - 48)
	addi t4, t4, -48	# convert char to integer digit
	li t5, 10
	mul t2, t2, t5	  # shift current result left (decimal)
	add t2, t2, t4	  # add new digit
	
	# move to next char
	addi t1, t1, 1
	lb t4, 0(t1)
	j parse_loop

invalid_input:
	# print error message
	li a7, 4
	la a0, errorMsg
	ecall
	# jump back to start of check to read again
	j check

end_parse:
	# apply negative sign if needed
	beqz t3, return_result
	sub t2, zero, t2	# result = 0 - result

return_result:
	mv a0, t2		   # move result to a0 for return
	ret
