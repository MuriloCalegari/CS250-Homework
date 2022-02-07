# Recursive program for HW2 - CS250 @ Duke
# Receives an input "n" from the console
# Prints f(n) = 3*n+[2*f(n-1)] -2, where f(0) = -2

.text
.align 2
.globl main

main:
	# Stack management
	addi $sp, $sp -12
	sw $ra, 0($sp)
	sw $s0, 4($sp) # n value
	sw $s1, 8($sp) # f(n)
	
	# Print enter n message
	li $v0, 4
	la $a0, enter_n
	syscall

	# Load integer from console
	li $v0, 5
	syscall
	move $s0, $v0 # my n value

	move $a0, $s0
	jl compute_fn
	move $s1, $v0

	# Print final value
	li 		$v0, 1
	move 	$a0, $s1
	syscall

	# Stack management
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp -8

compute_fn:


.data
	enter_n: .asciiz "Please enter an integer:\n"