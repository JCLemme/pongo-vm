import os
import sys
import random
import json

import pygame

import pongofour as pf
import asmfour as af

# I/O tweakables.
display_size = (32, 32)
zoom = 32
display_scaled = (display_size[0] * zoom, display_size[1] * zoom)
waiting_frame = False
paddle_a = 0
paddle_b = 0

fb = None
sfb = None

printing = True
pausing = True
spins = 0

def pongo_io(addr, data=None, waitex=False):
    global waiting_frame
    if waitex:
        if printing: print(">>>>> Frame submitted! <<<<<")
        waiting_frame = True
        return

    if data is None:
        if addr == 1024:
            return paddle_a
        elif addr == 1025:
            return paddle_b
        elif addr == 1026:
            return random.randint(0, 255)
        else:
            return 0xEA

    else:
        if addr < 1024:
            fb.set_at((addr % display_size[0], int(addr / display_size[1])), data)


def print_state(core):
    global spins
    spins += 1
    this_ip = core.get(pf.Regs.IpHi) << 8 | core.get(pf.Regs.IpLo)
    this_indi = core.get(pf.Regs.IndiHi) << 8 | core.get(pf.Regs.IndiLo)
    this_loop = core.get(pf.Regs.LoopHi) << 8 | core.get(pf.Regs.LoopLo)
    this_inst = core.get(this_ip)

    print(f"Ip ${this_ip:04x}, A ${core.a:04x}, D ${core.d:04x} | Loop ${this_loop:04x}, Indi ${this_indi:04x}   |   {af.RawInstruction.disassemble(this_inst)}")
    #if this_ip == 0x800e: breakpoint()
    #if spins > 40: sys.exit(-2)

if __name__ == "__main__":

    pygame.init()
    screen = pygame.display.set_mode(display_scaled)
    fb = pygame.Surface(display_size).convert(8)
    sfb = pygame.Surface(display_scaled).convert(8)
    pygame.key.set_repeat(500, 50)

    # Set up the terminal.
    fb.fill(pygame.Color(0, 255, 255))

    with open("xterm_colors.json", "r") as palette:
        colo = json.loads(palette.read())
        for c in colo:
            fb.set_palette_at(int(c), (colo[c]["r"], colo[c]["g"], colo[c]["b"]))

    sfb.set_palette(fb.get_palette())

    # Assemble the program.
    with open(sys.argv[1], "rb") as binfile:
        contents = [e for e in bytearray(binfile.read())]

    # Make a core.
    core = pf.PongoCore(contents[0x8000:], pongo_io)
    
    # And repeat.
    run = True
    paused = True

    while run:
        # Handle I/O.
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                run = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    run = False
                elif event.key == pygame.K_p:
                    pausing = not pausing
                elif event.key == pygame.K_o:
                    printing = not printing
                elif event.key == pygame.K_RETURN:
                    if pausing:
                        paused = False

        mpos = pygame.mouse.get_pos()
        paddle_a = int(mpos[0] / 32) % 32
        paddle_b = int(mpos[1] / 32) % 32

        if waiting_frame:
            pygame.transform.scale(fb, display_scaled, dest_surface=sfb)
            screen.blit(sfb, (0, 0))
            pygame.display.update()

            # pygame.time.wait(16)
            waiting_frame = False
        
        # Execute an instruction.
        if not pausing or (pausing and not paused):
            if printing: print_state(core)
            # TODO: run instructions to fill 60hz
            core.spin()
            paused = True

    pygame.quit()
