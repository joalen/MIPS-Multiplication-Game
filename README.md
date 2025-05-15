# Playing the Multiplication Game

## Pre-Requisites:

1. Make sure you have your sound on! I do play sounds, although terribly made, so you might want to make sure you set the right volume. In MIPS, I hardcoded to 75% volume so don’t put your speakers on full blast
2. Make sure that for Bitmap Display (Tools > Bitmap Display) that you invoke the following settings ( **failure to do so will cause your board to be corrupted!)** :

<img width="746" alt="image" src="https://github.com/user-attachments/assets/102ce3a1-61d2-4f9d-af3c-d70ac5e0e22a" />

3. Make sure that you press **Connect to MIPS**
    a. Failure to do so will result in nothing be drawn to the screen
4. Then, make sure you **open the file at main.asm** ; never open the files for the other modules since these are not runnable and will cause errors to be thrown to console...

## Instructions:

Phew! You got that out of the way, so let’s begin playing this game :D

1. Make sure that you open up main.asm (or File > Open > <directory of where you extracted the ZIP> and click on main.asm)
2. Click either this icon <img width="50" alt="image" src="https://github.com/user-attachments/assets/700fa11c-0dc6-48ff-9743-e48cf0f06d52" />, go to Run > Assemble, or you can press F3 on your keyboard
3. In the console, you’ll see something like this...
<img width="507" alt="image" src="https://github.com/user-attachments/assets/e4e76979-f946-4acb-bea4-716434aadc5b" />

4. Now click this icon or <img width="79" alt="image" src="https://github.com/user-attachments/assets/719a7634-0072-43b5-a5bb-663329c80363" />, go to Run > Go, or you can press F
5. Now, you’ll see an empty game board like this, which means you got it to work!!

<img width="815" alt="image" src="https://github.com/user-attachments/assets/e9349d78-54cb-4056-8c41-d27ef46b28ad" />

6. Now, select your integer from 1-9 and let the game begin
    a. Of course, if you pick a 0 or a 10, this will prompt you to try again

<img width="750" alt="image" src="https://github.com/user-attachments/assets/fcd4dbcb-ed20-4d53-87e4-e6fbc2ef6030" />

7. You’ll notice that the program momentarily pauses and plays noise...that’s expected and once the noise finishes, then the game will print out status messages indicating you’ve either...
       a. Won the game!
       b. Better Luck Next Time!
       c. A draw (rarely happens but you can make it work by just typing 1-9 relentlessly)
8. Want to play again...
    a. Press the <img width="51" alt="image" src="https://github.com/user-attachments/assets/75eea8ed-4855-491e-b89d-c6504b83ce08" />, go to Run > Reset, or press F12 on your keyboard
    b. Make sure in the Bitmap Display, you press “Reset” because otherwise, it will draw over the screen and that will look wonky!!
    c. Then, repeat from step #3 onwards until you’ve been bored and are done playing


## Troubleshooting:

Oh no...you encountered issues with running the program? See some common pitfalls

1. I seemed to have run into a runtime exception with invalid input?
       a. It either means you’ve pressed enter on accident or you put in a weird non-numeric character...in that case, you’ll do the following:
             i. Press the , go to Run > Reset, or press F12 on your keyboard
             ii. Make sure in the Bitmap Display, you press “Reset” because otherwise, it will draw over the screen and that will look wonky!!
             iii. Then, follow the instruction header in this guide and go from there
2. Oh no! I accidentally assembled, ran one of the modules (i.e - soundbox.asm or drawer.asm), and have gotten an invalid return address error or PCs invalid error
       a. These modules are not runnable and are merely just procedures that are invoked by the main.asm or the caller; therefore, the PC assumes that these are runnable and tries to invoke them but in reality, they need a caller to start from. Follow the instructions header to try again



# Multiplication Game

This program does what the URL https://www.mathsisfun.com/games/multiplication-game.html does with adaptations to the MIPS pipeline and with graphics that come from the bitmap display found in MARS. This system also has a winning algorithm (that takes into respect the user’s entropy in their moves) to try to beat the player and is adaptable to allow for multiple board sizes and numbers to your heart’s content (although the multiple board size functionality is there, I would have to rechange the logic for finding a “row”, “column” or “diagonal” win like how Tic-Tac-Toe works or Connect-4, so for now, I just left it as 1-9 so that it does the minimal viable
product).

# Challenges in making this game

This program, seemingly simple in nature, is complex to implement. For one, I had to make some sacrifices for a proper winning strategy for the game by simplifying the maxmin algorithm that I thought of for the CPU so that it can win AND remove functionality to block the user from trying to win (if it could). To be fair, I thought of this as if it were a high-level language, but we are working with low-level code, so there are trade-offs made.

Initially, I tried to .include the files I needed for the modules, but I ran into issues with recursive imports (or in other words, “circular dependency”) and that came because almost all of my modules use the SysCalls.asm” .include and it basically thinks that's the circular dependency? Then, I just resorted to removing those statements and implemented the .globl function to make these procedures “global” to the MIPS environment and invoke these function runs.

Learning the graphics was a bit of a struggle at first because I had to grapple with how to actually manipulate the base address and figure out how to even get the shading to work. My first thought was to use the $gp as the base address for the Bitmap Display, but that corrupted the Run I/O and spammed unicode characters into my shell. Turns out, the $gp not only is valid for the base address of the display BUT it’s used for the entire program that MIPS uses; therefore, I resorted to a video that used the MIPS MARS Bitmap Display and he used the (static data) base address (or 0x10010000), which worked flawlessly! This also gave me inspiration to try to use the Keyboard and Display MMIO simulator that the user can have for faster gameplay as the person does for their snake game!

There was also a lot of relearning back to how procedures worked in general through the lecture slides and I kept running into errors like “jump target address beyond 26-bit buffer” (can’t exactly remember the text verbatim) and this is where I went to the CSMC. For me, the CSMC was a way for me to get a second person vantage point to help me see what’s wrong and point me in the right direction. Turns out, whenever you have global labels spread across the span of your program, externally defined procedures outside of your namespace (being the current file) makes jal fail due to it exceeding that length (about +/- 128 MBs). Therefore, I needed jalr which does 
the jal (so we jump and link address BUT we store the return address easily into our normal buffer size of 32-bits). While that error subsided, then I got another error: “invalid program counter: <hex addr>” and I also asked the CSMC. Turns out, and it took some source code evaluation between me and the tutor, but I forgot to put .text before my .globl and other procedure/MIPS entries I made and instead, ALL of it was pushed under .data which did consume a lot of labels and made them invalid. This was also where the tutor gave me some guidance on how to actually see the jump label target addresses through the MIPS menu and that worked!

# What did I learn/takeaway from this project?

Well I learned a plethora of information just based on graphics, the best base address for a display, and the heap memory! While we never covered those concepts in class, I took the liberty to try learning more about MIPS (and assembly in general) for how Linux developers make these low-level libraries that many developers use for granted. It amazes me at how much effort it takes to write graphics and even knowing the general schema behind manipulating the heap to retrieve data.

What I will say is how proud I am to even learn how the number curves worked and how I meticulously tested the MIPS program (reattaching the bitmap device each time and modifying the code) and just seeing how almost clear the numbers are (they aren’t perfect because it's hard to really notice the individual bits). I was also more proud that I got myself to figure out bordered boxes and shaded boxes to indicate that a piece was open or a piece was empty!

I also learned more about the sound system that MIPS has. Essentially, I probed around MARS to see how sound plays and I found a few resources I mentioned in more detail in the Algorithms and System Designs section. My curiosity got the best of me and I was able to implement a relatively quick asm that I named the SoundBox to deliver these noises into the game (just for the touch of interactivity I hope). These were all extremely helpful and actually simpler than the graphics interface. Anyways, Looking at these resources, it’s simple enough and I talk more about it in the Algorithms and System Design section below.

While I knew some algorithms verbatim (by some I mean a few), it was great learning the intuition behind it as MIPS instructions and it helped me critically think of ways to optimize such algorithms more and really take in the gravity of how expensive certain operations are when done in low-level compilation. I know that with most languages, such as Python, C#, or Java, they all have the liberty of runtime compilation and being able to automatically manage resources. In college, learning C++, I had to learn dynamic and static memory allocations and that was furthered just through this course alone to see how that plays through hardware abstraction. In fact, many of the errors I experienced are common pitfalls that you’d see in C++ programming (although not thrown by compilers; mainly through analysis tools in general - like dynamic code analysis tools ← Google Sanitizers and such). Things like, invalid address or invalid PC are all things like Buffer Overflows, Null Dereferencing (usually if you see 0x000000)

# Algorithm and System Design

## Graphics Algorithms

**Note that the width set is 256 since that is the value to properly draw the “sprites” onto the bitmap display; therefore, any mention of the width, will refer to this 256 value**

For MIPS, I found this website https://mcs.utm.utoronto.ca/~258/doodlejump.html that does a similar concept in creating a doodle jump game and from there, I learned we can use the Bitmap Simulator to “sketch” out our data. How this Bitmap generation works is we think of this Bitmap screen as an array and in that array, we fill in values.

These graphics algorithms are again modular in nature so that in my other codes, I can invoke these functions to have any size for the game and be able to draw the board easily.

The article mentioned I needed a particular address to act as the base address for the bitmap display to be invoked in. Here, the global pointer is the more appropriate register since in lectures, I’ve learned that the global pointer is mainly used for the heap and dynamic allocation of storage as opposed to using the registers through static means. Perfect! In the Bitmap Simulator, you can see how I can set the base address for display. Additionally, I wanted to make sure that the user can see the boxes clearly, so here I set the unit width and height in pixels to be 2 with our display width set at 512x512 so that we can generate a large enough screen to be interactive

### Draw Box

Initially, I wanted to get the box drawn on the screen and my approach to doing that was the following:

1. For sure use the stack to store our values so that we can bring it on back to the main
    function .text
       a. Allocate 5 spots in the stack (so -20)
       b. Then store the following: return address (so we can return back to the main
          program – don’t want an infinite loop!), x and y positions on our bitmap screen,
          then the color we’d like our box to be (from the URL above which is web HEX
          HTML specification), and then the size of our box.
       c. Move my arguments – x, y, color, and size into the stack registers → from there
          we do this math to calculate the appropriate address
             i. y_pos * display_width → new y-position
ii. x_pos + (i) → pixel position
iii. (ii) * 4 → addend to the global pointer
iv. $gp + (iii) → new base address to invoke in the Bitmap display that acts
as the next position after draw
d. Then, we do our loop logic to draw this box, which reminds me of a 2D array
i. Start with our iteration for the row at 0 and then iterate through the
columns, which will draw our border-box!

1. This is important because I don’t want the box filled in just yet and need to make sure I get the four corners and that the first and last rows/columns are the only one’s filled
       a. How do I prevent filling in the other pixels? I invoke a pixelskip function that moves to the next pixel and moves to the next column by +1, which will return back unconditionally to the loop column function

The result of the above

<img width="622" alt="image" src="https://github.com/user-attachments/assets/eee79ef6-4f28-4799-bcd7-f6e3d3d9c9bd" />

### Draw Integer

Awesome! We got a box and now we want a digit in the box like the game showed. Therefore, I created a drawDigit function that essentially works like this...

1. Invoke all the curvature bits so that we can “draw” the digits on the screen (this step was
    perhaps frustrating because I had to modify each of these bytes one at a time until I got
    the proper numbers, which finally worked out – although they aren’t perfect)
```
digit0:. **byte** 0x3E, 0x41, 0x41, 0x41, 0x41, 0x41, 0x3E # these are
all the pixels that represent 0
digit1:. **byte** 0x08, 0x18, 0x28, 0x08, 0x08, 0x08, 0x3E # these are
all the pixels that represent 1
digit2:. **byte** 0x3E, 0x41, 0x01, 0x02, 0x04, 0x10, 0x7F # these are
all the pixels that represent 2
digit3:. **byte** 0x3E, 0x41, 0x01, 0x0E, 0x01, 0x41, 0x3E # these are
all the pixels that represent 3
digit4:. **byte** 0x02, 0x06, 0x0A, 0x12, 0x7F, 0x02, 0x02 # these are
all the pixels that represent 4
digit5:. **byte** 0x7F, 0x40, 0x40, 0x7E, 0x01, 0x41, 0x3E # these are
all the pixels that represent 5
digit6:. **byte** 0x1E, 0x20, 0x40, 0x7E, 0x41, 0x41, 0x3E # these are
all the pixels that represent 6
digit7:. **byte** 0x7F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x10 # these are
all the pixels that represent 7
digit8:. **byte** 0x3E, 0x41, 0x41, 0x3E, 0x41, 0x41, 0x3E # these are
all the pixels that represent 8
digit9:. **byte** 0x3E, 0x41, 0x41, 0x3F, 0x01, 0x02, 0x3C # these are
all the pixels that represent 9
```

2. Like the drawBox, we need five spaces in the stack (so 20 once again to move the stack pointer) and from there we calculate the base address to load into our global pointer
       a. This would again start with digit 0 and then from there, we multiply * 7 bytes to create our offset for this digit to properly bound to the box
       b. Then, we invoke our 2D array logic → loop the row and loop the column (like mentioned when I did the drawBox logic)
             i. However, with this, I made newer logic due to how we have those bytes that represent the “curves” of each of the numbers – my inspiration was for a “bit-game” like font

ii. In the digit_row_loop function, it’s essentially loading in the byte and initializing our column counter to proceed with drawing the number
iii. In the digit_col_loop, now we are able to draw the number
1. We do this by making sure we initiate 7 bits (cause I allocated all
seven bits of the curve of these numbers)
2. Then, we reverse the bit position (so we can make it a
seven-column bit)
3. Then we variable shift logic rightwards of our reversed bit position
4. From our lecture on what binary AND does, I can mask bits so that
I can fill in parts of the curve of the integer
5. This is where I can then safely assume that a zero bit is a pixel skip
       c. We need to calculate the x,y position of where we are in drawing our integer (this is what allows us to “traverse” the curve of these integers)...
             i. X position will be the base address x + the column
ii. Y position will be the base address y + the row
       d. Then, it’s back to creating our base address to append to, which refers back to how the draw box worked!


This is the end result of that + the draw box

<img width="620" alt="image" src="https://github.com/user-attachments/assets/0d3f2b3d-91fe-4959-9c15-4384e3ca6ded" />

### Fill-in box

Okay, now like in the game, we need to mark the boxes we’ve seen (and the computer sees) to clearly indicate to the user that the box is used and is an illegal move to play. This works generally as a normal 2D array traversal function as opposed to drawing a bordered box – which required doing only the first and last rows/columns

1. Same thing, set 5 spaces for our stack for the same arguments that draw box and draw integers had
2. Same calculating of the display position (for the x and y’s)
3. Then, finally, create the custom filledBox row and column loops
    a. This is normal iteration from first to last of the row and column

Of course, then I had to make another procedure to draw the grid based on the influence of the heap memory. The heap memory, essentially works out like this:

1. All of the “odd spots” or +0, +8, +10, +18 represent the products
2. All of the “even spots” or +4, +c, +14, +1c represent the fields for the following...
    a. 0 = FREE
    b. 1 = PLAYER
    c. 2 = CPU

Here’s a visual to help you understand...

<img width="527" alt="image" src="https://github.com/user-attachments/assets/44cd6028-addd-43cb-905b-45d01f74b462" />


Now, if you create the generateBoard functionality based on what the heap map looks like, then it will turn out to be like this!

<img width="625" alt="image" src="https://github.com/user-attachments/assets/ac6953e7-401a-4827-881a-c8a7aeb1f55f" />

_You might also be wondering why I started to use the base address as static data as opposed to the previous $gp? Well, I ran into issues with $gp corrupting my run I/O in MIPS and showing
unicode characters. Therefore, I went back to some of the resources I used and found out that most Bitmap generations will just borrow the static data base address and we leave the others
alone_

Video that helped with the $gp issue: https://www.youtube.com/watch?v=CdctMQjk3JI
● I had the bright idea to use the keyboard from that video to let the user easily input the numbers, but that required knowing how to add interrupts to the program (next lecture may teach us that??) and that would defeat the purpose of move validation so my original approach suffices for now

## Board Generation

For the board, although I could do the standard range of 1-9 integers to create products from 1-81, I wanted to add modularity to this game by allowing the user to have free-will in picking any range from the min that’s greater than or equal to one and max that is greater than or equal to two. Yeah, unfortunately, I did not gauge time properly and this feature will not be included due to such time constraints; I will stick with the regular 1-9 like the multiplication game had...

For me to transfer this board across the lifecycle of the program, I would need to use the Heap Memory, which would allow me to retrieve an address that points to this. Unlike C/C++, I don’t necessarily need to free the heap memory after using it (where I do use a temp array that I could free by passing in a negative value to the heap to shrink it down). However, that’s not necessary and could be unnecessary complexity added on top of that. Therefore, I’ll just allocate to the heap memory instead of doing both allocation and deallocation.

The pipeline for setting up the board generation boils down to this:

1. Generate the possible products and count the factor pairs necessary
2. Then, we sort products by their value (like how the game does it)
    a. Initially, I used Bubble Sort, but that was sooo slow on MARS that I just went to
       insertion sort!
3. Fill the board next with the top BOARD_SIZE (which I set to theoretically be 100 unique products that we can obtain from this multiplication game) products
4. Then, we create the valueMap of all the products → more important for the CPU playing the game since it does need to know how to win and that comes from the “weights” of these products that the CPU strategically can place

## The Game Logic - CPU Winner Algorithm

When I played the game, when I selected a number, it seemed to me to be arbitrary. The CPU plays a different move each time and tries not to combat me until I’m nearing four in a row, column, or diagonal. This arbitrary motion comes from numbers 1 to 9 as a row and the computer picks the first multiplicand while I pick the second multiplicand (or vice versa).

This sort of randomness for me means one of two thing:

1. I need a way to generate a random number each time to make the game more fluid and not completely deterministic in its pattern
       a. Create a PRNG implementation (use perhaps Linear Congruence Generator
          Algorithm)
       b. Use the SysCalls’s SysRandInt ✓
2. I also need to implement a sort of winning CPU strategy to “attempt” winning the game
    a. I initially wanted to do a Greedy Algorithm system that did Memoization and Backtracking _on the fly_ → (see: https://www.geeksforgeeks.org/minimax-algorithm-in-game-theory-set-1-introduction/) proved to be cumbersome and very hard to understand for so I just resorted to letting the CPU do the following below

### Winning Algorithm in MIPS

So for the winning algorithm motivation, I made it to where it should _ideally_ find consecutive spots made by the CPU (which again comes from the heap-generated board) and in there, the CPU has to decide what number to return. Initially, I thought of, again, using the minimax algorithm with some Alpha-Beta Pruning optimizations in place to make it “super smart” in playing the game, but programming it took a while and it was falling apart when I ran it in runtime. In other words, infinite loops and illegal word boundaries and bad PC errors...don’t want to deal with that mess.

Okay fine, then let’s just make it to where it will work based on these conditions:

1. Whenever we see that we have consecutive spots taken by CPU for either a row, column, or diagonal, the CPU will be inclined to pick that move based on the input of the user (made that as a precondition to influence this winning algorithm)
2. Attempt to “block” the user from winning the game because that makes the game harder for us to win, and would force us to be smart in how we can win the game

General steps I took to make the findCPUMove algo:

1. Invoke the initCPUMove procedure that just generates any number from 1-9 (yeah the valueMap would’ve been useful, but harder to maintain the heap and was going to confuse my board generation program)
2. Then, it just “tries” the move and see if it works. If invalid, it will undo the move that it made temporarily and try another.
       a. If all else fails, then, we just “go with the flow” and pick our random number → “life ain’t fair sometimes”
3. As for blocking the user, this happens when we can see that they are about to win (usually if it’s closer to consecutive matching in the row, diagonal, or column) and in that sense...it will prevent us from taking that one spot to win the game ← sometimes it may not always happen and depends on how serious you play the game.
       a. This works by essentially “mocking” the USER move and seeing if the user wins. If so, that move is the “blocker” and will be applied as the multiplicand returned by findCPUMove. Like the winning move, you can revert this move also and just “go with the flow”
4. For the last resort, just put 1 by default because we somehow “blew” through all the conditions of the above

## The Sound Generation

Sound generation, surprisingly, was the easiest component of this project compared to even the graphics or the actual game itself. Therefore, these were some of the resources I stumbled upon as I looked for ways to emulate noise in the MARS simulator:
● https://stackoverflow.com/questions/19754324/mips-playing-beep-sound
● https://github.com/dylanmtaylor/mars-audio/blob/master/AudioPlay.asm
● https://github.com/TheCodeOfLife/Midi-in-Mips/blob/master/Midi-in-Mips.asm
● https://weinman.cs.grinnell.edu/courses/CSC211/2020F/labs/mips-basics/

The general rundown of sound generation:
1. First, you define the MIDI version 1.0 specification of “note numbers” that correspond to what I believe are piano keys on a piano keyboard and those plays the noises for each of the notes → almost like those 8-bit arcade noise machines


2. Of course, this wouldn’t be without a challenge since you can’t import a regular “.mp3” or “.wav” file into your MARS project and just run it as such. Rather, you’d need to first decompose your preferred audio into MIDI format that then gives you the numbers you’re looking for
3. From there, I had the Audacity application that helped me analyze the Spectrogram for the different pitches and adjusted it accordingly to the best of my ability. I also trimmed out not needed noises that could ruin the MIDI analysis algorithm that the audio-to-midi website below would do.
4. Best website for MIDI extraction? → https://samplab.com/audio-to-midi (this will give you a .mid file that you can download to your machine)
5. Then, I found an article by Twillo that described how you can use Python to extract MIDI information (and to that, that’s a file parser, which is easy to understand and create a short script for). Learn more here: https://www.twilio.com/en-us/blog/working-with-midi-data-in-python-using-mido
6. From there, all I had to do was open up the Python interpreter and run each of these Python lines individually. Of course, you could make a Python file and run it, but for any “scratchwork” I use the python shell for just easy testing
```
**>>>** mid = mido.MidiFile("/Users/alenjo/Downloads/drawGameSound_Skribb.mid")
**>>> for** i, track **in** enumerate(mid.tracks):
**...** print(f'Track {i}: {track.name}')
**...** time = 0
**... for** msg **in** track:
**...** time += msg.time
**... if** msg.type == 'note_on' **and** msg.velocity > 0:
**...** print(f"Note: {msg.note}, Time: {time}")
**...**
Track 0:
Note: 41, Time: 23
Note: 53, Time: 23
Note: 48, Time: 253
Note: 36, Time: 276
```

As you can see, we have something! We’ve not only gotten the MIDI note number we need for MIPS, but we also have the timestamp that each of these notes occur and the latter is important
for it to really play (although my implementation was a bit wonky...)

7. Now, from the fourth link in the list, this is where I learned about the SysCall for MIDI noise generation in MIPS and that boils down to simply 33...would’ve been easier if there was a SysCalls for this, but I guess not (perhaps maybe different systems may not have this?)
8. Then, all I had to do was define an array (or .word in MIPS) that is the numbers you see for note and a .word for the timestamps and then simple start the address at zero of the word and loop until we reach a “-1”
       a. I made a “-1” since that’s the indicator of stopping the array and didn’t really feel like programming the logic to check for the end of the array with pointer arithmetic and such
              i. Also, “-1” was not a valid MIDI note so I could use this safely

9. To make abstraction possible in the soundbox.asm file, I made one dispatcher procedure that allows any of the .asm files within the same directory to just invoke the soundLibrary procedure to then select the appropriate noise to play based on the value received in the argument (1 = game over, 2 = winner, 3 = draw)
       a. I was going to implement noises for wrong moves and valid moves, but that proved to “hang” my program and that was a bit too much given the constraints

For the noise inspirations for the winning and losing soundtracks...I looked toward a funny compilation of Mario Kart losing soundtracks: https://www.youtube.com/watch?v=R-rouC_sd5Y

For the noise inspirations for the draw sound...I took the inspiration of Skribble.io sounds and picked the time’s up noise since that felt most appropriate: https://youtu.be/KQzjb1Pz8uE?si=acNCGuYiU-oHtZSi

Phew! That was a long explanation for a seemingly simple topic! Also, on a side note, the sounds don’t play really well because I’m not good with MIDI nor with variable adjustment of noises (to that I say is a sacrifice I’m willing to make for making this happen in MIPS alone)

## The Move Validations

This submodule (or procedure shall I say) is where we are tasked with figuring out the following
conditions...

1. The range must be between 1-9 (so blt 1 or bgt 9 == bad)
2. We cannot occupy an already occupied spot (easy enough with the heap map I showed you for the graphics algorithm. To remind you, we check for spots at offsets → +4, +c, +14, +1c)

Therefore, we can make MIPS procedures that prance around this functionality and essentially answers the two constraints above. In my MIPS procedure, I made it to where we essentially return a negative -1 to indicate that the move is invalid; simple as that.

## The Winning Moves

So how do we determine how to win the game? In the multiplication game, we had to either...
(a) Get four in a row
(b) Get four in a column
(c) Get four in a diagonal

In other words, Connect 4 style rules. Therefore, for the row functionality...

1. Loops through all the rows in the 2D matrix in our heap and again...looking at the offsets I gave you +4, +c, +14, +1c, and seeing if those are consecutive in nature by horizontal alignment
       a. I commented most of my code to show this and can really explain what I’m trying to say – lot of it is kept with brevity in mind due to programming and thinking through the right MIPS instructions to grab and seeing what sticks and solidifying those codes together

For the column functionality...

1. Same thing like the rows, EXCEPT we are now checking for vertical consecutiveness in the heap map for the offsets seen earlier.
       a. Again, I commented on most of my code to show this functionality

For the diagonal functionality...

1. This is really challenging and honestly took me about a solid one-two hours to figure out how to check for this. Really...it was more about top left→bottom right diagonality and top right→ bottom left diagonality
2. Here’s how this works (this is general and not as descriptive mainly because the comments should somewhat explain everything)...
       a. Check just the rows that allow us to have enough space for the diagonal for bottom-right starts
             i. Take the downRightColumnStart (or upRightColumnStart) and essentially loop until we’ve reached the top-left or bottom-left. Again...we are only checking for spots that are taken consecutively by the player or the CPU

## The Game Loop

The game loop comes from first letting the CPU pick the multiplicand first as seen in the multiplication game, and then we ask the user to pick the multiplicand from 1-9, and then we flip to the CPU to pick the move. All of this means that the second player who went gets their product highlighted on the board.

However, we also want input validation to make sure the user typed the correct integer range. For this, we invoke the SysReadInt (SysReadString would’ve been more appropriate for checking non-numeric characters, but to that, I would need to invoke a buffer, then watching for the \n character and that was going to be messy real quick in typecasting that finally to an integer...I laid out troubleshooting steps for this so you can quickly get back to the game)

Back to the input validation, we essentially check for range 1-9, which means blt 1 and bgt 9 so that we can see if the user accidentally enters let’s say a 10 or a 0 or even a negative value too. This prompts the user to try again and then the game continues without interruption.

If all went well with input validation and the CPU picked the move, then we multiplied the two multiplicands to form our product and then we moved to a procedure to mark this on the gameBoard. That will invoke a validMove procedure to check if we occupied this space already and returns a -1 if occupied, meaning that move was invalid.

If the move was valid, then can we safely mark that on the board provided that we have our base address for the display, the product in question, and who invoked the product (so the second player to have went). That will then mark the appropriate color; remember, green = the player and purple = the CPU (like how it is in the multiplication game to alleviate some confusion in the color schemes).

The game will finally end the game loop whenever we encounter a nonzero integer for the game state, meaning that there was a win/loss/draw. This is passed to the checkWin functionality in the boardgeneration.asm that checks for consecutive row, column, or diagonal and that will promptly end the game and print the final message. Afterwards, we safely shutdown the MIPS program with our SysExit.
