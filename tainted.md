You should never have to worry that someone is wasting your time, by making you read code that they didn't write.

Let's save us both the trouble. Here are all the things touched by AI in this project:

* `(number-to-chunks)` in `environment.lisp` was ported by Claude from its original Python implementation (in `old/asmfour.py`). It's fiddly and I wanted a "beachhead" from which to start the Lisp port of the assembler. 

* The scripts `png_to_lisp.py` and `old/xterm_to_gpl.py` (and `old/png_to_asm.py`) were written by Claude because I couldn't be assed.

* The directory `old/web/` contains Javascript versions of the emulator (somewhat broken) and the assembler (entirely broken). They were one-shots ("please port this file to JS", etc.) that I did as an experiment. Didn't really pan out. Call it cope; I had just found out that there's no JS interpreter for Common Lisp and was pretty upset about it.

Every other word/document/sexp/script/etc. in this repository was written by **me** with a keyboard and hands. 
