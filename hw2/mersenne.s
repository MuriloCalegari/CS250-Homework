# Mersenne program for HW2 - CS250 @ Duke
# Receives an input "n" from the console
# Prints the n-th mersenne number

.text
.align 2
.globl main

main:
	# Stack management
	addi $sp, $sp -24
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	
	li $s0, 1 # base mersenne value
	li $s1, 2 # base of multiplication
	
	# Print enter n message
	li $v0, 4
	la $a0, enter_n
	syscall

	# Load integer from console
	li $v0, 5
	syscall
	move $s2, $v0 # my n value
	
	li $s4, 1 # loop index

	for_loop:
	mul $s0, $s0, $s1 # $v0 = $$0 * 2 [$s1]
	beq $s4, $s2, exit_loop # if i == n, exit loop
	addi $s4, 1 ## increase loop index by one
	j for_loop

	exit_loop:
	addi $s0, -1

	# Print final value
	li 		$v0, 1
	move 	$a0, $s0
	syscall

	# Destroy stack frame
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp -24
	
	jr $ra

.data
	enter_n: .asciiz "Please enter an integer:\n"