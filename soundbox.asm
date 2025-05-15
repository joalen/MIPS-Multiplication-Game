# CS2340.003 Term Project (Multiplication Game -- SoundBox)
#
# Author: Alen Jo
# Date: 4-29-2025
# Location: UT Dallas

.data 	
	# Game over sound effect -- inspired by the SNES Mario Kart series "loosing" soundtrack
	gameOverSoundMIDI: .word 48, 72, 65, 68, 71, 47, 72, 65, 46, 68, 44, 60, 55, 43, 67, -1
	gameOverSoundTimeStamps: .word 0, 96, 288, 288, 288, 512, 672, 768, 992, 1280, 1472, 1504, 1536, 1728, 1760
	
	# Winner sound effect -- inspired by Mario Kart 8's "loosing" soundtrack, which in reality, was more of the sound for just winning
	winnerSoundMIDI: .word 65, 58, 70, 77, 72, 70, 34, 58, 60, 77, 34, 53, 58, 75, 72, 34, 46, 70, 24, 37, 65, 68, 75, 65, 77, 80, 49, 65, 25, 77, 80, 65, 70, 82, 39, 67, 68, 75, 80, 58, 63, 67, 70, 53, 60, 77, 65, 77, 24, 77, 24, -1
	winnerSoundTimeStamps: .word 162, 203, 203, 203, 284, 407, 529, 529, 529, 529, 895, 895, 895, 895, 1139, 1221, 1261, 1383, 1628, 1831, 1831, 1872, 1913, 1994, 2035, 2075, 2320, 2320, 2564, 2564, 2564, 2808, 2808, 2808, 3052, 3052, 3052, 3052, 3052, 3419, 3419, 3419, 3419, 3744, 3744, 3744, 3785, 4965, 5047, 5210, 5250
	
	# Draw sound effect -- this one I remembered from playing a Skribbl.io game with a few friends and there was the times up effect, so that's where this came from
	drawSoundMIDI: .word 41, 53, 48, 36, -1  
	drawSoundTimeStamps: .word 0, 32, 23, 253, 276
	
.text
.globl soundEffectLibrary

soundEffectLibrary:
    	addi $sp, $sp, -8  # Allocate stack space for two words          
    	sw $ra, 0($sp) # need the return addr
    	sw $a0, 4($sp) # Need the choice option
                
    	beq $a0, 1, winnerSoundCase # Case 1: Winner (you've set the option to one)     
    	beq $a0, 2, gameOverSoundCase # Case 2: Game Over (you've set the option to tw0)           
    	beq $a0, 3, drawSoundCase  # Case 3: Draw (you've set the option to three)         

    	j stopAudioLib # Default fallback case if invalid ID

	# Lot of this is like the switch/case statement and is particularly understandable since this is just single values I'm checking for as opposed to a complex conditional logic
	
	# Case 1: Winner Sound
	winnerSoundCase:
    		la $a0, winnerSoundMIDI
    		la $a1, winnerSoundTimeStamps
    		jal playSound
    		j stopAudioLib

	# Case 2: Game Over Sound
	gameOverSoundCase:
    		la $a0, gameOverSoundMIDI
    		la $a1, gameOverSoundTimeStamps
    		jal playSound
    		j stopAudioLib

	# Case 3: Draw Sound
	drawSoundCase:
    		la $a0, drawSoundMIDI
    		la $a1, drawSoundTimeStamps
    		jal playSound
    		j stopAudioLib

	# End of soundEffectLibrary
	stopAudioLib:
    		lw $ra, 0($sp)
    		lw $a0, 4($sp) # Restore a0
    		addi $sp, $sp, 8 # Adjust stack by 8 (not 4)
    		jr $ra


playSound:
    	# need the stack to obtain things like the MIDI .word array and the timestamps so that I can "attempt" to play the proper noises in a proper syncing
    	addi $sp, $sp, -16
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)

    	move $s0, $a0 # MIDI notes array
    	move $s1, $a1 # timestamps array
    	li $s2, 0 # current index

	loop_notes:
    		# Calculate current note address
    		sll $t9, $s2, 2 # index * 4 (word size)
    		add $t9, $s0, $t9 # base address + offset
    		lw $t0, 0($t9) # notes[index]
    
    		li $t1, -1 # Check for end marker
    		beq $t0, $t1, end_playSound # Exit if end of array

    		# Calculate timestamp addresses
    		sll $t9, $s2, 2 # index * 4 (had to make sure that jalr didn't corrupt this...)
    		add $t9, $s1, $t9 # timestamp base + offset (had to make sure that jalr didn't corrupt this...)
    		lw $t2, 0($t9) # the time[index]
    
    		# Goto next timestamp and MIDI
    		addi $t8, $s2, 1 # index + 1
    		sll $t8, $t8, 2 # (index + 1) * 4
    		add $t8, $s1, $t8 # address of next timestamp
    		lw $t3, 0($t8) # time[index+1] <-- move to the next timestamp
    
    		sub $t4, $t3, $t2 # duration of how long to play each note

    		# Play the note
    		li $v0, 33 # MIDI syscall
   		move $a0, $t0 # MIDI note
    		move $a1, $t4 # Duration
    		li $a2, 0 # Instrument of choice (I believe this is Grand Piano, but I don't honestly have a list of these instruments...)
    		li $a3, 75 # Volume (default to that because it's loud enough...)
    		syscall

    		# Move to next note
    		addi $s2, $s2, 1  # Increment index
    		j loop_notes

	end_playSound:
    		lw $ra, 0($sp)
    		lw $s0, 4($sp)
    		lw $s1, 8($sp)
    		lw $s2, 12($sp)
    		addi $sp, $sp, 16

    		
    		jr $ra # Returning back to main