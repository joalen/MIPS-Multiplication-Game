# CS2340.003 Term Project (Multiplication Game Graphics Driver)
#
# Author: Alen Jo
# Date: 4-1-2025
# Location: UT Dallas

.include "SysCalls.asm" 

.eqv CELL_SIZE 18  # Size of each cell
.eqv CELL_SPACING 4  # Spacing between cells
.eqv BOARD_START_X 10 # Starting X position of board
.eqv BOARD_START_Y 10 # Starting Y position of board
.eqv BOARD_WIDTH 6  # Board is 6x6

.data 
	# Note, I made every attempt to make the curves perfect for some integers, but at times, it's not very good because I had to just keep modifying the right hex bits to see what sticks
	digit0: .byte 0x3E, 0x41, 0x41, 0x41, 0x41, 0x41, 0x3E # these are all the pixels that represent 0
	digit1: .byte 0x08, 0x18, 0x28, 0x08, 0x08, 0x08, 0x3E # these are all the pixels that represent 1
	digit2: .byte 0x3E, 0x41, 0x01, 0x02, 0x04, 0x10, 0x7F # these are all the pixels that represent 2
	digit3: .byte 0x3E, 0x41, 0x01, 0x0E, 0x01, 0x41, 0x3E # these are all the pixels that represent 3
	digit4: .byte 0x02, 0x06, 0x0A, 0x12, 0x7F, 0x02, 0x02 # these are all the pixels that represent 4
	digit5: .byte 0x7F, 0x40, 0x40, 0x7E, 0x01, 0x41, 0x3E # these are all the pixels that represent 5
	digit6: .byte 0x1E, 0x20, 0x40, 0x7E, 0x41, 0x41, 0x3E # these are all the pixels that represent 6
	digit7: .byte 0x7F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x10 # these are all the pixels that represent 7
	digit8: .byte 0x3E, 0x41, 0x41, 0x3E, 0x41, 0x41, 0x3E # these are all the pixels that represent 8
	digit9: .byte 0x3E, 0x41, 0x41, 0x3F, 0x01, 0x02, 0x3C # these are all the pixels that represent 9


.globl drawTheGameBoard
.text
drawBox:
    	addi $sp, $sp, -20 # storing our values into the stack so that we can retrieve them back (stack needs about five values)
    	sw $ra, 0($sp) # to go back after completing drawing the box 
        sw $s0, 4($sp) # need the x-position (this bitmap display is a simple 2D array)
        sw $s1, 8($sp) # need the y-position (this bitmap display is a simple 2D array)
        sw $s2, 12($sp) # need the color to paint this box saved as well
        sw $s3, 16($sp) # need the size of our box --> this is configurable 
        move $s0, $a0
        move $s1, $a1
        move $s2, $a2
        move $s3, $a3 

        # these sets of code make it easier to compute our $gp + newAddr => position at which we color in that bit
       	li $t8, 256 # initialize display width (the standard setting from the bitmap display thingy in MARS divided by the unit draw for a pixel)
        mul $t9, $s1, $t8 # calculate the y-position, so it's simply the y * the display width
       	add $t9, $t9, $s0 # we take our calculated y-position and essentially add the x position to obtain our pixel position 
       	mul $t9, $t9, 4 # it's now the (y * displayWidth + x) * 4 (a pixel we can think of as a word)
        add $t9, $t0, $t9 # now we append the three above calculations to then get essentially $gp + (y * displayWidth + x) * 4 = mem addr to draw at for bitmap
        li $t4, 0 # start our row counter at 0 for our loop 
looprow:
    	beq $t4, $s3, completeDrawing # when we reached our desired size, then we stop and restore our stack pointer
    	move $t6, $t9 # we copy that address we've calculated earlier in the drawBox procedure 
    	li $t5, 0 # also instantiate the column counter because we are doing like a nested for loop (a 2D array traversal essentially) 
loopcolumn: 
    	beq $t5, $s3, rowIterate # If we've completed all the columns, we can move onto (or iterate) to the next row by one pixel
    	
    	# Only draw if on the border (first/last row or first/last column)
    	beq $t4, $zero, pixeldraw # First row (top border)
    	beq $t5, $zero, pixeldraw # First column (left border)
    	addi $t7, $s3, -1 # Calculate the last position (size - 1)
    	beq $t4, $t7, pixeldraw # Last row (bottom border)
    	beq $t5, $t7, pixeldraw # Last column (right border)
    	j pixelskip # Skip drawing for interior pixels because that's where we "shade" it in

pixeldraw:
    	sw $s2, 0($t6) # Draw the border pixel
    	
pixelskip:
    	addi $t6, $t6, 4 # go to the next pixel, which again is like a word so 4
    	addi $t5, $t5, 1 # move to the next column by one (again, just like how a 2D array traversal works) 
    	j loopcolumn # go back again to loop column until we've reached the end our inner loop

rowIterate:
    	mul $t7, $t8, 4 # our stored width * 4 bytes
    	add $t9, $t9, $t7 # now we add one row worth of these bytes
    	addi $t4, $t4, 1 # increment our row counter finally
    	j looprow # now go back to the outer loop and move onwards from there, iterating to the looprow context

completeDrawing:
    	lw $ra, 0($sp) # our original return address from caller
    	lw $s0, 4($sp) # our x position (original)
        lw $s1, 8($sp) # our y position (original)
        lw $s2, 12($sp) # our color defined HEX
        lw $s3, 16($sp) # our size
        addi $sp, $sp, 20 # reset the stack-pointer back to where it was initially 
        jr $ra # return to sender

drawDigit:
	# we will need a lot of stack space because these digits are expensive and need to be drawn precisely (or at least somewhat precisely)
    	addi $sp, $sp, -24
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)
    	sw $s3, 16($sp)
    	sw $t0, 20($sp)
    
    	# Calculate digit pattern address
    	la $s0, digit0
    	mul $t6, $a3, 7      # Each digit pattern is 7 bytes
    	add $s0, $s0, $t6
    
    	# Initialize row counter
    	li $s1, 0
    
	digit_row_loop:
    		beq $s1, 7, digit_done
    		lb $t2, 0($s0) # Load byte for this row (we defined it in .data)
    		li $s2, 0 # Initialize bit position
    
	digit_col_loop:
    		beq $s2, 7, digit_next_row
    
    		# Extract bit (MSB first)
    		li $t4, 0x40 # Start with bit 6 (0x40 = 01000000)
    		srlv $t4, $t4, $s2 # Shift right by column number
    		and $t3, $t2, $t4    # Mask to get bit
    		beqz $t3, digit_skip  # Skip if bit is 0
    
    		# Calculate pixel position
    		add $t4, $a0, $s2    # x = base_x + column
    		add $t5, $a1, $s1    # y = base_y + row
    
    		# Draw pixel
    		li $t8, 256 # Width of display (hardcoded for now because I never had much time to create another constant and this was generally the safer display width option to pick)
    		mul $t9, $t5, $t8 # y * width
    		add $t9, $t9, $t4 # (y * width) + x
    		sll $t9, $t9, 2 # ((y * width) + x) * 4
    		add $t9, $t0, $t9    # $gp + (((y * width) + x) * 4)
    		sw $a2, 0($t9)       # Store color
    
	digit_skip:
    		addi $s2, $s2, 1 # Next column
    		j digit_col_loop
    
	digit_next_row:
    		addi $s0, $s0, 1 # Next byte in pattern
    		addi $s1, $s1, 1 # Next row
    		j digit_row_loop
    
	digit_done:
    		lw $ra, 0($sp)
    		lw $s0, 4($sp)
    		lw $s1, 8($sp)
    		lw $s2, 12($sp)
    		lw $s3, 16($sp)
    		lw $t0, 20($sp)
    		addi $sp, $sp, 24
    		
    		jr $ra

drawFilledBox:
	# Exactly how drawBox is but now we can fill in from the beginning to the end of all rows/columns of this box's pixels
    	addi $sp, $sp, -20  
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)
    	sw $t0, 16($sp)
    	
    	move $s0, $a0 # x position
    	move $s1, $a1 # y position
    	move $s2, $a2 # fill color
    	move $s3, $a3 # box size

    	# Calculate display position (same as in drawBox) so repeating the comments here is superflouous in nature
    	li $t8, 256  # Adjust for your display settings (512/2)
    	mul $t9, $s1, $t8
    	add $t9, $t9, $s0
    	mul $t9, $t9, 4
    	add $t9, $t0, $t9
    	li $t4, 0  # Row counter
    
	filledBoxRowLoop:
    		beq $t4, $s3, completeFilledDrawing
    		move $t6, $t9 # Copy the calculated address
    		li $t5, 0 # Column counter
    
	filledBoxColumnLoop: 
    		beq $t5, $s3, filledBoxRowIterate
		sw $s2, 0($t6) # Draw with the fill color
    
    		addi $t6, $t6, 4 # Next pixel
   		addi $t5, $t5, 1 # Next column
    		j filledBoxColumnLoop

	filledBoxRowIterate:
    		mul $t7, $t8, 4 # Display width * 4 bytes
    		add $t9, $t9, $t7 # Add one row worth of bytes
    		addi $t4, $t4, 1 # Increment row counter
    		j filledBoxRowLoop

	completeFilledDrawing:
		# now we are done with our filled box so reset the stack and go back to normal execution
    		lw $ra, 0($sp)
    		lw $s0, 4($sp)
    		lw $s1, 8($sp)
    		lw $s2, 12($sp)
    		lw $t0, 16($sp)
    		addi $sp, $sp, 20
    		jr $ra

	drawTheGameBoard:
		# Make room for 10 registers (40 bytes) because this will be very much needed for how many operations it would take to generate the board of dynamically heap made numbers
    		la $t0, 0x10010000 # Set display base address
    		addi $sp, $sp, -40       
    		sw $ra, 0($sp)
    		sw $s0, 4($sp)
    		sw $s1, 8($sp) 
    		sw $s2, 12($sp)
    		sw $s3, 16($sp)
    		sw $s4, 20($sp)
    		sw $s5, 24($sp)
    		sw $s6, 28($sp)
    		sw $s7, 32($sp)
    		sw $t0, 36($sp) # Save the base display address (which was static data instead of $gp)
    
    		move $s0, $a0  # Board address
    		li $s1, 0 # Row counter

		boardRowLoop:
    			li $s2, 0  # Column counter

		boardColLoop:
    			# Calculate cell index and address
    			mul $s3, $s1, BOARD_WIDTH
    			add $s3, $s3, $s2
    			sll $s6, $s3, 3
    			add $s7, $s0, $s6

   		 	# Load cell data
    			lw $s4, 0($s7) # Product
    			lw $s5, 4($s7) # Status
    
    			# Calculate pixel position
    			li $t7, CELL_SIZE
    			add $t7, $t7, CELL_SPACING
    
    			li $a0, BOARD_START_X
    			mul $t8, $s2, $t7
    			add $a0, $a0, $t8
    
    			li $a1, BOARD_START_Y
    			mul $t8, $s1, $t7
    			add $a1, $a1, $t8
    
    			li $a3, CELL_SIZE
    			move $a2, $t3 # Default white color
    
    			# Choose drawing based on status (wanted to add the option to let people pick whatever colors they wanted, but that's stretching the limits)
    			li $t1, 0x8F00FF # CPU (purple)
    			li $t2, 0x6AA84F # Player (green)
    			li $t3, 0xFFFFFF # Text/borders (white)
    
    			# Draw based on status
    			beq $s5, $zero, draw_empty
    			li $t9, 1
    			beq $s5, $t9, draw_player
    
    			# CPU cell
    			move $a2, $t1
    			lw $t0, 36($sp) # Load display base
    			jal drawFilledBox
    			
    			sw $t0, 36($sp) # Save display base
    			j draw_product
    
			draw_empty:
				# that would be the empty, not filled box to show it's a free space
    				move $a2, $t3
    				lw $t0, 36($sp)
    				jal drawBox
    				sw $t0, 36($sp)
    				j draw_product
    
			draw_player:
				# this would be the green shading that happens for when the PLAYER occupied the spot
    				move $a2, $t2
    				lw $t0, 36($sp)
    				jal drawFilledBox
    				sw $t0, 36($sp)
    
			draw_product:
    				# Better digit centering and being able to get not just single, but double digits (triple digits would be fantastic, but that's going deeper into the waters...)
    				move $t4, $s4 # Product value
    				li $t5, 10
    				div $t4, $t5
    				mflo $t6 # Tens place
    				mfhi $t7 # Ones place
    
    				beqz $t6, single_digit
    
   				# Double digit centering (better horizontal alignment)
    				addi $a0, $a0, 3 # X position for tens
    				addi $a1, $a1, 7 # Y position centered
    
    				move $a2, $t3 # White color
    				move $a3, $t6 # Tens digit
    				lw $t0, 36($sp)
    				
    				jal drawDigit # invoke our digit drawing system (for the tens place digit in question)
    				sw $t0, 36($sp)
    
    				addi $a0, $a0, 8 # X position for ones
    				move $a3, $t7 # Ones digit
    				lw $t0, 36($sp) 
    				
    				jal drawDigit # invoke our digit drawing system (for the ones place digit in question)
    				sw $t0, 36($sp)
    				
    				j next_cell # move onto the next box
    
single_digit:
    	# Single digit centering
    	addi $a0, $a0, 7        # Better horizontal center
    	addi $a1, $a1, 7        # Vertical center
    
    	move $a2, $t3           # White color
    	move $a3, $t7           # Ones digit
    	lw $t0, 36($sp)
    	jal drawDigit
    	sw $t0, 36($sp)
    
next_cell:
    	addi $s2, $s2, 1
    	li $t9, BOARD_WIDTH
    	blt $s2, $t9, boardColLoop
    
    	addi $s1, $s1, 1
    	blt $s1, $t9, boardRowLoop
    	
    	# Restore back the registers because that would prevent my program from crashing and running into errors like bad PCs or invalid address (which is essentially a null deref in languages like C/C++)
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	lw $s3, 16($sp)
    	lw $s4, 20($sp)
    	lw $s5, 24($sp)
    	lw $s6, 28($sp)
    	lw $s7, 32($sp)
    	lw $t0, 36($sp)
    	addi $sp, $sp, 40
    	
    	jr $ra
