pongo cpu
=========

theory
------

The pongo cpu is a transport-triggered architecture; there is one instruction, *move*, and it is implicit. 
Technically, there is a second instruction; when the high-order bit of an instruction is set, the source is treated as an immediate value to be moved into the destination, rather than as an address.

Registers are n bits wide, and hold signed values. Instruction words are (2n + 1) bits wide, holding two memory addresses and an immediate flag. 
The address bus width matches the register width, thus the cpu can address 2^n words. 
Each memory cell is word-sized, and thus can hold quite a bit more than one address. Moves from memory into memory will move the whole word.
Note, however, that any move into or out of a register will mask the value to be n bits wide, so the machine can be considered n-bit for all practical purposes. 

All registers are mapped into the beginning of memory, and are internally connected to logic that allows the cpu to perform useful work.

Register 0 is the instruction pointer. This value automatically increments as instructions are processed. 
Register 1 is a write-only shadow of the instruction pointer, with the caveat that it will only allow a write when Loop is greater than zero.

Loading the instruction pointer will inhibit it from incrementing for that cycle. 

Four registers make up the arithmetic unit. Arithmetic is performed every cycle, with each function executing in parallel and being deposited into its respective register.
Registers 2 and 3 are the A and B operand, respectively.
Register 4 is the result of A + B, while register 5 is the result of ~A.

The display is controlled by three dedicated registers. Registers 10 and 11 make up an X and Y coordinate pair; register 12 is an eight-bit color.
The coordinates are implemented as counters; they can be incremented without needing to go through the arithmetic unit.

Various functions are controlled by register 13, the Pulse register. Each bit of this register is connected directly to external logic, with no backing store.
Thus, writing to it effectively "pulses" those bits high for a cycle.
Bits 0 and 1 increment the X and Y display coordinates, respectively. Bit 2 writes the pixel described in the display registers to the display, while bit 3 clears the display entirely.
Bit 4 decrements the Loop register - see below.
Bit 5 is a "wait for interrupt"; the CPU will stop cycling until some external logic fires. This is generally connected to a 60Hz timer.
Writing zero to Pulse does nothing; it can be safely used as a no-op.

The last register, 14, is the Loop register. It can be used in conjunction with the IpLoop register to implement conditional jumps.
Internally, this register is implemented as a decrementing counter; when a write to IpLoop succeeds - i.e. when the value in Loop is greater than zero - it decrements Loop by one. 
This allows loops to be written concisely, as the name implies.

Execution begins at the "start address", which is machine-dependent but generally equal to the first non-register word in memory.
There is no specific instruction to halt the CPU; however, a move from the instruction pointer *into* the instruction pointer will stall, and thus can be used as a substitute.


assembly
--------

Since there is only one instruction, pongo assembly language is concise. Comments begin with "#" and blank lines are ignored.
Comments can also follow instructions on the same line. The assembler ignores everything after a valid instruction, but by convention, you should still begin these inline comments with "#".

The basic instruction consists of a source and a destination address, separated by ">" to imply direction. Register names are automatically substituted with their addresses.

    23 > 33
    19 > OpA
    Add > IpLoop

Immediate values begin with "$", and are parsed as a signed decimal integer. Only the source can be an immediate value.

    $5 > Loop
    $-2 > OpB

Writes to the Pulse register can be substituted with "^"; everything following the caret is parsed as a bit to set in the resulting instruction. See below for the bit names.
Note that the assembler is brain-dead and will attempt to match *everything* following the caret, thus inline comments cannot be left on these lines.

    ^ Plot
    ^ IncDx DecLp Clear

Preprocessor statements begin with "@".

`@Ip nnn`, where nnn is an unsigned decimal integer, sets the address that assembled instructions are inserted into memory.

`@Start` tells the assembler that the current address should be where the program begins execution; this is mostly for the benefit of emulators.

`@Data n` reserves a word in memory, and writes the signed decimal integer n into that word.

`@Def a b` is short for "define"; any following instance of a in the program will be substituted by b. Substitutions will only occur on whole terms, i.e. ones separated by whitespace.

    @Def PlayerSize $10
    PlayerSize > Loop

would become

    $10 > Loop

`@Lbl a` is short for "label", and acts as a define where the substitution term is the current address. 
Labels can be treated as addresses, to implement named variables...

    @Lbl HighScore
    @Data 0
    $10 > HighScore

...or prepended with "$" to be treated as an immediate value, which is useful for jumps.

    $9 > Loop
    @Lbl DrawingLine
    ^ IncDx
    $DrawingLine > IpLoop


reference
---------

| Address | Short name | Description |
| ------- | ---------- | ----------- |
| 0 | Ip | Instruction pointer |
| 1 | IpLoop | Conditional instruction pointer |
| 2 | OpA | Operand A |
| 3 | OpB | Operand B | 
| 4 | Add | Addition result | 
| 5 | Inv | Bitwise inversion result | 
| 10 | Dx | Display X coordinate | 
| 11 | Dy | Display Y coordinate | 
| 12 | Col | Display pixel color | 
| 13 | Pulse | Pulse register |
| 14 | Loop | Loop register | 

| Bit | Short name | Description |
| --- | ---------- | ----------- |
| 0x01 | IncDx | Increments the Dx register | 
| 0x02 | IncDy | Increments the Dy register | 
| 0x04 | Plot | Draws a pixel to the display | 
| 0x08 | Clear | Clears the display | 
| 0x10 | DecLp | Decrements the loop register |
| 0x20 | WaitEx | Waits for an external interrupt |
