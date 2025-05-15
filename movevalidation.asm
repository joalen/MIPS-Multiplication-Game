# CS2340.003 Term Project (Multiplication Game -- move validations)
#
# Author: Alen Jo
# Date: 4-27-2025
# Location: UT Dallas

.text 
	.eqv BOARD_SIZE 36 # the default 6x6 board like in the multiplication game
	.eqv FREE 0  # indicates a free marker 
	.eqv BOARD_WIDTH 6  # Board is 6x6
	.eqv BOARD_HEIGHT 6
	
.globl validMove
.globl checkWin

validMove:
	addi $sp, $sp, -12 # just save the return address to the stack
	sw $ra, 0($sp) # of course we need to go back to the function in question 
	sw $a0, 4($sp) 
	sw $a1, 8($sp)
	
	move $t0, $a0 # board addr retrieved from caller 
	move $t1, $a1 # product retrieved also from caller 
	
	li $t2, 0 # position start

	searchLoop:
    		lw $t3, 0($t0)         # load product at current position
    		beq $t3, $t1, productmatch # if product matches, check occupation
    
    		addi $t0, $t0, 8 # next board position retrieval
    		addi $t2, $t2, 1 # increment counter
    		blt $t2, BOARD_SIZE, searchLoop # continue if not at end of board
    
    		li $v0, -1 # Product not found
    		li $v1, -1 # Invalid position
    		j finish
    
	productmatch:
    		# Check occupation status at offset 4 of board address
    		lw $t4, 4($t0)
    		bne $t4, FREE, occupied # If not FREE (0), move is invalid
    
    		li $v0, 0 # Position is FREE
    		move $v1, $t0 # Return memory address of the board entry
    		j finish
    
	occupied:
    		li $v0, -1 # Position is taken
    		li $v1, -1 # Invalid position
    
	finish:
		# we shall reset the stack
    		lw $a1, 8($sp)
    		lw $a2, 4($sp) 
    		lw $ra, 0($sp)
  
    		addi $sp, $sp, 12
    		jr $ra # go back to sender

checkWin:
    	addi $sp, $sp, -24 
    	sw $ra, 0($sp) # return address
    	sw $s0, 4($sp) # Board base addr
    	sw $s1, 8($sp) # Temp #1
    	sw $s2, 12($sp) # Temp #2
    	sw $s3, 16($sp) # Temp #3
    	sw $s4, 20($sp) # Temp #4 
    
    	move $s0, $a0 # Store board address in $s0
    
    	# Check rows for win
    	jal checkRows
    	bne $v0, $zero, winFound # If winner found, return back to main loop
    
    	# Check columns for win
    	jal checkColumns
    	bne $v0, $zero, winFound  # If winner found, return
    
    	# Check diagonals for win
    	jal checkDiagonals
    
	winFound:
    		lw $s4, 20($sp) # Restore $s4
    		lw $s3, 16($sp) # Restore $s3
    		lw $s2, 12($sp) # Restore $s2
    		lw $s1, 8($sp) # Restore $s1
    		lw $s0, 4($sp) # Restore $s0
    		lw $ra, 0($sp) # Restore return address
    		addi $sp, $sp, 24 # Restore stack pointer
    		jr $ra # Return

	# Row check!
	checkRows:
    		li $t0, 0 # Row counter
    		li $t8, 8 # Constant 8 for multiplications
    		li $t9, BOARD_WIDTH # Load board width
		
		rowLoop:
    			li $t1, 0 # Column counter
    
    			# Calculate row start address: base + (row * BOARD_WIDTH * 8)
    			mul $t2, $t0, $t9 # row * BOARD_WIDTH
    			mul $t2, $t2, $t8 # * 8
    			add $t2, $s0, $t2 # + base
    
		colInRowLoop:
    			li $t7, BOARD_WIDTH # Load the board width
    			addi $t7, $t7, -3 # BOARD_WIDTH - 3
    			bge $t1, $t7, nextRow  # Not enough spaces left in row for 4-in-a-row a
    
    			# Check for 4 consecutive pieces
    			move $t3, $t2 # Current position
    
    			# Load status at current position
    			lw $t4, 4($t3) # Load player value at offset +4
    			beq $t4, $zero, nextCol # Skip if position is empty (FREE = 0)
    
    			# Check next 3 positions for same player
    			li $t5, 1 # Counter for consecutive pieces
    			move $t6, $t4 # Remember player value
    
		rowCheckLoop:
    			addi $t3, $t3, 8 # Move to next column position
    			lw $t4, 4($t3) # Load player value
    			bne $t4, $t6, nextCol  # If not same player, try next column
    
    			addi $t5, $t5, 1  # Increment consecutive counter
    			beq $t5, 4, foundWinner # If 4 consecutive, we have a winner
    
    			j rowCheckLoop  # Continue checking
    
		nextCol:
    			addi $t1, $t1, 1 # Next column
    			addi $t2, $t2, 8 # Next board position
    			li $t7, BOARD_WIDTH # Load board width
    			blt $t1, $t7, colInRowLoop # go back to column in row loop again until we've either found a matching row or exhausted everything...
    
		nextRow:
    			addi $t0, $t0, 1 # Next row
    			li $t7, BOARD_HEIGHT # Load board height
    			blt $t0, $t7, rowLoop
    
    			li $v0, 0 # No winner found
    			jr $ra
    
	# Check columns for win
	checkColumns:
    		li $t0, 0  # Column counter
    		li $t8, 8  # Constant 8 for multiplications
		
		colLoop:
    			li $t1, 0 # Row counter
    
    			# Calculate column start address: base address + (col * 8)
    			mul $t2, $t0, $t8 # col * 8
    			add $t2, $s0, $t2 # add that to the base address
    
		rowInColLoop:
    			li $t7, BOARD_HEIGHT # Load board height
    			addi $t7, $t7, -3 # BOARD_HEIGHT - 3
    			bge $t1, $t7, nextCol2 # Not enough spaces left in column for 4-in-a-row
    
    			# Check for 4 consecutive pieces
    			move $t3, $t2          # Current position
    
   			# Load status at current position
    			lw $t4, 4($t3) # Load player value at offset +4
    			beq $t4, $zero, nextRow2 # Skip if position is empty (FREE = 0)
    
    			# Check next 3 positions for same player
    			li $t5, 1 # Counter for consecutive pieces
    			move $t6, $t4  # Remember player value
    
		colCheckLoop:
    			# Calculate offset to next row: BOARD_WIDTH * 8
    			li $t7, BOARD_WIDTH
    			mul $t7, $t7, $t8 # BOARD_WIDTH * 8
    			add $t3, $t3, $t7 # Move to next row position
    
    			lw $t4, 4($t3) # Load player value
    			bne $t4, $t6, nextRow2 # If not same player, try next row
    
    			addi $t5, $t5, 1 # Increment consecutive counter
    			beq $t5, 4, foundWinner # If 4 consecutive, we have a winner
    
    			j colCheckLoop # Continue checking
    
		nextRow2:
    			addi $t1, $t1, 1 # Next row
    			# Calculate offset to move down one row: BOARD_WIDTH * 8
    			
    			li $t7, BOARD_WIDTH
    			mul $t7, $t7, $t8 # BOARD_WIDTH * 8
    			add $t2, $t2, $t7 # Next board position (move down one row)
    
    			li $t7, BOARD_HEIGHT # Load board height
    			blt $t1, $t7, rowInColLoop
    
		nextCol2:
    			addi $t0, $t0, 1 # Next column
    			
    			# Reset to top of next column
    			mul $t2, $t0, $t8 # col * 8
    			add $t2, $s0, $t2 # base + col*8
    
    			li $t7, BOARD_WIDTH # Load board width
    			blt $t0, $t7, colLoop # go back to looping the column
    
    			li $v0, 0 # No winner found
    			jr $ra

	# Check diagonals for win
	checkDiagonals:
    		li $t8, 8 # Constant 8 for multiplications
    
    		# Check down-right diagonals
    		li $t0, 0 # Start row counter
    		
		downRightRowStart:
    			li $t1, 0 # Start column counter
    
    			# Only check rows with enough space for diagonal
    			li $t7, BOARD_HEIGHT   # Load board height
    			addi $t7, $t7, -3      # BOARD_HEIGHT - 3
    			beq $t0, $t7, checkUpRight
    
    			# Calculate start address: base address + (row * BOARD_WIDTH * 8)
    			li $t7, BOARD_WIDTH # Load board width
    			mul $t2, $t0, $t7 # row * BOARD_WIDTH
    			mul $t2, $t2, $t8 # * 8
    			add $t2, $s0, $t2 # + base address
    
		downRightColStart:
    			# Only check columns with enough space for diagonal
    			li $t7, BOARD_WIDTH # Load board width
    			addi $t7, $t7, -3 # BOARD_WIDTH - 3
    			beq $t1, $t7, nextDRRow # we just continue looping to diagonal right up until we can reach either four consecutive or exhaust to top left corner
    
    			# Current position address: start + (col * 8)
    			mul $t3, $t1, $t8      # col * 8
    			add $t3, $t2, $t3      # + start address
    
    			# Load the occupation status at current position
    			lw $t4, 4($t3) # Load player value at offset +4
    			beq $t4, $zero, nextDRCol # Skip if position is empty (FREE = 0)
    
   			# Check next 3 positions diagonally for same player
    			li $t5, 1 # Counter for consecutive pieces
    			move $t6, $t4 # Remember player value
    
		diagDownRightLoop:
    			# Calculate offset to move diagonally down-right: (BOARD_WIDTH * 8) + 8
    			li $t7, BOARD_WIDTH  # Load board width
    			mul $t7, $t7, $t8 # BOARD_WIDTH * 8
    			addi $t7, $t7, 8  # + 8
    			add $t3, $t3, $t7 # Move diagonally down-right
    
    			lw $t4, 4($t3) # Load player value
    			bne $t4, $t6, nextDRCol # If not same player, try next column
    
    			addi $t5, $t5, 1 # Increment consecutive counter
    			beq $t5, 4, foundWinner # If 4 consecutive, we have a winner
    
    			j diagDownRightLoop # Continue checking
    
			nextDRCol:
    				addi $t1, $t1, 1 # Next column
    				li $t7, BOARD_WIDTH # Load board width
    				addi $t7, $t7, -3 # BOARD_WIDTH - 3
    				blt $t1, $t7, downRightColStart
    
			nextDRRow:
    				addi $t0, $t0, 1 # Next row
    				li $t7, BOARD_HEIGHT # Load board height
    				addi $t7, $t7, -3 # BOARD_HEIGHT - 3
    				blt $t0, $t7, downRightRowStart

   			# Check up-right diagonals
			checkUpRight:
    				li $t0, 3 # Start row counter (need at least 3 rows above)
			
			upRightRowStart:
    				li $t1, 0 # Start column counter
    
    				li $t7, BOARD_HEIGHT # Load board height
    				beq $t0, $t7, doneDiagonals
    
    				# Calculate start address: base + (row * BOARD_WIDTH * 8)
    				li $t7, BOARD_WIDTH # Load board width
    				mul $t2, $t0, $t7 # row * BOARD_WIDTH
    				mul $t2, $t2, $t8 # * 8
    				add $t2, $s0, $t2 # + base
    
			upRightColStart:
    				# Only check columns with enough space for diagonal
    				li $t7, BOARD_WIDTH # Load board width
    				addi $t7, $t7, -3 # BOARD_WIDTH - 3
    				beq $t1, $t7, nextURRow
    
    				# Current position address: start + (col * 8)
    				mul $t3, $t1, $t8 # col * 8
    				add $t3, $t2, $t3 # + start address
    
    				# Load status at current position
    				lw $t4, 4($t3) # Load player value at offset +4
    				beq $t4, $zero, nextURCol # Skip if position is empty (FREE = 0)
    
    				# Check next 3 positions diagonally for same player
    				li $t5, 1 # Counter for consecutive pieces
    				move $t6, $t4  # Remember player value
    
		diagUpRightLoop:
    			# Calculate offset to move diagonally up-right: (BOARD_WIDTH * 8) - 8
    			li $t7, BOARD_WIDTH # Load board width
    			mul $t7, $t7, $t8 # BOARD_WIDTH * 8
    			sub $t7, $zero, $t7 # Negate (for moving up)
    			addi $t7, $t7, 8 # + 8 (for moving right)
    			add $t3, $t3, $t7 # Move diagonally up-right
    			lw $t4, 4($t3) # Load player value
    			bne $t4, $t6, nextURCol # If not same player, try next column
        		
        		addi $t5, $t5, 1 # Increment consecutive counter
    			beq $t5, 4, foundWinner # If 4 consecutive, we have a winner
    
    			j diagUpRightLoop # Continue checking from the diagonal upward bounds --> meaning from top right to bottom left
    
		nextURCol:
    			addi $t1, $t1, 1  # Next column
    			li $t7, BOARD_WIDTH  # Load board width
    			addi $t7, $t7, -3  # BOARD_WIDTH - 3
    			blt $t1, $t7, upRightColStart

		nextURRow:
    			addi $t0, $t0, 1 # Next row
    			li $t7, BOARD_HEIGHT  # Load board height
    			blt $t0, $t7, upRightRowStart

	doneDiagonals:
    		li $v0, 0  # No winner found so we just continue on back
    		jr $ra

	foundWinner:
    		move $v0, $t6 # Return winning player (1 or 2)
    		jr $ra
