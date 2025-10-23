import os
import sys
import json
import random
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
    StoreIndirect = 0x10,  # next d>a* should use the indirect register
    LoadIndirect  = 0x20   # next a*>d should use the indirect register
    IndirectDown  = 0x40,  # decrements the indirect register
    WaitForFrame  = 0x80,  # pauses execution until the next frametime


class PongoCore():
    # Reset machine state.
    def reset(self, also_ram=False):
        if also_ram: self.ram = [0] * 16384
        self.ram[Regs.IpHi] = 0x80
        self.a = 0
        self.d = 0
        self.num_pushes = 0
        self.next_sixteen = False
        self.next_load_indirect = False
        self.next_store_indirect = False
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
            else: return calc_a & 0x3F
        elif self.num_pushes == 1:
            if calc_a & 0x0800: return calc_a | (~0xFFF & 0xFFFF)
            else: return calc_a & 0xFFF
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
                return (self.ram[Regs.IndiLo] >> 1) | (0x80 if self.ram[Regs.IndiLo] & 0x1 else 0x0)
            else:
                return self.ram[addr] & 0xFF

        elif addr < 32768:
            return self.io_handler(addr - 16384) & 0xFF

        elif addr < 65536:
            return self.rom[addr - 32768] & 0xFF

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
                if (data & FlowLines.LoadIndirect): self.next_load_indirect = True
                if (data & FlowLines.StoreIndirect): self.next_store_indirect = True

                if (data & FlowLines.LoopDown): self.counter_down(Regs.LoopLo)
                if (data & FlowLines.IndirectUp): self.counter_up(Regs.IndiLo)
                if (data & FlowLines.IndirectDown): self.counter_down(Regs.IndiLo)
                
                # A leaking abstraction: the IO handler controls frame timing, so we use its interface to
                # set this bit. In hardware it'd be a separate "halt cpu" line that the GPU ties into.
                if (data & FlowLines.WaitForFrame): self.io_handler(0, None, waitex=True)

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
            # The hardware doesn't shift, but rather flip-flops between high chunks.
            if self.num_pushes % 2 == 0:
                self.a = (self.a & ~0xFC0) | (this_data << 6)
            else:
                self.a = (self.a & ~0xF000) | (this_data << 12)

            self.num_pushes += 1

        elif this_opcode == Opcodes.AMovD:
            self.d = self.final_a(this_data)
            self.num_pushes = 0

        else:
            this_address = self.final_a(this_data)
            # Also note the order of ops here: need to inhibit looking at this flag during flow writes
            do_six = self.next_sixteen
            self.next_sixteen = False

            if this_opcode == Opcodes.AsMovD:
                if self.next_load_indirect:
                    this_address = (self.get(Regs.IndiHi) << 8 | self.get(Regs.IndiLo))
                    self.next_load_indirect = False

                new_data = self.get(this_address)
                if self.next_sixteen: new_data = (self.get(this_address + 1) << 8 | new_data)
                # self.next_sixteen = False  # To enable wide load/stores in the same instruction
                self.d = new_data
            
            elif this_opcode == Opcodes.DmovAs:
                should_move = True
                if self.next_store_indirect:
                    this_address = (self.get(Regs.IndiHi) << 8 | self.get(Regs.IndiLo))
                    self.next_store_indirect = False

                if self.next_inhibit:
                    this_loop = self.get(Regs.LoopHi) << 8 | self.get(Regs.LoopLo)
                    if this_loop == 0: should_move = False
                    self.next_inhibit = False

                if should_move:
                    self.set(this_address, self.d)
                    if do_six: self.set(this_address + 1, self.d >> 8)

            self.num_pushes = 0  # resetting every time reflects the circuit as built - could change

        self.a &= 0xFFFF
        self.d &= 0xFFFF

# A note to you: on inhibit ordering
# Initially, it was inhibit > 0, and 16w was preserved on failed D>A*
# ...which allowed optimized jumps like Exit ?> Ip; Again > Ip
# Now we are trying inhibit == 0, so loops can run like Again ?> Ip;
# ...but we can't preserve 16w because it would be dangling on loop exit
# I think this has no real consequences but if things break it's on you


# Note to self: you could do something terrible and load Ip from RAM, adding three cycles to every inst

# Memory map:
# $0008 - $3FFF  RAM
# $4000 - $47FF  Display
# $8000 - $FFFF  ROM (reset vector is $8000)


