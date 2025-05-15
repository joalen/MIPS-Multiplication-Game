# CS2340.003 Term Project (Multiplication Game -- Optimized Board Generator)
#
# Author: Alen Jo
# Date: 4-26-2025
# Location: UT Dallas

.include "SysCalls.asm"

.eqv BOARD_SIZE 36 # 6x6 board
.eqv MAX_PRODUCTS 81 # upto 81 products possible as seen in the original multiplication game

# these are the bits that define the "fields" prop for each of the product locations (I described it as sort of the "even" offsets of the addrs)
.eqv FREE 0
.eqv PLAYER 1
.eqv CPU 2

.text
.globl creategameboard

creategameboard:
	addi $sp, $sp, -16
	sw $ra, 0($sp) 
	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)
    
    	li $s0, 1 # Min factor
    	li $s1, 9 # Max factor

    	# Generating the board that the user and CPU will play in their session
    	li $v0, SysAlloc
    	li $a0, BOARD_SIZE
    	sll $a0, $a0, 3
    	syscall
    	
    	move $s2, $v0 # obtain the base address that starts the board position

    	move $a0, $s0
    	move $a1, $s1
    	move $a2, $s2
    	jal generateBoard # now we can proceed to fill the heap with our products + the fields to track and place the values in

    	move $v0, $s2 # Return board address

    	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	
    	addi $sp, $sp, 16
	jr $ra

generateBoard:
    	addi $sp, $sp, -20
    	sw $ra, 0($sp)
    	sw $s0, 4($sp) # min factor (start index)
    	sw $s1, 8($sp) # max factor (end index)
    	sw $s2, 12($sp) # board address
    	sw $s4, 16($sp) # product count
    
    	move $s0, $a0 # Min factor
    	move $s1, $a1 # Max factor
    	move $s2, $a2 # Board address
    	li $s4, 0 # Product count

    	# Allocate & initialize temp array
    	li $v0, SysAlloc
    	li $a0, MAX_PRODUCTS
    	sll $a0, $a0, 3
    	syscall
    	move $t9, $v0

    	# Zero the array, this is more important for the sorting algorithm of choice I implemented -- insertion sort
    	move $t0, $t9
    	li $t1, MAX_PRODUCTS
    	
	initArray:
    		sw $zero, 0($t0)
    		sw $zero, 4($t0)
    		addi $t0, $t0, 8
    		addi $t1, $t1, -1
    		bnez $t1, initArray

    		move $t0, $s0 # Generate the products for each location
		outerLoop:
    			bgt $t0, $s1, genDone # completed the board generation
    			move $t1, $t0 # Start j at i to avoid duplicates
		
		innerLoop:
    			bgt $t1, $s1, nextOuter # go back out to the outer loop
    			mul $t2, $t0, $t1 # Product
    
    			# Inline product searching --> found to be more faster, although took me a second to really figure out this mess
    			move $t3, $t9 # pointing to the product storage arr
    			li $t4, 0 # product index is set to zero for me to count the products
			
			# we proceed to search for all the products and add/increment each of them
			searchProduct:
    				lw $t5, 0($t3) # loading the product values 
    				beqz $t5, addProduct # not found product? go add the product
    				beq $t5, $t2, incProduct # increment the count if we've seen product before
    				addi $t3, $t3, 8 # go to next position of base addr --> remember, we skip +4 because that's our field attrib
    				addi $t4, $t4, 1 # incrementing the product index by one
    
    				# need to prevent going over the upper-bound of MAX_PRODUCTS because we know it would go on forever!!
    				li $t6, MAX_PRODUCTS # maximum products --> helpful for when we want to change the max product to accept the max index * max index for dnynamic board generation
    				bge $t4, $t6, addProduct # not product? add it...
    				j searchProduct # continue to search for the desirable products
    
				addProduct:
    					sw $t2, 0($t3)
    					li $t5, 1
    					sw $t5, 4($t3)
    					addi $s4, $s4, 1
    					j nextProduct
    
				incProduct:
    					lw $t5, 4($t3)
    					addi $t5, $t5, 1
    					sw $t5, 4($t3)
    
			nextProduct:
    				addi $t1, $t1, 1
    				j innerLoop
    
			nextOuter:
    				addi $t0, $t0, 1
    				j outerLoop

	genDone:
    		# Sorting the products by their value through insertion sort since this is faster algo
    		move $t0, $t9
    		li $t1, 1
	sortLoop:
	
    		sll $t2, $t1, 3
    		add $t2, $t0, $t2
    		lw $t3, 0($t2)
    		beqz $t3, sortDone
    		lw $t4, 4($t2)
    
    		move $t5, $t1
	
	insertLoop:
    		beqz $t5, nextSort
    
    		addi $t6, $t5, -1
    		sll $t7, $t6, 3
    		add $t7, $t0, $t7
    		lw $t8, 0($t7) # Load product value instead of count
    
    		bge $t3, $t8, nextSort # Compare product values (changed from count comparison)
    
    		# Shift element
    		lw $t8, 0($t7)
    		lw $s5, 4($t7)
    
    		sll $s6, $t5, 3
    		add $s6, $t0, $s6
    
    		sw $t8, 0($s6)
    		sw $s5, 4($s6)
    
    		addi $t5, $t5, -1
    		j insertLoop
    
	nextSort:
    		sll $t7, $t5, 3
    		add $t7, $t0, $t7
    
    		sw $t3, 0($t7)
    		sw $t4, 4($t7)
    
    		addi $t1, $t1, 1
    		j sortLoop
    
	sortDone:
    		# Now we can start to traverse and reorganize our heap structure with the sorted values
    		move $t0, $t9
    		move $t1, $s2
    		li $t2, 0
    
fillLoop:	
    	beq $t2, BOARD_SIZE, fillEnd
    
    	sll $t3, $t2, 3
    	add $t3, $t0, $t3
    	lw $t4, 0($t3)
 
    	sll $t5, $t2, 3
    	add $t5, $t1, $t5

    	beqz $t4, fillOne

    	sw $t4, 0($t5)
    	sw $zero, 4($t5)
    	addi $t2, $t2, 1
    	j fillLoop

	fillOne:
    		li $t4, 1
    		sw $t4, 0($t5)
    		sw $zero, 4($t5)
    		addi $t2, $t2, 1
    		j fillLoop

	fillEnd:
    		# Restore registers and return back to main
    		lw $ra, 0($sp)
    		lw $s0, 4($sp)
    		lw $s1, 8($sp)
    		lw $s2, 12($sp)
    		lw $s4, 16($sp)
    		addi $sp, $sp, 20
    		
    		jr $ra
