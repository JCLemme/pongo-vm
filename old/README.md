A short history of Pongos.

Basic archaeology:

## Pongo v1

Far too simple. Was optimizing for small datapaths, so there's no ALU and limited register-to-register options. The result was a machine that couldn't play Pong.

You can watch it try, though: `python pongo.py pong.asm`. It can draw the playfield before crashing out. See it in lights by running `pongocpu.circ` in Logisim.

## Pongo v2

An experiment with transport-triggered architectures. Worked OK, but never got built in Logisim because it was a mess and I knew I could do better.

This one has a working Pong (`python mvpongo.py bpong.asm`) but it's rougher than v3. 

## Pongo v3

Same concept as v2 but with the fat trimmed off. Weird-ass Harvard architecture with 16-bit instructions and 11-bit words. All memory is accessed indirectly so its "address space" is only like four bits wide (just the registers).

Pong works pretty well: it's an enhanced copy of v2's. Try it with `python pongothree.py tpong.asm`. The binary that the emulator generates (`assembled.bin`) will also run in Logisim (`pongothree.circ`), if you're patient. (See also `pongothree_latch.circ`, an experiment to increase the address space.)

Abandoned for being too limited yet too complex: a full adder, but no ability to read data in ROM? Fuck me, absolutely not.

## Pongo v4

Latest. This version had a traditional assembler (in `asmfour.*`) but I threw it out in favor of Lisp macros. It works fine other than macros, which I didn't finish. 

You can see an evolution of its syntax in all the `*.posm` files, and if you really care you can get syntax highlighting in Vim (`pongo.vim`).
