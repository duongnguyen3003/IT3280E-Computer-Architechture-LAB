.data
	msg1: .asciz "Input N: "
	msg2: .asciz "Output: "
	msg_error: .asciz "Error (requires at least 2 elements)\n"
	endl: .asciz "\n"
	space: .asciz " "
	msg_error2: .asciz "Not a number. Try again: "
	buffer:  .space 32   # Buffer to store input text

.text
# Registers:
# t0 = number of elements
# t1 = largest product found so far
# t2 = first element of the pair with the largest product
# t3 = second element of the pair with the largest product
# t4 = previous element read
# t5 = current element read
# t6 = loop counter

main:
	# prompt and read for the number of elements
	li a7, 4
	la a0, msg1
	ecall
	
	jal ra, check
	mv t0, a0

	# check if there are at least 2 elements for a pair
	li a7, 2
	blt t0, a7, error

	# initialize largest product as INT_MIN
	li t1, -2147483648

	# read the first element
	jal ra, check
	mv t4, a0 # t4 holds the previous element

	# initialize loop counter to 1
	li t6, 1

loop:
	bge t6, t0, res # if counter >= number of elements, go to result

 	# read the next (current) element
	jal ra, check
	mv t5, a0 # t5 holds the current element

	# calculate product of previous (t4) and current (t5)
	mul a0, t4, t5

	# check if the new product is larger than the max product so far
	ble a0, t1, no_update # if new_product <= max_product, skip the update

update:
	mv t1, a0 # update largest product
	mv t2, t4 # update first element of the pair
	mv t3, t5 # update second element of the pair
	j no_update # continue to the next step

no_update:
	# the current element now becomes the previous one for the next iteration
	add t4, t5, zero
	j next

next:
	addi t6, t6, 1		# increment index counter
	j loop				# repeat the loop

res:
	# print the output message
	li a7, 4
	la a0, msg2
	ecall

	# print the first element of the pair
	li a7, 1
	mv a0, t2
	ecall

	# print " "
	li a7, 4
	la a0, space
	ecall

	# print the second element of the pair
	li a7, 1
	add a0, t3, zero
	ecall
	
    # Exit cleanly
	li a7, 10
	ecall

error:
	# print the message for insufficient elements
	li a7, 4
	la a0, msg_error
	ecall
	j main
	
check:
    # read string from user
    li a7, 8
    la a0, buffer
    li a1, 30
    ecall

    # initialize parsing variables
    la s1, buffer # s1 = pointer to current char
    li s3, 0 # s3 = result
    li s4, 0 # s4 = sign flag (0 = +, 1 = -)
    
    lb s2, 0(s1)        # Load first byte
    
    # check for negative sign
    li s5, 45           # s5 = for '-'
    bne s2, s5, parse_loop
    li s4, 1            # set sign flag to negative
    addi s1, s1, 1      # move pointer forward
    lb s2, 0(s1)        # load next char

parse_loop:
    # Check for end of string (newline or null)
    li s5, 10           # s5 = '\n'
    beq s2, s5, end_parse
    beqz s2, end_parse  # Null terminator
    
    # digit must be from '0' to '9'
    li s5, 48           # s5 = '0'
    blt s2, s5, invalid_input
    li s5, 57           # s5 = '9'
    bgt s2, s5, invalid_input

    # result = (result * 10) + (char - 48)
    addi s2, s2, -48    # convert char to  digit
    li s5, 10
    mul s3, s3, s5	# shift current result left (decimal)
    add s3, s3, s2      # add new digit
    
    # next char
    addi s1, s1, 1
    lb s2, 0(s1)
    j parse_loop

invalid_input:
    # print error message
    li a7, 4
    la a0, msg_error2
    ecall
    # jump back to start of check to read again
    j check

end_parse:
    # apply negative sign if needed
    beqz s4, return_result
    sub s3, zero, s3    # result = 0 - result

return_result:
    mv a0, s3           # move result to a0 for return
    ret
