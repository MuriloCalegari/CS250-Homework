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
	addi, $sp, $sp, -8
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
	beq $v0, $0, print_names_start # if strcmp(infected, done) == 0, then go to print names

	# Read transmitter
	li $v0, 8
	la $a0, transmitter
	li $a1, 32
	syscall

	## REMOVE \n FROM infected/transmitter
	la $a0, transmitter
	jal remove_nln
	la $a0, infected
	jal remove_nln

	# Call put_infected
	la $a0, infected
	jal put_infected

	# Call put_transmitter
	la $a0, transmitter
	la $a1, infected
	jal put_transmitter

	# Clean buffers
	la $a0, infected
	jal strclr
	la $a1, transmitter
	jal strclr

	j read_pair

	print_names_start:
	move $t0, $s7 # currentPerson = $t0 = firstElement
	print_names:
	beq $t0, $0, exit
	lb $t1, 64($t0) # $t1 = currentPerson->infected[1][0]
	bne $t1, $0, print_names_two_infected # if currentPerson->infected[1][0] != '\0'
	lb $t1, 32($t0) # $t1 = currentPerson->infected[0][0]
	bne $t1, $0, print_names_one_infected # if currentPerson->infected[0][0] != '\0'
	j print_name_currentperson

	print_names_two_infected:
	# Print name of transmitter
	li 		$v0, 4
	move 	$a0, $t0
	syscall

	# Print space
	li 		$v0, 4
	la 		$a0, space
	syscall
	
	# Print name of first infected
	add $t1, $t0, 32
	li 		$v0, 4
	move 	$a0, $t1
	syscall

	# Print space
	li 		$v0, 4
	la 		$a0, space
	syscall
	
	# Print name of second infected
	add $t1, $t0, 64
	li 		$v0, 4
	move 	$a0, $t1
	syscall

	# Print new line
	li 		$v0, 4
	la 		$a0, new_line
	syscall

	lw $t0, 96($t0) # currentPerson = currentPerson->next;
	j print_names
	
	print_names_one_infected:
	# Print name of transmitter
	li 		$v0, 4
	move 	$a0, $t0
	syscall

	# Print space
	li 		$v0, 4
	la 		$a0, space
	syscall
	
	# Print name of first infected
	add $t1, $t0, 32
	li 		$v0, 4
	move 	$a0, $t1
	syscall

	# Print new line
	li 		$v0, 4
	la 		$a0, new_line
	syscall

	lw $t0, 96($t0) # currentPerson = currentPerson->next;
	j print_names
	
	print_name_currentperson:
	li 		$v0, 4
	move 	$a0, $t0
	syscall
	
	# Print new line
	li 		$v0, 4
	la 		$a0, new_line
	syscall

	lw $t0, 96($t0) # currentPerson = currentPerson->next;
	j print_names
	
	exit:
	# Collapse stack
	lw $s7, 4($sp)
	lw $ra, 0($sp)
	addi, $sp, $sp, 8

	jr $ra

### MY FUNCTIONS ###

# $a0 = string buffer to remove trailing new line
remove_nln:
	lb $t0, 0($a0)
	beq $t0, $zero, done_clearing_nln
	
	beq $t0, 10, found_nln ## if char == '\n'
	addi $a0, $a0, 1
	j remove_nln

	found_nln:
	sb $zero, 0($a0)

	done_clearing_nln:
	jr $ra

# $a0 = transmitter, $a1 = infected
### INTERNAL REGISTERS USED
# $s0 = pointer to currentPerson in linked list
# $s1 = result of string comparasion
# $s2 = used for storing values of accesses to currentPerson
# $s3 = saved transmitter_name argument
# $s4 = saved infected_name argument
put_transmitter:
	# Stack management
	addi, $sp, $sp, -24
	sw, $ra, 0($sp)
	sw, $s0, 4($sp)
	sw, $s1, 8($sp)
	sw, $s2, 12($sp)
	sw, $s3, 16($sp)
	sw, $s4, 20($sp)

	move $s3, $a0 # Save $a0 to $s3
	move $s4, $a1 # Save $a1 to $s4
	bne $s7, $0, transmitter_firstelement_not_null

	move $a0, $s3
	jal initialize_infected
	move $s7, $v0
	j transmitter_exit_while

	transmitter_firstelement_not_null:

	move $s0, $s7 # currentPerson = firstElement

	while_put_transmitter:
		beq $s0, $0, transmitter_exit_while # if currentPerson == NULL ($0), break loop
		
		# Compare currentPerson->name to transmitterName
		move $a0, $s0 # strcmp(currentPerson-name,
		move $a1, $s3 # transmitterName)
		jal strcmp
		move $s1, $v0 # save result of strcmp to $s1

		bne $s1, $0, continue # if strCmp == 0 fill infected[0] or infected[1]
		
		lw $t0, 32($s0) # currentPerson->infected[0][0]
		bne $t0, $0, first_string_not_null

			# if (currentPerson->infected[0][0] == '\0') {
			addi $t0, $s0, 32 # $t0 pointer to currentPerson->infected[0]
			move $a0, $t0
			move $a1, $s4
			jal strcpy
			j transmitter_exit_while

		first_string_not_null:
			addi $t0, $s0, 32 # $t0 pointer to currentPerson->infected[0]
			move $a0, $t0
			move $a1, $s4
			jal strcmp

			bge $v0, $0, else_put_infected_into_second_position
			# if (strcmp(currentPerson->infected[0], infectedName) < 0) {
				addi $t0, $s0, 64 # $t0 pointer to currentPerson->infected[1]
				move $a0, $t0
				move $a1, $s4
				jal strcpy
				j transmitter_exit_while

			else_put_infected_into_second_position:
				#strcpy(currentPerson->infected[1], currentPerson->infected[0]);
				add $t0, $s0, 64 # $t0 pointer to currentPerson->infected[1]
				move $a0, $t0
				add $t0, $s0, 32 # $t0 pointer to currentPerson->infected[0]
				move $a1, $t0
				jal strcpy

				#strcpy(currentPerson->infected[0], infectedName);
				add $t0, $s0, 32
				move $a0, $t0
				move $a1, $s4
				jal strcpy

				j transmitter_exit_while

		continue:
		blt	$s1, $0, transmitter_strcmp_less_than_zero	# if $s1 < $0 then strcmp_infected_less_than
		j transmitter_strcmp_else

		transmitter_strcmp_less_than_zero: # if (strCmp < 0) {
			lw $s2, 96($s0) # $s2 = value of currentPerson.next
			beq $s2, $0, transmitter_currentperson_null 
			j transmitter_else_currentperson_null
			
			transmitter_currentperson_null: # if (currentPerson->next == NULL) {
				move $a0, $s4
				move $a1, $s3
				jal initialize_transmitter
				sw $v0, 96($s0) # currentPerson->next = infected;
				j transmitter_exit_while
			transmitter_else_currentperson_null: # } else 
				# Compare currentPerson->next->name to transmitterName
				lw $s2, 96($s0) # $s2 = value of currentPerson.next (pointer to first character)
				move $a0, $s2 # strcmp(currentPerson->next->name,
				move $a1, $s3 # transmitterName)
				jal strcmp
				ble	$v0, $0, transmitter_advance_loop	# if $v0 <= $0 then transmitter_advance_loop
				move $a0, $s4
				move $a1, $s3
				jal initialize_transmitter
				lw $s2, 96($s0) # $s2 = currentPerson->next
				sw $s2, 96($v0) # infected->next = currentPerson->next
				sw $v0, 96($s0) # currentPerson->next = infected
				j transmitter_exit_while
		transmitter_strcmp_else: # } else {
			move $a0, $s4
			move $a1, $s3
			jal initialize_transmitter
			sw $s0, 96($v0) # infected->next = currentPerson
			move $s7, $v0 # firstElement = infected;
			j transmitter_exit_while
		
		transmitter_advance_loop:
		lw $s0, 96($s0) # $s0 = currentPerson->next
		j while_put_transmitter
	
	transmitter_exit_while:

	# Collapse stack
	lw, $ra, 0($sp)
	lw, $s0, 4($sp)
	lw, $s1, 8($sp)
	lw, $s2, 12($sp)
	lw, $s3, 16($sp)
	lw, $s4, 20($sp)
	addi, $sp, $sp, 24

	jr $ra

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

	move $s3, $a0 # Save $a0 to $s3
	bne $s7, $0, infected_firstelement_not_null

	move $a0, $s3
	jal initialize_infected
	move $s7, $v0
	j infected_exit_while

	infected_firstelement_not_null:

	move $s0, $s7 # currentPerson = firstElement

	while_put_infected:
		beq $s0, $0, infected_exit_while # if currentPerson == NULL ($0), break loop
		
		# Compare currentPerson->name to infectedName
		move $a0, $s0 # strcmp(currentPerson-name,
		move $a1, $s3 # infectedName)
		jal strcmp
		move $s1, $v0 # save result of strcmp to $s1

		beq $s1, $0, infected_exit_while # if strCmp == 0 return;
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
				ble	$v0, $0, advance_loop	# if $v0 <= $0 then advance_loop
				move $a0, $s3
				jal initialize_infected # $v0 = initializeInfected(infectedName) -> pointer
				lw $s2, 96($s0) # $s2 = currentPerson->next
				sw $s2, 96($v0) # infected->next = currentPerson->next
				sw $v0, 96($s0) # currentPerson->next = infected
				j infected_exit_while
		infected_strcmp_else: # } else {
			move $a0, $s3
			jal initialize_infected # $v0 = initializeInfected(infectedName) -> pointer
			sw $s0, 96($v0) # infected->next = currentPerson
			move $s7, $v0 # firstElement = infected;
			j infected_exit_while
		
		advance_loop:
		lw $s0, 96($s0) # $s0 = currentPerson->next
		j while_put_infected
	
	infected_exit_while:

	# Collapse stack
	lw, $ra, 0($sp)
	lw, $s0, 4($sp)
	lw, $s1, 8($sp)
	lw, $s2, 12($sp)
	lw, $s3, 16($sp)
	addi, $sp, $sp, 20

	jr $ra

# $a0 = pointer to first char of infected_name
### INTERNAL REGISTERS USED
# $s0 = copy of $a0
initialize_infected:
	# Stack management
	addi, $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)

	move $s0, $a0

	# Allocate 100B for my struct
	li $v0, 9
	li $a0, 100
	syscall #$v0 = pointer to 100B space in memory

	move $a1, $s0 # src = infected_name
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
	lw $s0, 4($sp)
	addi, $sp, $sp, 8
	
	jr $ra
	
# $a0 = pointer to first char of infected_name
# $a1 = pointer to first char of transmitter_name
### INTERNAL REGISTERS USED
# $s0 = copy of $a0
# $s1 = copy of $a1
initialize_transmitter:
	# Stack management
	addi, $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	move $s0, $a0
	move $s1, $a1

	# Allocate 100B for my struct
	li $v0, 9
	li $a0, 100
	syscall #$v0 = pointer to 100B space in memory

	move $a1, $s1
	move $a0, $v0 # dest = first 32 bytes of struct
	jal strcpy

	# Fill infected[0] with infected_name
	move $a1, $s0 		# infected_name as src
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
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi, $sp, $sp, 12
	
	jr $ra

### HELPER FUNCTIONS ###
# $a0 = dest, $a1 = src
strcpy:
	lb $t0, 0($a1)
	sb $t0, 0($a0)
    beq $t0, $zero, done_copying
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	j strcpy

	done_copying:
	jr $ra

# $a0 = string buffer to be zeroed out
strclr:
	lb $t0, 0($a0)
	beq $t0, $zero, done_clearing
	sb $zero, 0($a0)
	addi $a0, $a0, 1
	j strclr

	done_clearing:
	jr $ra

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

.data
	infected: .space 32
	transmitter: .space 32
	done: .asciiz "DONE\n"
	empty_string: .asciiz ""
	new_line: .asciiz "\n"
	space: .asciiz " "