# CS2340.003 Term Project (Multiplication Game -- Main Loop)
#
# Author: Alen Jo
# Date: 4-27-2025
# Location: UT Dallas

.include "SysCalls.asm"

.data 
	promptmove: .asciiz "\n Your move! Enter your integer from 1-9: "
	invalidmove: .asciiz "\nInvalid move! Try again!!\n"
	cpumove: .asciiz "\n The CPU selected integer (1-9):"
	playerwin: .asciiz "\nYou win! Congrats!!"
	cpuwin: .asciiz "\n CPU wins! Better luck next time..."
	drawgame: .asciiz "\n We have a draw! Play again..."
    	boardFilled: .asciiz "\n Board is full! Game over."
      
.text 
	.eqv BOARD_SIZE 36 # the default 6x6 board like in the multiplication game (again also for the sake of making TAs lives easier, this is hardcoded, but this is going to be a square matrix we can set to reasonably fit all the products)
	.eqv MAX_PRODUCTS 81 # max products in total to track --> for the sake of portability and ease for TAs, this is hardcoded, but otherwise, it's simply the max index * max index
	.eqv FREE 0  # indicates a free marker 
	.eqv PLAYER 1 # indicates that the player has the position 
	.eqv CPU 2 # indicates that CPU has the position

main:	
   	# invoke the generator to create our board
   	la $t9, creategameboard
   	jalr $t9 

    	move $s0, $v0 # board address that contains the fields
    	move $s1, $v1 # value map address
    
    	move $a0, $s0 # board address as parameter
	la $t9, drawTheGameBoard
	jalr $t9 # external calling to the boardgeneration.asm
		
    	# Set board pointers for CPU player module
    	move $a0, $s0  # board address
    	move $a1, $s1  # value map address
    	
    	# initialize board pointers
    	la $t9, setBoardPointers
	jalr $t9

    	# Initialize game state
    	li $s2, 0 # move counter
    	li $s3, 0 # last CPU move
    	li $s4, 0 # last player move
    	li $s5, 0 # game state (0=ongoing, 1=player wins, 2=CPU wins, 3=draw) --> helps prevent the program from "hanging"
    
    	# CPU goes first
    	la $t9, initCPUplayer
	jalr $t9
    	
    	move $s3, $v0  # store CPU move
    
    	# Print CPU's move
    	li $v0, SysPrintString
    	la $a0, cpumove
    	syscall
    
    	li $v0, SysPrintInt
    	move $a0, $s3
    	syscall

    	# Main game loop
	gameloop:
   		 # Check if board is full (36 moves)
    		li $t0, BOARD_SIZE
    		beq $s2, $t0, gamedraw
    
    		# Player's turn prompting -- we use jalr bause the word addr is exceeded beyond the 26-bit buffer unfortunately
    		la $t9, playerMovePrompt 
    		jalr $t9
    		
    		move $s4, $v0 # store player move
    		
    		# Calculate product
    		mul $t0, $s3, $s4 # CPU move * Player move
        
    		# Make the move on the board
    		move $a0, $s0  # board address
    		move $a1, $t0  # product
    		li $a2, PLAYER # mark as player
    		
    		jal markBoard
    		    
    		move $a0, $s0 # grab the board addr
    		addi $sp, $sp, -4 # allocate stack space 
		sw $ra, 0($sp) # save return address
		la $t9, drawTheGameBoard
		jalr $t9 # resolves the issue with target word addr being overflowed beyond 26-bit
		
		lw $ra, 0($sp) # restore return address
		addi $sp, $sp, 4 # deallocate stack space
		
    		# Update move counter
   		addi $s2, $s2, 1
    
    		# Check for win
    		move $a0, $s0  # board address
    		la $t7, checkWin
    		jalr $t7
    		
    		beq $v0, PLAYER, player_wins
    
    		# Check if board is full
    		li $t0, BOARD_SIZE
    		beq $s2, $t0, gamedraw
    
        	# CPU's turn
        	move $a0, $s0  # board address
        	move $a1, $s4
    		la $t7, findCPUMove # get best CPU move
    		jalr $t7
    		
    		move $s3, $v0 # store CPU move
    
    		# Print CPU's move to stdout
    		li $v0, SysPrintString
    		la $a0, cpumove # load in our cpumove str
    		syscall
    
    		# printing our the integer to stdout
    		li $v0, SysPrintInt
    		move $a0, $s3
    		syscall
    
    		# Calculate product
    		mul $t0, $s3, $s4 # CPU move * Player move
    
    		# Make the move on the board
    		move $a0, $s0 # board address
    		move $a1, $t0 # product
    		li $a2, CPU # mark as CPU
    		
    		la $t9, markBoard # mark the board
    		jalr $t9 
    		
    		bltz $v0, invalidMoveByCPU # Check if invalid move
    
    		move $a0, $s0 # board address stored as an argument
    		
    		addi $sp, $sp, -4 # allocate stack space
		sw $ra, 0($sp) # save return address
		la $t9, drawTheGameBoard
		jalr $t9 # external function, so we should invoke jalr to extend the bits
		
		# restore the stack back
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
    		addi $s2, $s2, 1 # Update move counter
    		
    		move $a0, $s0  # board address
    		la $t9, checkWin
    		jalr $t9
    		beq $v0, CPU, cpuwins
    		
    		j gameloop # Continue looping the game until we either win, cpu wins, or rarely speaking, we obtain a draw (harder to get imo)

# Handle invalid player move error as a regular message  
invalidMoveByPlayer:	
	# play the illegal move noise (this would correspond to 0)
	li $a0, 0
	la $t9, soundEffectLibrary
	jalr $t9
	
    	li $v0, SysPrintString
    	la $a0, invalidmove
    	syscall
    	
    	la $t9, gameloop
	jr $t9

# Handle invalid CPU move (shouldn't happen but expect the unexpected)
invalidMoveByCPU:
    	# Get any valid move as fallback
    	li $v0, SysPrintString
    	la $a0, invalidmove
    	syscall
    	
    	la $t9, gameloop
	jr $t9

# Player wins message stdout
player_wins:
	# play the winner noise (this would correspond to 2)
	li $a0, 1
	la $t9, soundEffectLibrary
	jalr $t9
	
    	li $v0, SysPrintString
    	la $a0, playerwin
    	syscall
    	la $t9, stopgame
    	jr $t9

# CPU wins message stdout
cpuwins:
	# play the loser noise (this would correspond to 1)
	li $a0, 2
	la $t9, soundEffectLibrary
	jalr $t9
	
    	li $v0, SysPrintString
    	la $a0, cpuwin
    	syscall
    	la $t9, stopgame
    	jr $t9

# Game is a draw stdout
gamedraw:
	# play the draw noise (this would correspond to 3)
	li $a0, 2
	la $t9, soundEffectLibrary
	jalr $t9
	
    	li $v0, SysPrintString
    	la $a0, drawgame
    	syscall
    	la $t9, stopgame
    	jr $t9

# End the game
stopgame:
    	li $v0, SysExit
    	syscall

# Function to make the player move
playerMovePrompt:
    	addi $sp, $sp, -4 # allocate stack space
   	sw $ra, 0($sp) # store return address
    
    	playerInput:
    		# print the prompt message
        	li $v0, SysPrintString
        	la $a0, promptmove
        	syscall
    
    		# obtain the input range
        	li $v0, SysReadInt
        	syscall
        	move $t0, $v0
    
        	# Validate input range (1-9)
        	blt $t0, 1, invalidEntry
        	bgt $t0, 9, invalidEntry
        
        	# Valid input	
        	move $v0, $t0  # return user input
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
        	jr $ra # go back to the caller
    
    		invalidEntry:
        		li $v0, SysPrintString
        		la $a0, invalidmove
        		syscall
        
        		la $t9, playerInput
			jr $t9


markBoard:
    	addi $sp, $sp, -16 # allocate stack space
    	sw $ra, 0($sp) # store return address
    
    	# Call validMove with the same arguments (board address and product)
    	move $a0, $s0  # board address
    	move $a1, $t0  # product
    	sw $a0, 4($sp) # save board addr
    	sw $a1, 8($sp) # save product
    	sw $a2, 12($sp) # save player marker
    	la $s5, validMove # load address of validMove function
    	jalr $ra, $s5 # call validMove
    	
    	# Check validMove result
    	bnez $v0, markInvalid  # if result is not 0, move is invalid
    
    	# Move is valid, $v1 contains the address of the board entry to mark such	
    	lw $a2, 12($sp) # restore player marker
    
    	# Mark the position
    	sw $a2, 4($v1) # store player marker at offset 4 from the board entry
    	li $v0, 0 # successful
    	j markExit
    
	markInvalid:
    		li $v0, -1 # invalid move indicator
 
markExit:
    	lw $a2, 12($sp)
    	lw $a1, 8($sp)
    	lw $a0, 4($sp)
    	lw $ra, 0($sp)
    	
    	addi $sp, $sp, 16
    	jr $ra
