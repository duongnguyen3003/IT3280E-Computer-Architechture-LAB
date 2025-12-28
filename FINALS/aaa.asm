.data
    # Prompts
    prompt_cnt:  .asciz "How many numbers to play with? (1-4): "
    prompt_mem:  .asciz "\nMemorize these numbers: "
    prompt_in:   .asciz "\nEnter the numbers (space-separated, then Enter): "
    win_msg:     .asciz "\nCorrect! Starting next round...\n"
    lose_msg:    .asciz "\nIncorrect. Game Over."
    timer_msg:   .asciz "\nErasing in: "
    space:       .asciz " "
    
    # Global variable to store the User's choice of N
    game_n:      .word 0   
    
    # Storage arrays (Reserving space for up to 10 integers -> 40 bytes)
    target_nums: .space 16
    user_nums:   .space 16
    matched:     .space 16

.text
# ==========================================
# 0. Configuration Phase (Ask for N)
# ==========================================
start_setup:
    la a0, prompt_cnt
    jal print_string
    
    li s2, 0            # Accumulator for input
setup_input_loop:
    jal read_char       # Read char
    mv t0, a0
    
    li t1, 10           # Check for Enter key (\n)
    beq t0, t1, setup_done
    
    # Simple validation: Ignore non-digits
    li t1, 48
    blt t0, t1, setup_input_loop
    li t1, 57
    bgt t0, t1, setup_input_loop

    mv a0, t0           # Echo char
    jal print_char
    
    addi t0, t0, -48    # ASCII to Int
    li t1, 10
    mul s2, s2, t1      # shift decimal place
    add s2, s2, t0      # add digit
    j setup_input_loop

setup_done:
    # Save the chosen count (N) to memory
    la t2, game_n
    sw s2, 0(t2)

# ==========================================
# Main Game Loop
# ==========================================
game_start:
    # 1. Generate N Random Numbers (1-99)
    li t0, 0            # Loop counter
gen_loop:
    li a7, 41           # Syscall: rand int
    ecall
    li t1, 99
    rem a0, a0, t1
    
    # Absolute value logic
    bge a0, zero, pos_val
    sub a0, zero, a0
pos_val:
    addi a0, a0, 1      # Ensure range 1-99
    
    la t2, target_nums
    slli t3, t0, 2
    add t2, t2, t3
    sw a0, 0(t2)
    
    addi t0, t0, 1
    
    # Load Limit from memory
    lw t1, game_n       
    blt t0, t1, gen_loop

    # 2. Display Numbers
    la a0, prompt_mem
    jal print_string
    
    li t0, 0
show_nums:
    la t2, target_nums
    slli t3, t0, 2
    add t2, t2, t3
    lw a0, 0(t2)
    jal print_int       
    la a0, space
    jal print_string
    
    addi t0, t0, 1
    lw t1, game_n
    blt t0, t1, show_nums

    # ==========================================
    # 3. Countdown Timer (N * 3 seconds)
    # ==========================================
    la a0, timer_msg
    jal print_string
    
    # Calculate Timer Duration: s0 = game_n * 3
    lw t0, game_n       # Load N
    li t1, 3
    mul s0, t0, t1      # s0 = N * 3

countdown:
    mv a0, s0
    # Use print_int because time might be > 9 (2 digits)
    jal print_int     
    
    la a0, space
    jal print_string
    
    li a0, 1000         # Sleep 1s
    li a7, 32
    ecall
    
    addi s0, s0, -1
    bnez s0, countdown

    # 4. Erase Screen
    li t0, 0
clear_screen:
    li a0, 10           
    jal print_char
    addi t0, t0, 1
    li t1, 30
    blt t0, t1, clear_screen

    # 5. User Input
    la a0, prompt_in
    jal print_string
    
    li s1, 0            # Number count
    li s2, 0            # Accumulator
input_loop:
    jal read_char       
    mv t0, a0           
    
    li t1, 10           # Enter
    beq t0, t1, finalize_last_num
    li t1, 32           # Space
    beq t0, t1, store_num
    
    mv a0, t0
    jal print_char      # Echo
    
    addi t0, t0, -48    
    li t1, 10
    mul s2, s2, t1
    add s2, s2, t0
    j input_loop

store_num:
    li a0, 32
    jal print_char
    la t2, user_nums
    slli t3, s1, 2
    add t2, t2, t3
    sw s2, 0(t2)
    li s2, 0            
    addi s1, s1, 1
    
    # Load Limit from memory
    lw t1, game_n
    blt s1, t1, input_loop
    j validate          

finalize_last_num:
    la t2, user_nums
    slli t3, s1, 2
    add t2, t2, t3
    sw s2, 0(t2)

    # 6. Unordered Validation
validate:
    # Clear matched array
    li t0, 0
clear_matched_loop:
    la t2, matched
    slli t3, t0, 2
    add t2, t2, t3
    sw zero, 0(t2)
    addi t0, t0, 1
    lw t1, game_n
    blt t0, t1, clear_matched_loop
    
    li s3, 0            # Match counter
    li t0, 0            # Target index
outer_match:
    la t2, target_nums
    slli t3, t0, 2
    add t2, t2, t3
    lw t4, 0(t2)        
    
    li t1, 0            # User index
inner_match:
    la t2, user_nums
    slli t3, t1, 2
    add t2, t2, t3
    lw t5, 0(t2)        
    
    bne t4, t5, next_inner
    
    la t2, matched
    slli t3, t1, 2
    add t2, t2, t3
    lw t6, 0(t2)
    bnez t6, next_inner
    
    li t6, 1
    sw t6, 0(t2)        
    addi s3, s3, 1      
    j next_outer        

next_inner:
    addi t1, t1, 1
    lw t2, game_n
    blt t1, t2, inner_match
next_outer:
    addi t0, t0, 1
    lw t1, game_n
    blt t0, t1, outer_match

    # 7. Check Win
    lw t1, game_n
    beq s3, t1, win
    
    la a0, lose_msg
    jal print_string
    li a7, 10           
    ecall

win:
    la a0, win_msg
    jal print_string
    j game_start        

# --- MMIO Helpers (Unchanged) ---

print_int:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a0, 4(sp)
    li t1, 10
    blt a0, t1, pi_base
    div a0, a0, t1
    jal print_int
    lw a0, 4(sp)
    li t1, 10
    rem a0, a0, t1
pi_base:
    addi a0, a0, 48
    jal print_char
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

print_char:
    li t5, 0xffff0008
wait_tx:
    lw t6, 0(t5)
    andi t6, t6, 1
    beq t6, zero, wait_tx
    sw a0, 4(t5)
    ret

print_string:
    mv t2, a0
ps_loop:
    lbu a0, 0(t2)
    beq a0, zero, ps_done
    addi sp, sp, -12
    sw ra, 0(sp)
    sw t2, 4(sp)
    sw a0, 8(sp)
    jal print_char
    lw a0, 8(sp)
    lw t2, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 12
    addi t2, t2, 1
    j ps_loop
ps_done:
    ret

read_char:
    li t5, 0xffff0000
wait_rx:
    lw t6, 0(t5)
    andi t6, t6, 1
    beq t6, zero, wait_rx
    lw a0, 4(t5)
    ret