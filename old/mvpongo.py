import os
import sys
import random
import pygame
from enum import IntEnum

# Ugly state
addr_width = 8
addr_mask = (2 ** addr_width) - 1

word_width = (2 * addr_width) + 1
word_mask = (2 ** word_width) - 1

ram = [0] * (2 ** word_width)
start = 0

asmmap = {}

class Regs(IntEnum):
    # Instruction pointer
    Ip      = 0,
    IpLoop  = 1,

    # Arithmetic unit
    OpA     = 2,
    OpB     = 3,
    Add     = 4,
    Inv     = 5,
    Rsv1    = 6,
    Rsv2    = 7,

    # Input
    PadA    = 8,
    PadB    = 9,

    # Display
    Dx      = 10,
    Dy      = 11,
    Col     = 12,

    # Controls
    Pulse   = 13,
    Loop    = 14,

class PulseLines(IntEnum):
    Nop     = 0x00,
    IncDx   = 0x01,
    IncDy   = 0x02,
    Plot    = 0x04,
    Clear   = 0x08,
    DecLp   = 0x10,
    WaitEx  = 0x20,


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


def assemble(filename):
    global start

    rawasm = open(filename, "r")
    asm = rawasm.readlines()
    rawasm.close()

    cip = 0
    labels = {}
    defines = {}
    hits = 0

    # Man writes world's worst lookahead; asked to leave emulation
    for statement in asm:
        statement = statement.strip()
        tok = statement.split()

        if len(tok) > 0 and not tok[0].startswith("#"):
            adv = True

            if tok[0].startswith("@"):
                # Preprocessor commands
                match tok[0]:
                    case "@Ip":
                        cip = int(tok[1]) & addr_mask
                        adv = False
                    case "@Lbl":
                        adv = False
                        labels[tok[1]] = cip
                    case "@Def":
                        adv = False
                        defines[tok[1]] = tok[2]
                    case "@Start":
                        adv = False

            if adv:
                cip += 1


    cip = 0

    for statement in asm:
        statement = statement.strip()
        tok = statement.split()

        if len(tok) > 0 and not tok[0].startswith("#"):
            adv = True
            
            # We'll assemble these into a word later
            src = 0
            dst = 0
            immed = False

            if tok[0].startswith("@"):
                # Preprocessor commands
                match tok[0]:
                    case "@Ip":
                        cip = int(tok[1]) & addr_mask
                        adv = False
                    case "@Data":
                        ram[cip] = int(tok[1]) & word_mask  
                    case "@Lbl":
                        adv = False
                        labels[tok[1]] = cip
                    case "@Def":
                        adv = False
                        defines[tok[1]] = tok[2]
                    case "@Start":
                        adv = False
                        start = cip

            elif tok[0].startswith("^"):
                # Pulseline macros - see what we got
                for line in tok[1:]:
                    try: 
                        src |= PulseLines[line]
                    except KeyError: 
                        print("unknown pulseline " + line)
                        sys.exit(-1)

                immed = True
                dst = Regs.Pulse.value

                # And assemble it all
                result = (1 << (addr_width * 2) if immed else 0) | src << addr_width | dst
                result &= word_mask

                ram[cip] = result

            else:
                # Regular instruction - see what we can do with it
                if len(tok) < 3 or tok[1] != ">":
                    # I'm just being mean
                    print("malformed expression " + statement)
                    sys.exit(-1)

                # Replace defines
                if tok[0] in defines: 
                    srctok = defines[tok[0]]
                elif tok[0] in labels: 
                    srctok = labels[tok[0]]
                elif tok[0].startswith("$") and tok[0][1:] in labels:
                    # Terrible hack for Ip writes
                    srctok = labels[tok[0][1:]]
                    immed = True
                else: srctok = tok[0]

                if tok[2] in defines: 
                    dsttok = defines[tok[2]]
                elif tok[2] in labels: 
                    dsttok = labels[tok[2]]
                else: dsttok = tok[2]

                # Convert to numbers
                if isinstance(srctok, str) and srctok.startswith("$"):
                    # Immediate value
                    src = int(srctok[1:]) & addr_mask
                    immed = True
                else:
                    # Possibly a named register
                    try:
                        src = Regs[srctok]
                    except KeyError:
                        # Must be an address?
                        src = int(srctok) & addr_mask

                try:
                    dst = Regs[dsttok]
                except KeyError:
                    # Must be a number?
                    dst = int(dsttok) & addr_mask

                # And assemble it all
                result = (1 << (addr_width * 2) if immed else 0) | src << addr_width | dst
                result &= word_mask

                ram[cip] = result

            if adv:
                asmmap[cip] = statement
                hits += 1
                cip += 1

            cip &= addr_mask
    
    print(f"Memory usage is {hits}/{2**addr_width}w")

last = -1
waiting = False
printing = False

# inspired by something on so
def sign_extended(val):
    sign_bit = 1 << (addr_width - 1)
    return (val & (sign_bit - 1)) - (val & sign_bit)

def step_cpu():
    global ram
    global last
    global waiting

    # Load up instruction 
    cip = ram[Regs.Ip]
    current_inst = ram[cip]

    immed = True if current_inst & (1 << (addr_width * 2)) else False
    src = (current_inst >> addr_width) & addr_mask
    dst = current_inst & addr_mask

    # Pretty print
    if cip != last and printing:
        if immed: psrc = f"${src:03X}"
        elif src in Regs: psrc = Regs(src).name
        else: psrc = f"{src:03X}"

        if dst in Regs: pdst = Regs(dst).name
        else: pdst = f"{dst:03X}"

        print(f"ip 0x{ram[Regs.Ip]:03X} : {psrc} > {pdst} : {asmmap[cip]}")

    # Move bits
    if immed and dst != Regs.IpLoop:
        ram[dst] = src
    else:
        # One special case: a write to IpLoop only succeeds if Loop is greater than zero
        if dst == Regs.IpLoop:
            #print(sign_extended(ram[Regs.Loop]))
            if sign_extended(ram[Regs.Loop]) > 0:
                if immed:
                    ram[Regs.Ip] = src
                else:
                    ram[Regs.Ip] = ram[src]
                ram[Regs.Loop] -= 1
            else:
                # Manually advance Ip past this
                ram[Regs.Ip] += 1
        else:
            ram[dst] = ram[src]

    # Do spooky math
    ram[Regs.Add] = (ram[Regs.OpA] + ram[Regs.OpB]) & addr_mask
    ram[Regs.Inv] = (~ram[Regs.OpA]) & addr_mask

    mpos = pygame.mouse.get_pos()
    ram[Regs.PadA] = int(mpos[0] / 32) % 32
    ram[Regs.PadB] = int(mpos[1] / 32) % 32

    current_pulse = ram[Regs.Pulse]

    if current_pulse & PulseLines.Plot:
        fb.set_at((ram[Regs.Dx], ram[Regs.Dy]), ram[Regs.Col])
    if current_pulse & PulseLines.Clear:
        fb.fill(pygame.Color("black"))

    if current_pulse & PulseLines.IncDx:
        ram[Regs.Dx] += 1
    if current_pulse & PulseLines.IncDy:
        ram[Regs.Dy] += 1
    if current_pulse & PulseLines.DecLp:
        ram[Regs.Loop] -= 1

    if current_pulse & PulseLines.WaitEx:
        waiting = True

    ram[Regs.Pulse] = 0

    # Maybe advance the ip
    if dst != Regs.Ip and dst != Regs.IpLoop:
        ram[Regs.Ip] += 1

    last = cip



if __name__ == "__main__":

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
