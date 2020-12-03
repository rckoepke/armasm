//
// Assembler program to print a register in hex
// to stdout.
//
// X0-X2 - parameters to linux function services
// X1 - is also address of byte we are writing
// X4 - register to print
// W5 - loop index
// W6 - current character
// X8 - linux function number

.global _main                   // Provide program starting address
.p2align 2

print:
  ADRP   X1, hexstr@PAGE        // start of hex template string address - doesn't matter what's in here as long as it is 17 chars long, but for formatting/human reading should start with 0x, and end with \n
  ADD    X1, X1, hexstr@PAGEOFF // rest of hex template string address (12-bit offset)
  # https://stackoverflow.com/questions/41906688/
  # https://reverseengineering.stackexchange.com/questions/14385/
  ADD    X1, X1, #17            // start at least significant digit
  MOV    W5, #16                // essentially int i = 16 to initialize loop at 16
  # will do i=16; i>0; i--
loop:
    AND    W6, W4, #0xf         // mask of least sig digit (grabs smallest digit only)
// This next checks if W6 >= 10 then this digit is a letter (Hex A-F, decimal 10-15)
    CMP    W6, #10              // Compare digit to decimal 10
    B.GE    letter              // If >= 10, go to "dealing with letters" procedure. see Table C1-1 Condition codes, ARM DDI 0487F.c
    # https://developer.arm.com/docs/ddi0595/h/aarch64-system-registers/nzcv
    ADD    W6, W6, #48          // Else its a number so convert to an ASCII digit
  //ADD    W6, W6, #'0'         // same as above http://www.asciitable.com
    B    cont                   // skip past 'letter', goto to 'cont. Essentially, end if
letter: // procedure to handle the digits A to F (decimal 10-15)
    ADD    W6, W6, #(65-10)     // converts numerical number to ASCII value
   #ADD    W6, W6, #55          // same as above http://www.asciitable.com
   #ADD    W6, W6, #'A'-10      // same as above http://www.asciitable.com
                                // for example, 55+12 = 67. 67 in ASCII is 'C' and 'C' is the hex digit for 12.
cont:    // end if
    STRB    W6, [X1]            // store least byte from W6 into character address held in X1
    SUB    X1, X1, #1           // decrement address for next digit/character
    LSR    X4, X4, #4           // shift off the digit we just processed

    // next W5
    SUBS    W5, W5, #1          // step W5 by -1 - note, this is a comparison in addition to a substraction
    B.NE    loop                // another for loop if not done see Table C1-1 Condition codes, ARM DDI 0487F.c
    # https://developer.arm.com/docs/ddi0595/h/aarch64-system-registers/nzcv

// Setup the parameters to print our hex number
// and then call Linux to do it.
    MOV    X0, #1                 // 1 = StdOut
    ADRP   X1, hexstr@PAGE        // approximate address of string (cannot pass full 64-bits in one instruction)
    ADD    X1, X1, hexstr@PAGEOFF // precise address of string (the last 12 bits that didn't fit in previous instruction)
    MOV    X2, #19                // length of our string
    MOV    X16, #4                // linux write system call
    SVC    #0x80                  // Call linux to output the string
    ret

one:
    MOV    X4, #0x6E3A           // 0x6E3A
    MOVK    X4, #0x4F5D, LSL #16 // 0x4F5D6E3A
    MOVK    X4, #0xFEDC, LSL #32 // 0xFEDC4F5D6E3A
    MOVK    X4, #0x1234, LSL #48 // 0x1234FEDC4F5D6E3A == 1311953613649440314 (1.3 billion billion)
    ret

two:
    MOV    X4, #0x1234           // 00x1234
    MOVK    X4, #0x4444, LSL #16 // 0x44441234
    MOVK    X4, #0x5555, LSL #32 // 0x555544441234
    MOVK    X4, #0x6666, LSL #48 // 0x6666555544441234 == 7378678864199029300 (7.3 billion billion)
    ret

exit:
// Setup the parameters to exit the program
// and then call the kernel to do it.
    MOV     X0, #0               // Use 0 return code
    MOV     X16, #1              // System call number 1 terminates this program
    SVC     #0x80                // Call kernel to terminate the program

_main:
    BL one
    BL print
    BL two
    BL print
    B exit

.data

hexstr:      .ascii  "0x0000000000000000\n"
