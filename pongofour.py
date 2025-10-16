import os
import sys
import json
import random
import pygame
from enum import IntEnum


class Opcodes(IntEnum):
    AsMovD = 0b00,
    AMovD  = 0b01,
    DmovAs = 0b10,
    PushA  = 0b11

class Regs(IntEnum):
    # Instruction pointer
    IpLo    = 0,
    IpHi    = 1,

    LoopLo  = 2,
    LoopHi  = 3,

    IndiLo  = 4,
    IndiHi  = 5,

    Nand    = 6,

    Flow    = 7

class FlowLines(IntEnum):
    SixteenWide   = 0x01,  # could do in one cycle by "cheating" w/ 16bit regs, but would rather not - so you can write words to all memory (odds)
    # should also read 16 etc.
    InhibitIfZero = 0x02,  # blocks the next d> move if the loop register is zero
    LoopDown      = 0x04,  # decrements the loop register
    IndirectUp    = 0x08,  # increments the indirect register
    UseIndirect   = 0x10,  # next a* instruction should use the indirect register
    IndirectDown  = 0x20,  # decrements the indirect register
    WaitForFrame  = 0x40,  # pauses execution until the next frametime


class PongoCore():
    # Reset machine state.
    def reset(self, also_ram=False):
        if also_ram: self.ram = [0] * 16384
        self.ram[Regs.IpHi] = 0x80
        self.a = 0
        self.d = 0
        self.num_pushes = 0
        self.next_sixteen = False
        self.next_indirect = False
        self.next_inhibit = False

    # Construct a new core.
    def __init__(self, rom, io=None):
        self.rom = rom
        self.io_handler = io
        self.reset(True)

    # Calculate A given the current instruction and sign extension.
    def final_a(self, inst_a):
        calc_a = (self.a | inst_a) & 0xFFFF
        # I refuse to be smarter than this.
        if self.num_pushes == 0:
            if calc_a & 0x0020: return calc_a | (~0x3F & 0xFFFF)
            else: return calc_a
        elif self.num_pushes == 1:
            if calc_a & 0x0800: return calc_a | (~0x3F & 0xFFFF)
            else: return calc_a
        elif self.num_pushes == 2:
            return calc_a
        else:
            raise RuntimeWarning("Too many pushes in a row")

    # Manipulates one of the counter registers.
    def counter_up(self, base_addr):
        this_byte = (self.ram[base_addr] + 1) & 0xFF
        self.ram[base_addr] = this_byte
        if this_byte == 0x00:
            this_byte = (self.ram[base_addr + 1] + 1) & 0xFF
            self.ram[base_addr + 1] = this_byte

    def counter_down(self, base_addr):
        this_byte = (self.ram[base_addr] - 1) & 0xFF
        self.ram[base_addr] = this_byte
        if this_byte == 0xFF:
            this_byte = (self.ram[base_addr + 1] - 1) & 0xFF
            self.ram[base_addr + 1] = this_byte

    # Gets a byte from system memory.
    def get(self, addr):
        addr &= 0xFFFF
        if addr < 16384:
            if addr == Regs.Nand:
                return ~(self.ram[Regs.IndiLo] & self.ram[Regs.IndiHi])
            elif addr == Regs.Flow:
                return 0x55
            else:
                return self.ram[addr] & 0xFF

        elif addr < 32768:
            return self.io_handler(addr - 16384) & 0xFF

        elif addr < 65536:
            return self.rom[addr] & 0xFF

        else:
            raise RuntimeWarning("Read out of bounds")

    # Sets a byte in system memory.
    def set(self, addr, data):
        addr &= 0xFFFF
        data &= 0xFF
        if addr < 16384:
            # We can just ignore writes to Nand.
            self.ram[addr] = data

            if addr == Regs.Flow:
                if (data & FlowLines.SixteenWide): self.next_sixteen = True
                if (data & FlowLines.InhibitIfZero): self.next_inhibit = True
                if (data & FlowLines.UseIndirect): self.next_indirect = True

                if (data & FlowLines.LoopDown): self.counter_down(Regs.LoopLo)
                if (data & FlowLines.IndirectUp): self.counter_up(Regs.IndiLo)
                if (data & FlowLines.IndirectDown): self.counter_down(Regs.IndiLo)
                
                # A leaking abstraction: the IO handler controls frame timing, so we use its interface to
                # set this bit. In hardware it'd be a separate "halt cpu" line that the GPU ties into.
                if (data & FlowLines.WaitForFrame): self.io_handler(0, None, True)

        elif addr < 32768:
            self.io_handler((addr - 16384) & 0xFFFF, data)

        else:
            raise RuntimeWarning("Write out of bounds")

    # Process a single instruction.
    def spin(self):
        this_ip = self.get(Regs.IpHi) << 8 | self.get(Regs.IpLo)
        this_inst = self.get(this_ip)
        this_opcode = this_inst >> 6
        this_data = this_inst & 0x3F
        
        self.counter_up(Regs.IpLo)

        if this_opcode == Opcodes.PushA:
            self.a |= this_data
            self.a <<= 6
            self.num_pushes += 1

        elif this_opcode == Opcodes.AMovD:
            self.d = self.final_a(this_data)
            self.num_pushes = 0

        else:
            self.num_pushes = 0  # resetting every time reflects the circuit as built - could change

            if self.next_indirect:
                this_address = (self.get(Regs.IndiHi) << 8 | self.get(Regs.IndiLo))
                self.next_indirect = False
            else:
                this_address = self.final_a(this_data)

            if this_opcode == Opcodes.AsMovD:
                new_data = self.get(this_address)
                if self.next_sixteen: new_data = (self.get(this_address + 1) << 8 | new_data)
                self.next_sixteen = False
                self.d = new_data
            
            elif this_opcode == Opcodes.DmovAs:
                should_move = True
                if self.next_inhibit:
                    this_loop = self.get(Regs.LoopHi) << 8 | self.get(Regs.LoopLo)
                    if this_loop > 0: should_move = False
                    self.next_inhibit = False

                if should_move:
                    self.set(this_address, self.d)
                    if self.next_sixteen: self.set(this_address + 1, self.d >> 8)
                    self.next_sixteen = False  # note that this flag doesn't clear if the move doesn't happen

        self.a &= 0xFFFF
        self.d &= 0xFFFF


# Note to self: you could do something terrible and load Ip from RAM, adding three cycles to every inst

# Memory map:
# $0008 - $3FFF  RAM
# $4000 - $47FF  Display
# $8000 - $FFFF  ROM (reset vector is $8000)

# I/O tweakables.
display_size = (32, 32)
zoom = 32
display_scaled = (display_size[0] * zoom, display_size[1] * zoom)
waiting_frame = False
paddle_a = 0
paddle_b = 0

fb = None
sfb = None

def pongo_io(addr, data=None, waitex=False):
    global waiting_frame
    if waitex:
        waiting_frame = True
        return

    if data is None:
        if addr == 1024:
            return paddle_a
        elif addr == 1025:
            return paddle_b
        else:
            return 0xEA

    else:
        if addr < 1024:
            fb.set_at((addr % display_size[0], int(addr / display_size[1])), data)


def print_state():
    cip = reg[Regs.Ip]
    src, dst, immed = from_word(rom[cip])
    if src == dst and src == Regs.Ip: return
    print(f"Ip {cip:03X} : {rom[cip]:04X} : {'$' if immed else ' '}{src:03X} > {dst:03X} {(': ' + ' '.join(parsed[cip])) if cip in parsed else ''}", end="")
    print(f"\t\tOpA {reg[Regs.OpA]:03X} : OpB {reg[Regs.OpB]:03X} : Test {reg[Regs.Test]:03X} : PadA {reg[Regs.PadA]:03X}", end="")
    print(f" : TmpA {reg[Regs.TmpA]:03X} : TmpB {reg[Regs.TmpB]:03X} : TmpC {reg[Regs.TmpC]:03X}")



printing = False

if __name__ == "__main__":

    pygame.init()
    screen = pygame.display.set_mode(display_scaled)
    fb = pygame.Surface(display_size).convert(8)
    sfb = pygame.Surface(display_scaled).convert(8)

    # Set up the terminal.
    fb.fill(pygame.Color(0, 255, 255))

    with open("xterm_colors.json", "r") as palette:
        colo = json.loads(palette.read())
        for c in colo:
            fb.set_palette_at(int(c), (colo[c]["r"], colo[c]["g"], colo[c]["b"]))

    sfb.set_palette(fb.get_palette())

    # Assemble the program.
    with open(sys.argv[1], "r") as source:
        contents = source.readlines()

    do_assembly(contents)

    with open("assembled.bin", "w") as mch:
        for i in range(0, 2**width):
            w = rom[i]
            mch.write(f"{w:04X} ")

    # Make a core.
    core = PongoCore(assembled, pongo_io)

    # And repeat.
    run = True

    while run:
        # Execute an instruction.
        core.spin()

        # Handle I/O.
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                run = False

        mpos = pygame.mouse.get_pos()
        paddle_a = int(mpos[0] / 32) % 32
        paddle_b = int(mpos[1] / 32) % 32

        if waiting_frame:
            pygame.transform.scale(fb, display_scaled, dest_surface=sfb)
            screen.blit(sfb, (0, 0))
            pygame.display.update()

            pygame.time.wait(15)
            waiting_frame = False


    pygame.quit()
