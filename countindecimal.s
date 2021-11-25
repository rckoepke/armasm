//
// Assembler program to count up to a 32-bit number in decimal.
//
// X0-X2 - parameters to linux function services
// X1 - pointer to the address of string byte we are manipulating/reading/outputting
// X16 - linux syscall function number

// X6/W6 - counter to print, is actually character (starts at decimal value 48)
// X7/W7 - an offset which keeps track of which digit we are currently manipulating during "carry-the-one" operations
// X3 - used for determining offset based on number of non-leading zero digits currently being used
// X4 - used to keep track of how many non-leading-zero digits there are
// X5 - keeps track of where the carry counter currently is.


.global _main                   // Provide program starting address
.p2align 2

.equ STRING_LENGTH, 10 // set this to one less than the maximum number of digits in placemarker
// e.g.
// placemarker: .ascii  "000\n"
// .equ STRING_LENGTH, 2

.equ COUNT_TO_A, 0x614E // lowest 4 hex digits of number to count to
.equ COUNT_TO_B, 0xBC
.equ COUNT_TO_C, 0x0000
.equ COUNT_TO_D, 0x0000 // most significant bits

_main:
adrp    X1, placemarker@PAGE // see first example
add     X1, X1, placemarker@PAGEOFF // see first example, initialize X1
ADD     X1, X1, #STRING_LENGTH // this indicates we have a 5-digit string available
MOV     W6, '0' // initialize the counter to the character '0' (not numerical value zero)
MOV     X0, #1 // initialize the file descriptor, 1 = StdOut
MOV     X2, #STRING_LENGTH // initialize the string length for write()
MOV     X3, #STRING_LENGTH // initialize the string length (this time not including leading zeroes)
MOV     X4, #0 // used to keep track of how many non-leading-zero digits there are
MOV     X5, #0 // keeps track of where the carry counter currently is.
MOV     X7, #0 // initialize the digit offset counter used for carries

MOV     X8, #COUNT_TO_A // this adds "A" to X8
MOVK    X8, #COUNT_TO_B, LSL #16 // this adds "B", multiplied by 65536, to X8
//MOVK    X8, #COUNT_TO_C, LSL #32 // Commented out because this is too slow
//MOVK    X8, #COUNT_TO_D, LSL #48 // Commented out because this is too slow

loop:
SUBS     X8, X8, #1 // i--;
B.MI  exit // if we've reduced X8 to zero, we've completed the task and we can exit
BL      increment // add one to the string
// BL      print // comment out this line to greatly speed up operation
B loop // most of the time, just add one to the string again.

exit:
BL      print // print the new number
MOV     X0, #0      // Use 0 as our return code, indicating no errors.
MOV     X16, #1
SVC     #0x80           // Call kernel to terminate the program

print: // this prints the current value of the string that X1 points to
ADRP    X1, placemarker@PAGE // start of hex template string address - doesn't matter what's in here, but for formatting/human reading should end with \n
ADD     X1, X1, placemarker@PAGEOFF // rest of string address (12-bit offset), see
# https://stackoverflow.com/questions/41906688/
# https://reverseengineering.stackexchange.com/questions/14385/
ADD     X1, X1, X3
MOV     X0, #1 // File Descriptor, tells syscall where to write to. 1 = StdOut
mov     X2, #15 //X3 // Tells syscall what length of buffer to expect/write out.
mov     X16, #4 // Tells syscall to call "write". See list of syscalls here: https://opensource.apple.com/source/xnu/xnu-7195.81.3/bsd/kern/syscalls.master.auto.html
svc     #0x80 // tells MacOSX to go ahead and run the syscall using X0, X1, X2, and X16 (specific purpose of X0, X1, and X2 is dictated by the value of X16)
ADRP    X1, placemarker@PAGE // start of hex template string address - doesn't matter what's in here, but for formatting/human reading should end with \n
ADD     X1, X1, placemarker@PAGEOFF // rest of string address (12-bit offset), see
ADD     X1, X1, #STRING_LENGTH
ret

increment:
CMP     W6, '9' // check if W6 is maxed out and we need to carry the one
B.EQ    decimalcarry // carries the one
ADD     X6, X6, #1 // increment W6 by 1
STRB    W6, [X1] // store the contents of the least significant byte of W6 into the address pointed to by X1
ret

decimalcarry:
ADD     X5, X5, #1 // increment the number of digits to print out for pretty printing
MOV     W6, '0' // Increment W6.
STRB    W6, [X1, X7] // store the contents of the least significant byte of W6 into the address pointed to by... X1, but shifted to the left by the magnitude of X7.
SUB     X7, X7, #1 // decrement X7
LDRB    W6, [X1, X7] // read the next digit in X1 (offset by X7), then store it into W6.
CMP     W6, '9' // check if this next digit needs to also "carry-the-one"
B.EQ    decimalcarry // keep carrying ones until you dont have to anymore
CMP     X4, X5
B.LT    incrementdigits
decimalcarry_cont:
ADD     X6, X6, #1 // increment the highest most significant digit which does not need a carry.
STRB    W6, [X1, X7] // store this into the string
MOV     X7, #0 // reset digit-of-focus to the smallest digit
MOV     W6, '0' // reset current counter to zero
MOV     X5, #0
ret

incrementdigits:
MOV     X4, X5
SUB     X3, X3, #1
B decimalcarry_cont

.data
placemarker:      .ascii  "00000000000\n" // just a placeholder, the initial value of the string that we will build. needs to be large enough to hold whatever length string you want to count to.
