# The Pongo series of virtual machines
---

The machines in this repository are the result of eighteen months of nerd-sniping: what is the simplest computer that can play Pong?

Science is now a little closer to an answer. At least this simple:

![Version three](/media/cover.png)

(Documentation to be written.)

---

## Play with it

You'll need a Python venv and SBCL.

Pongo v3 is the latest version that can play Pong, kind of, sort of. Navigate to `old/` and run `python pongothree.py tpong.asm`. Mouse controls both paddles.

The much more ambitious Pongo v4 does not have a Pong written for it yet. Rest assured, it will someday. A much better Pong even. But feel free to try what's there via:

```
./impede pfpong.lisp pfpong.bin
python emufour.py pfpong.bin
```

The emulator starts paused - press **p** to resume or **enter** to single step. You can turn off debug logging (for a speedup) with **o**. 

Pongo v4 programs are written in a Cronenberg hybrid of Lisp and assembler. In lieu of docs you can read through `environment.lisp` and grasp the basics. 
