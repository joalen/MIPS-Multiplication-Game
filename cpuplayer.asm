# CS2340.003 Term Project (Multiplication Game -- CPU Winning Algorithm )
#
# Author: Alen Jo
# Date: 4-23-2025
# Location: UT Dallas

.include "SysCalls.asm"

.eqv BOARD_SIZE 36 # the default 6x6 board like in the multiplication game
.eqv FREE 0  # indicates a free marker 
.eqv PLAYER 1 # indicates that the player has the position 
.eqv CPU 2 # indicates that CPU has the position

.data 
    	boardptr: .word 0
    
.globl initCPUplayer
.globl findCPUMove
.globl setBoardPointers

.text
setBoardPointers:
	# allocating three spots because apparently, I run into word boundary issues and I need more space on the stack to prevent that
	addi $sp, $sp, -12
	sw $ra, 0($sp) 
	sw $s0, 4($sp) 
	sw $s1, 8($sp) 
	
    	sw $a0, boardptr # Store board address we've retrieved from main loop that then came from the boardgeneration.asm program
    	
    	lw $s1, 8($sp)
    	lw $s0, 4($sp)
    	lw $ra, 0($sp)
    	
    	addi $sp, $sp, 4
    	jr $ra # Return
    
initCPUplayer:
	addi $sp, $sp, -4 # Allocate stack space
    	sw $ra, 0($sp) # Save return address
    
    	li $v0, SysRandIntRange # Random number
    	li $a0, 0 # min index to start our random number search
    	li $a1, 9 # max index to end our random number search (exclusive, but this will get fixed)
    	syscall
    
    	addi $v0, $a0, 1 # Convert now to 1-9
    
    	lw $ra, 0($sp) # Restore return address
    	addi $sp, $sp, 4 # Free stack space
    	jr $ra # Return

findCPUMove:
	# allocate the stack; obviously, this is muscle memory now, so commenting this exact line would be cumbersome, but essentially here, we require the board addr, the multiplicand the player picked
    	addi $sp, $sp, -20
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)
    	sw $s3, 16($sp) # this register is what I use to track for attempts made by the CPU to find the best move <-- don't want it to go to infinity!
    
    	move $s0, $a0 # board address
    	move $s1, $a1 # user provided multiplicand
    
    	li $s3, 0 # Initialize attempt counter to zero
    
	tryWinningMove:
    		addi $s3, $s3, 1 # Increment attempt counter
    		li $t0, 10 # Maximum number of attempts
    		bge $s3, $t0, tryRandomMove # If too many attempts, try a random move
    
    		jal initCPUplayer # invoke our random number generator for the CPU to pick
    		
    		move $s2, $v0 # we got the random number we need from CPU
    		move $a0, $s0 # Board address
    		
    		move $a1, $s2 # Product candidate to try
    		jal validMove # let's see if this board space is allowed (so check if it's free and not occupied) 
    		
    		bltz $v0, tryWinningMove  # now let's try the winning move and see what we get ($v0 should contain the validMove reg)
    
    		# Simulate the move by marking position as CPU (so faking it)
    		li $t0, CPU
    		sw $t0, 4($v1)
    
    		# Check if this move can help the CPU win
    		move $a0, $s0
    		jal checkWin # now let's see if we can win --> go to movevalidation.asm and then we run our checkWin procedure
    		
    		beq $v0, $t0, foundWinningMove # if we got a winning move, then we can pass that back to main.asm
    
    		# Revert move (failed winning move so let's reverse that)
    		li $t1, FREE
    		sw $t1, 4($v1)
    
    		# Reset attempt counter for the blocking move part of this algo since we can't seem to win by ourselves so we play defense
    		li $s3, 0
   
	tryBlockingMove:
    		addi $s3, $s3, 1 # Increment attempt counter
    		li $t0, 10 # Maximum number of attempts
    		bge $s3, $t0, tryRandomMove # If too many attempts, try a random move
     
    		jal initCPUplayer # again, back to getting our random number
    		move $s2, $v0 # Save generated product
    
    		move $a0, $s0 # board addr
    		move $a1, $s2 # product of choice
    		jal validMove # go to see if this blocking move is valid to take
    		
    		bltz $v0, tryBlockingMove  # Invalid? Try another
    
    		# Simulate the move by marking position as USER (so we "mock" the USER and see if we defeated the USER and stumped them)
    		li $t0, PLAYER
    		sw $t0, 4($v1)
    
    		# Check if the user would win with this move (not looking good for the CPU if it passes!)
    		move $a0, $s0
    		jal checkWin 
    		beq $v0, $t0, blockUserMove
    
    		# Revert the move we made since we don't want that to be permanent
   		li $t1, FREE
    		sw $t1, 4($v1)
    
    		# If no win or block, just "go with the flow" and pick the random integer of choice like how we initially started
    		j goWithTheFlow

	# fallback strategy for when we've tried too many times
	tryRandomMove:
    		li $s3, 0 # Reset attempt counter
    
		randomMoveLoop:
    			addi $s3, $s3, 1
    			li $t0, 20  # Higher attempt limit for finding any valid move
    			bge $s3, $t0, emergencyMove # Last resort if we can't find any valid move
    
    			jal initCPUplayer # get our random number from CPU
    			move $s2, $v0
    
    			move $a0, $s0
    			move $a1, $s2
    			jal validMove
    			bltz $v0, randomMoveLoop  # If invalid, try again
    
    			# Found a valid move so let's go with the flow here
    			j goWithTheFlow

	# Last resort if we can't find any valid move (even with "going with the flow")
	emergencyMove:
    		li $s2, 1 # Start with move 1
    
		emergencyLoop:
    			move $a0, $s0
    			move $a1, $s2
    			jal validMove # check if the space occupied
    			
    			bgez $v0, goWithTheFlow
    
    			addi $s2, $s2, 1
    			li $t0, 50 # Reasonable upper limit for moves
    			ble $s2, $t0, emergencyLoop
    
    			# If all else fails, return move 1 since that's just the default I picked and I don't believe we will ever encounter this issue I hope
    			li $v0, 1
    			j endFindMove
    
	foundWinningMove:
    		move $v0, $s2 # we have a winner, winner, chicken dinner move
    		j endFindMove # stop CPU algo operation
    
	blockUserMove:
    		move $v0, $s2 # blocking time! 
    		j endFindMove # stop CPU algo operation
    
	goWithTheFlow:
    		move $v0, $s2 # use the current move
    
	endFindMove:
    		# resetting the stack
    		lw $s3, 16($sp)
    		lw $s2, 12($sp)
    		lw $s1, 8($sp)
    		lw $s0, 4($sp)
    		lw $ra, 0($sp)
    		addi $sp, $sp, 20
    
    		jr $ra # go back to main asm
