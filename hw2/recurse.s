# Recursive program for HW2 - CS250 @ Duke
# Receives an input "n" from the console
# Prints f(n) = 3*n+[2*f(n-1)] -2, where f(0) = -2

.text
.align 2
.globl main

main:
	# Stack management
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $t0, 4($sp) # n value
	sw $t1, 8($sp) # f(n)
	
	# Print enter n message
	li $v0, 4
	la $a0, enter_n
	syscall

	# Load integer from console
	li $v0, 5
	syscall
	move $t0, $v0 # my n value

	move $a0, $t0
	jal compute_fn
	move $t1, $v0

	# Print final value
	li 		$v0, 1
	move 	$a0, $t1
	syscall

	# Stack management
	lw $ra, 0($sp)
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	addi $sp, $sp, 12

	jr $ra

compute_fn:
	# Stack management
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp) # $s0 = my original n value
	sw $s1, 8($sp) # $s1 = 3, for multiplication

	bne $a0, $0, compute_body # if $a0 != 0, skip base case
	li $v0, -2
	j exit_recursion

	compute_body:
	move $s0, $a0 # Save argument $a0 to $s0
	addi $a0, $a0, -1 # Decrease n by 1, and use arg for procedure
	jal compute_fn

	# Multiply $s0 by three, and $v0 (computefn(n-1)) two times
	li $s1, 3
	mul $s0, $s0, $s1 # $s0 = 3n
	add $v0, $v0, $v0 # $v0 = 2*computefn(n-1)
	add $v0, $v0, $s0 # $v0 = 3n + 2computefn(n-1)
	addi $v0, $v0, -2 # $v0 = 3n + 2computefn(n-1) - 2

exit_recursion:
	# Stack management
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

.data
	enter_n: .asciiz "Please enter an integer:\n"