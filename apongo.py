import os
import sys
import random
import pygame
from enum import IntEnum


# ----
# Machine defs

class Regs(IntEnum):
    # Instruction pointer
    Ip      = 0,
    IpTest  = 1,

    # Arithmetic functions
    Test    = 2,
    OpA     = 3,
    OpB     = 4,
    Add     = 5,
    Nand    = 6,

    # Memory access
    RamAddr = 7,
    RamIn   = 8,
    RamOut  = 9,

    # Display access
    DspAddr = 10,
    DspIn   = 11,
    DspOut  = 12,

    # Various I/O
    Paddle  = 13,
    Temp    = 14,
    Indir   = 15

# Tweakables.
width = 11
ram_size = 8
display_size = (32, 32)

# Autocalculated masks and such.
width_mask = (2 ** width) - 1
word_width = width + 4 + 1
word_mask = (2 ** word_width) - 1
ram_mask = (2 ** ram_size) - 1

# Convert words to fields and back again.
def to_word(src, dest, immediate=False):
    return ((src & width_mask) << 5) | ((dest & 0xF) << 1) | (0x1 if immediate)

def from_word(word):
    return ((word >> 5) & width_mask), ((word >> 1) & 0xF), (True if word & 0x1 else False)


# ----
# Machine state

rom = [0] * (2 ** width)
ram = [0] * (2 ** ram_size)
vram = [0] * (display_size[0] * display_size[1])


# ---- 
# Assembler

defines = {}
reverse_source = {}

class Macro():
    def __init__(self, args, lines):
        self.args = args
        self.lines = lines

    def inflate(self, called):
        output = []
        for line in self.lines:
            line_toks = line.strip().split()
            for i, tok in enumerate(line_toks):
                if tok in self.args:
                    line_toks[i] = called[self.args.index(tok)]
            output.append(" ".join(line_toks))
        return output

def do_assembly(contents):
    # First pass: clean, parse, and find definitions.
    blocks = {}

    for line in contents:
        line_toks = line.strip().split()

        if len(line_toks) == 0 or line_toks[0].startswith("#"):
            continue

        # Valid line. Is it a macro?
        if line_toks[0].startswith("

if __name__ == "__main__":

    pygame.init()
    screen = pygame.display.set_mode((32*32, 32*32))
    fb = pygame.Surface((32, 32)).convert(8)
    sfb = pygame.Surface((32*32, 32*32)).convert(8)

    fb.fill(pygame.Color(0, 255, 255))

    fb.set_palette_at(0, (0, 0, 0))
    fb.set_palette_at(160, (215, 0, 0))
    fb.set_palette_at(34, (0, 175, 0))
    fb.set_palette_at(240, (88, 88, 88))
    fb.set_palette_at(255, (238, 238, 238))

    sfb.set_palette(fb.get_palette())

    assemble(sys.argv[1])
    with open("assembled.bin", "w") as mch:
        for i in range(0, 2**addr_width):
            w = ram[i]
            mch.write(f"{w:05X} ")

    # Past the registers
    ram[Regs.Ip] = start

    run = True
    do_tick = True

    while run:
        # Manage shit
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                run = False
            #elif event.type == pygame.KEYDOWN:
            #    do_tick = True

        if do_tick:
            #do_tick = False
            
            # Execute
            step_cpu()

            # Show it off
            if waiting:
                pygame.transform.scale(fb, (32*32, 32*32), dest_surface=sfb)
                screen.blit(sfb, (0, 0))
                pygame.display.update()

                pygame.time.wait(15)
                waiting = False


    pygame.quit()
