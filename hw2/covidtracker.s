# Covidtracker program for HW2 - CS250 @ Duke

.text
.align 2
.globl main

### Struct person ###
# name = 32 bytes
# infected[0] = 32 bytes
# infected[1] = 32 bytes
# next = 4 bytes
### Total = 100 bytes

## Given $x register holding pointer to element:
# 0($x)	 ->	name[0]
# 32($x) ->	infected[0][0]
# 64($x) ->	infected[1][0]
# 96($x) ->	pointer for next person in linked list

### Global variables (DO NOT use anywhere else. No function is saving this)
# $s7 -> pointer to first patient in my linked list

main:
	# Stack management
	addi, $sp, $sp, -4
	sw $ra, 0($sp)
	sw $s7, 4($sp) # Pointer to first element
	
	read_pair:
	# Read infected
	li $v0, 8
	la $a0, infected
	li $a1, 32
	syscall

	# Check if line == done
	la $a0, infected
	la $a1, done
	jal strcmp
	beq $v0, $0, print_names # if strcmp(infected, done) == 0, then go to print names

	# Read transmitter
	li $v0, 8
	la $a0, transmitter
	li $a1, 32
	syscall

	# Call put_transmitter
	la $a0, infected
	la $a1, transmitter
	jal put_transmitter

	# Call put_infected
	la $a0, infected
	jal put_infected

	j read_pair

	print_names:
	lw $ra, 0($sp)
	addi, $sp, $sp, 4

	jr $ra

### MY FUNCTIONS ###
# $a0 = infected, $a1 = transmitter
put_transmitter:

# $a0 = infected_name
### INTERNAL REGISTERS USED
# $s0 = pointer to currentPerson in linked list
# $s1 = result of string comparasion
# $s2 = used for storing values of accesses to currentPerson
# $s3 = saved infected_name argument
put_infected:
	# Stack management
	addi, $sp, $sp, -20
	sw, $ra, 0($sp)
	sw, $s0, 4($sp)
	sw, $s1, 8($sp)
	sw, $s2, 12($sp)
	sw, $s3, 16($sp)

	move $s0, $s7 # currentPerson = firstElement
	move $s3, $a0 # Save $a0 to $s3

	while_put_infected:
		beq $s0, $v0, infected_exit_while # if currentPerson == NULL ($0), break loop
		
		# Compare currentPerson->name to infectedName
		move $a0, $s0 # strcmp(currentPerson-name,
		move $a1, $s3 # infectedName)
		jal strcmp
		move $s1, $v0 # save result of strcmp to $s1

		beq $s1, $v0, infected_exit_while # if strCmp == 0 return;
		blt	$s1, $0, infected_strcmp_less_than_zero	# if $s1 < $0 then strcmp_infected_less_than
		j infected_strcmp_else

		infected_strcmp_less_than_zero: # if (strCmp < 0) {
			lw $s2, 96($s0) # $s2 = value of currentPerson.next
			beq $s2, $0, infected_currentperson_null 
			j infected_else_currentperson_null
			
			infected_currentperson_null: # if (currentPerson->next == NULL) {
				move $a0, $s3
				jal initialize_infected # $v0 = initializeInfected(infectedName) -> pointer
				sw $v0, 96($s0) # currentPerson->next = infected;
				j infected_exit_while
			infected_else_currentperson_null: # } else 
				# Compare currentPerson->next->name to infectedName
				lw $s2, 96($s0) # $s2 = value of currentPerson.next (pointer to first character)
				move $a0, $s2 # strcmp(currentPerson->next->name,
				move $a1, $s3 # infectedName)
				jal strcmp
				ble	$v0, $0, infected_exit_while	# if $v0 <= $0 then break loop
				move $a0, $s3
				jal initialize_infected # $v0 = initializeInfected(infectedName) -> pointer
				lw $s2, 96($s0) # $s2 = currentPerson->next
				sw $s2, 96($v0) # infected->next = currentPerson->next
				sw $v0, $s2 # currentPerson->next = infected
				j infected_exit_while
		infected_strcmp_else: # } else {
			move $a0, $s3
			jal initialize_infected # $v0 = initializeInfected(infectedName) -> pointer
			sw $s0, 96($v0) # infected->next = currentPerson
			move $s7, $v0 # firstElement = infected;
			j infected_exit_while
		
		lw $s0, 96($s0) # $s0 = currentPerson->next
	
	infected_exit_while:

	# Collapse stack
	lw, $ra, 0($sp)
	lw, $s0, 4($sp)
	lw, $s1, 8($sp)
	lw, $s2, 12($sp)
	sw, $s3, 16($sp)
	addi, $sp, $sp, 20

	jr $ra

# $a0 = pointer to first char of infected_name
initialize_infected:
	# Stack management
	addi, $sp, $sp, -4
	sw $ra, 0($sp)

	# Allocate 100B for my struct
	li $v0, 9
	li $a0, 100
	syscall #$v0 = pointer to 100B space in memory

	# $a0 = infectedName, so I move it to $a1
	move $a1, $a0
	move $a0, $v0 # dest = first 32 bytes of struct
	jal strcpy

	# Fill infected[0] and infected[1] with empty string
	la $a1, empty_string
	addi $v0, $v0, 32 # Move pointer to infected[0][0]
	move $a0, $v0 # infected[0][0]
	jal strcpy

	la $a1, empty_string
	addi $v0, $v0, 32 # Move pointer to infected[1][0]
	move $a0, $v0 # infected[1][0]
	jal strcpy

	# Initialize next pointer to zero
	addi $v0, $v0, 32 # Move pointer to next*
	sw $0, 0($v0)

	addi $v0, $v0, -96 # Return $v0 to beggining of struct

	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	
	jr $ra
	
# $a0 = pointer to first char of infected_name
# $a1 = pointer to first char of transmitter_name
initialize_transmitter:
	# Stack management
	addi, $sp, $sp, -4
	sw $ra, 0($sp)

	# Allocate 100B for my struct
	li $v0, 9
	li $a0, 100
	syscall #$v0 = pointer to 100B space in memory

	# $a1 is already transmitter name. So no need to move it
	move $a0, $v0 # dest = first 32 bytes of struct
	jal strcpy

	# Fill infected[0] with infected_name
	move $a1, $a0 		# infected_name as src
	addi $v0, $v0, 32 	# Move pointer to infected[0][0]
	move $a0, $v0 		# pointer to infected[0][0] as dest
	jal strcpy

	# Fill infected[1] with empty string
	la $a1, empty_string
	addi $v0, $v0, 32 # Move pointer to infected[1][0]
	move $a0, $v0 # infected[1][0]
	jal strcpy

	# Initialize next pointer to zero
	addi $v0, $v0, 32 # Move pointer to next*
	sw $0, 0($v0) # Initialize to 0

	addi $v0, $v0, -96 # Return $v0 to beggining of struct

	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	
	jr $ra


### HELPER FUNCTIONS ###
# $a0, $a1 = strings to compare
# $v0 = result of strcmp($a0, $a1)
strcmp:
	lb $t0, 0($a0)
	lb $t1, 0($a1)

	bne $t0, $t1, done_with_strcmp_loop
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	bnez $t0, strcmp
	li $v0, 0
	jr $ra
		

	done_with_strcmp_loop:
	sub $v0, $t0, $t1
	jr $ra

# $a0 = dest, $a1 = src
strcpy:
	lb $t0, 0($a1)
	beq $t0, $zero, done_copying
	sb $t0, 0($a0)
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	j strcpy

	done_copying:
	jr $ra

.data
	infected: .space 32 ### TODO: Are these initialized to zero?
	transmitter: .space 32
	done: .asciiz "DONE\n"
	empty_string: .asciiz ""