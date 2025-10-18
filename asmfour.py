import os
import sys
from enum import IntEnum

from lark import Lark, Token, Tree

import pongofour as pf

class VirtualRegs(IntEnum):
    Ip   = 0,
    Loop = 2,
    Indi = 4,

    OpA  = 8,
    OpB  = 9,
    Add  = 10,

    TmpA = 11,
    TmpB = 12,
    TmpC = 13,
    TmpD = 14,
    TmpE = 15


yuck_src_cache = []

def invert_enum(enum: IntEnum):
    keys = {}
    for e in enum: keys[e.name] = e.value
    return keys

def trace(node: Tree):
    try:
        return (node.meta.line - 1, yuck_src_cache[node.meta.line - 1], node.meta.column - 1)
    except Exception:
        return (0, "~~unknown~~")

def crash_out(line, msg):
    print(f"{sys.argv[1]}:{line[0]}:{'' if len(line) != 3 else str(line[2]) + ':'} error: {msg}")
    print(line[1])
    if len(line) == 3: print((" " * line[2]) + "^")
    sys.exit(-1)



# Ugh
cache_regs = invert_enum(pf.Regs)
cache_flow = invert_enum(pf.FlowLines)
cache_virts = invert_enum(VirtualRegs)

class AssemblerState():
    def __init__(self):
        self.labels = {}
        self.defines = {}
        self.macros = {}
        self.regions = []

    def add_region(self, origin):
        self.last_region = Region(origin)
        self.regions.append(self.last_region)

    def add_statement(self, statement):
        self.last_region.add(statement)

    def add_macro(self, macro):
        self.macros[macro.name] = macro

    def add_label(self, label):
        label.give_width_hint(self.last_region.origin)
        self.labels[label.name] = label
        self.add_statement(label)

    def find_macro(self, name):
        return self.macros[name]

    def find_identifier(self, name):
        # Scan the tables.
        if name in cache_regs: return cache_regs[name]
        elif name in cache_flow: return cache_flow[name]
        elif name in cache_virts: return cache_virts[name]
        elif name in self.labels: return self.labels[name]
        else:
            raise KeyError(f"undeclared identifier \"{name}\"")

# --- --- --- --- --- --- ---

class Statement():
    def __init__(self):
        pass

    @classmethod
    def parse(cls, node: Tree):
        return cls()

    def inflate(self, offset: int, state: AssemblerState):
        return len(self.render(state))

    def render(self, state: AssemblerState):
        return bytes(0)


# A value passed to an instruction - one of several types.
class Argument():
    @staticmethod
    def parse_value(child):
        if child.data == "number_dec": value = int(child.children[0].value)
        elif child.data == "number_hex": value = int(child.children[0].value, 16)
        elif child.data == "number_bin": value = int(child.children[0].value, 2)
        elif child.data == "identifier": value = str(child.children[0].value)
        return value

    def __init__(self, value: str | int | list[str | int], indirect: bool = False, wide: bool = False, negative: bool = False, dubble: bool = False):
        self.value = value
        self.indirect = indirect
        self.wide = wide
        self.negative = negative
        self.dubble = dubble

    @classmethod
    def parse(cls, node: Token):
        dubble = True if node.data == "argument_dub" else False
        indirect = True if node.data == "argument_ind" else False
        wide = True if node.data == "argument_wid" else False
       
        # I don't like how I did this.
        if node.data == "bitfield":
            value = []
            negative = False
            for bf in node.children:
                tmparg = Argument.parse(bf)
                value.append(tmparg.value)
        elif len(node.children) > 0:
            # It might be one of several types.
            child = node.children[0]
            value = cls.parse_value(child)
            # TODO: no hack here plz
            negative = True if child.data == "number_dec" and value < 0 else False
        else:
            # It's double indirect. We don't really care about the value.
            value = pf.Regs.IndiLo
            negative = False

        return cls(value, indirect, wide, negative, dubble)

    def final_value(self, state):
        out = 0
        if not isinstance(self.value, list):
            todo = [self.value]
        else:
            todo = self.value

        for field in todo:
            if isinstance(field, int):
                out |= field
            else:
                # Hack: select fields should automatically count as "wide".
                if field == "Ip" or field == "Loop" or field == "Indi":
                    self.wide = True
                found = state.find_identifier(field)
                if isinstance(found, int): out |= found
                else: out |= found.location

        return out

    # This is stateful, so no dunder.
    def bytes(self, state):
        fat = self.final_value(state)

        if fat > 0xFF:
            return int(fat & 0xFFFF).to_bytes(2, "little")
        else:
            return int(fat & 0xFF).to_bytes(1)

    def chunks(self, state: AssemblerState):
        fat = self.final_value(state)

        # Lazy
        outs = [(fat & 0xF000) >> 12, (fat & 0x0FC0) >> 6, fat & 0x003F]

        if self.negative:
            if outs[0] == 0xF and outs[1] == 0x3F and outs[2] & 0x20: return [outs[2]]
            if outs[0] == 0xF and outs[1] == 0x3F and not (outs[2] & 0x20): return [0x3F, outs[2]]
            if outs[0] == 0xF and outs[1] & 0x20: return outs[1:3]
            return [outs[1], outs[0], outs[2]]
            # return outs
        else:
            if outs[0] == 0x0 and outs[1] == 0x00 and not (outs[2] & 0x20): return [outs[2]]
            if outs[0] == 0x0 and outs[1] == 0x00 and outs[2] & 0x20: return [0, outs[2]]
            if outs[0] == 0x0 and not (outs[1] & 0x20): return outs[1:3]
            return [outs[1], outs[0], outs[2]]
            
# A raw machine instruction.
class RawInstruction():
    def __init__(self, opcode: int, data: int = 0):
        self.opcode = opcode
        self.data = data

    @classmethod
    def disassemble(cls, inst: int):
        opcode = (inst & 0xC0) >> 6
        data = inst & 0x3F
        return cls(opcode, data)

    @classmethod
    def parse(cls, node: Token):
        # TODO: better support for identifiers inline
        data = Argument.parse_value(node.children[0].children[0])
        if isinstance(data, str): raise ValueError("only numbers allowed for inline instructions")

        if node.data == "inline_push": opcode = pf.Opcodes.PushA
        elif node.data == "inline_asd": opcode = pf.Opcodes.AsMovD
        elif node.data == "inline_ad": opcode = pf.Opcodes.AMovD
        elif node.data == "inline_das": opcode = pf.Opcodes.DmovAs
        
        return cls(opcode, data)

    def __int__(self):
        return ((self.opcode << 6) | (self.data & 0x3F)) & 0xFF

    def __bytes__(self):
        return int(self).to_bytes(1)

    def __repr__(self):
        return f"<op {pf.Opcodes(self.opcode).name}, data {hex(self.data)}>"

    def __str__(self):
        if self.opcode == pf.Opcodes.AMovD:
            return f"({hex(self.data)} > D)"
        elif self.opcode == pf.Opcodes.AsMovD:
            return f"(*{hex(self.data)} > D)"
        elif self.opcode == pf.Opcodes.DmovAs:
            return f"(D > *{hex(self.data)})"
        else:
            return f"({hex(self.data)} +)"

# A block of raw data to include in the binary.
class Data(Statement):
    def __init__(self, args: list[str | Argument]):
        self.args = args

    @classmethod
    def parse(cls, mainnode: Token):
        out = []
        args = mainnode.children[0].children
        for node in args:
            if node.data == "character":
                out.append(node.children[0].value)
            elif node.data == "string":
                # TODO: escape characters
                out.append(node.children[0].value[1:-1])
            else:
                out.append(Argument.parse(node))

        return cls(out)

    def render(self, state: AssemblerState):
        rend = bytes(0)
        for arg in self.args:
            if isinstance(arg, Argument):
                rend += arg.bytes(state)
            else:
                rend += arg.encode()
        return rend

# A single assembly instruction. Might degrade into multiple machine instructions.
class Instruction(Statement):
    def __init__(self, left: Argument, right: Argument, inhibited: bool = False):
        self.left = left
        self.right = right
        self.inhibited = inhibited

    @classmethod
    def parse(cls, node: Tree):
        inhibited = True if node.data == "instruction_inh" else False
        return cls(Argument.parse(node.children[0]), Argument.parse(node.children[1]), inhibited)

    def render(self, state: AssemblerState):
        rend = bytes(0)
        # TODO: more hate. We need to render the Argument to determine whether it should be wide or not.
        # And that needs to happen before we set the flags.
        leftdata = self.left.chunks(state)
        rightdata = self.right.chunks(state)
        print(f"left {self.left.final_value(state)} -> {leftdata}, right {self.right.final_value(state)} -> {rightdata}")

        # TODO: support auto indirect load
        # TODO: maybe done but double check
        if self.left.dubble and self.right.dubble:
            crash_out(trace(self), "can't reference indirect register on both sides of an instruction")

        # First up: set control lines.
        # TODO: check logic re: wide accesses, see if the compromise here is ok
        flags = (pf.FlowLines.InhibitIfZero if self.inhibited else 0)
        flags |= (pf.FlowLines.SixteenWide if self.left.wide or self.right.wide else 0)
        flags |= (pf.FlowLines.StoreIndirect if self.right.dubble else 0)
        flags |= (pf.FlowLines.LoadIndirect if self.left.dubble else 0)
        if flags != 0:
            rend += bytes(RawInstruction(pf.Opcodes.AMovD, flags))
            rend += bytes(RawInstruction(pf.Opcodes.DmovAs, pf.Regs.Flow))

        # Next, write the source data to D.
        for chunk in leftdata[:-1]:
            rend += bytes(RawInstruction(pf.Opcodes.PushA, chunk))
        if self.left.indirect:
            rend += bytes(RawInstruction(pf.Opcodes.AsMovD, leftdata[-1]))
        else:
            rend += bytes(RawInstruction(pf.Opcodes.AMovD, leftdata[-1]))

        # Then, store it at the specified address.
        # (I don't know if I want to keep the asterisk, it's implicit... we'll ignore it for now)
        for chunk in rightdata[:-1]:
            rend += bytes(RawInstruction(pf.Opcodes.PushA, chunk))
        rend += bytes(RawInstruction(pf.Opcodes.DmovAs, rightdata[-1]))

        return rend

# A block of raw instructions.
class Inline(Statement):
    def __init__(self, insts: list[RawInstruction]):
        self.insts = insts

    @classmethod
    def parse(cls, insts: Tree):
        found = []
        for node in insts.children: found.append(RawInstruction.parse(node))
        return cls(found)

    def render(self, state: AssemblerState):
        rend = bytes(0)
        for inst in self.insts: rend += int(inst).to_bytes(1)
        return rend

# A reference to a location in the program. Parsed in two passes: once to get its
# width, and twice to calculate its real offset.
class Label(Statement):
    def __init__(self, name):
        self.name = name
        self.location = 0
        self.final = False

    @classmethod
    def parse(cls, node: Token):
        return cls(node.children[0].value)

    def give_width_hint(self, origin_hint):
        if origin_hint < 0x32:
            self.location = (2 ** 6) - 1
        elif origin_hint < 0x2048:
            self.location = (2 ** 12) - 1
        else:
            self.location = (2 ** 16) - 1

    def inflate(self, offset: int, state: AssemblerState):
        self.location = offset
        self.final = True
        return 0

# A block of code that can be inlined from anywhere in the program.
class Macro():
    def __init__(self, name: str, signature: list[str]):
        self.name = name
        self.signature = signature
        self.contents = []

    @classmethod
    def parse(cls, node: Token):
        pass

    def generate(self, args):
        pass

# A place to swap in a macro.
class MacroCall(Statement):
    def __init__(self, name: str, args: list[str | int]):
        self.name = name
        self.args = args

    @classmethod
    def parse(cls, node: Token):
        args = []
        for child in node.children:
            args.append(Argument.parse(child))

        return cls(node.value, args)

# A region in the binary containing statements.
class Region():
    def __init__(self, origin: int):
        self.origin = origin
        self.statements = []
        self.rendered = None

    def add(self, state):
        self.statements.append(state)

    # Figure out how big we are going to be.
    def inflate_children(self, state):
        # How big we are!
        offset = self.origin
        this_block_idx = 0

        while this_block_idx < len(self.statements):
            this_block = self.statements[this_block_idx]

            # Look for macros to expand.
            if isinstance(this_block, MacroCall):
                try:
                    swap_macro = state.find_macro(this_block.name)
                except Exception:
                    crash_out(trace(this_block), f"undefined macro \"{this_block.name}\"")
                
                fill_in = swap_macro.generate(this_block.args)

                self.statements.remove(this_block_idx)
                for ib in range(len(fill_in)):
                    self.statements.insert(this_block_idx + ib, fill_in[ib])

            else:
                # Otherwise just inflate the block.
                try:
                    offset += this_block.inflate(offset, state)
                    this_block_idx += 1
                except Exception as e:
                    crash_out(trace(this_block), e)

    # Collect children as bytes.
    def render_children(self, state):
        self.rendered = bytes(0)
        for block in self.statements:
            self.rendered += block.render(state)
        
"""
    Fuq I'm mixed up.
    PREPROCESSOR:
    * pads strings
    * removes comments and blank lines
    * extracts defines
    * handles includes
    
    PARSING:
    * generates node tree

    FORWARD PASS:
    * converts tree into list of objects
    * splits code into regions and macros
    * expands local labels
    * calculates label width
    * caches seen labels

    REVERSE PASS:
    * replaces macro calls
    * expands statements
    * calculates label offsets

    FASTPASS:
    * relocates labels
    * collect output binary

"""


# --- --- --- --- --- --- ---

if __name__ == "__main__":
    # Load the source file please.
    with open(sys.argv[1], "r") as srcfile:
        raw_srclines = srcfile.read().splitlines()

    srcpadded = ""

    # This hack fixes the parser - it won't decompose statements w/o trailing whitespace.
    # TODO: why is that
    for line in raw_srclines:
        srcpadded += line + "  \n"

    # Ugh
    yuck_src_cache = srcpadded.splitlines()

    # Grow some trees.
    with open("asmfour.lark", "r") as gf:
        parser = Lark(gf, propagate_positions = True)
        srctree = parser.parse(srcpadded)

    state = AssemblerState()

    # THE FORWARD PASS
    for node in srctree.children:
        # TODO: this will break when including
        raw_line = trace(node)

        if node.data == "preprocessor_ip":
            # Make a new region at this address.
            next_ip = Argument.parse_value(node.children[0])
            state.add_region(next_ip)
            
        elif node.data == "preprocessor_data":
            state.add_statement(Data.parse(node))
            
        elif node.data == "preprocessor_generic":
            crash_out(raw_line, "unrecognized preprocessor statement")

        elif node.data == "inline":
            state.add_statement(Inline.parse(node))

        elif node.data.startswith("instruction"):
            state.add_statement(Instruction.parse(node))

        elif node.data == "label":
            state.add_label(Label.parse(node))
             
        elif node.data == "macro":
            state.add_macro(Macro.parse(node))

        elif node.data == "macro_call":
            state.add_statement(MacroCall.parse(node))

        else:
            crash_out(raw_line, "unrecognized statement")

    breakpoint()
    # THE REVERSE PASS
    for region in state.regions:
        region.inflate_children(state)
    breakpoint()
    # DISNEY'S FASTPASS:TM:
    for region in state.regions:
        region.render_children(state)

    # No clever name, just collate the regions together.
    result = bytearray(2 ** 16)

    for region in state.regions:
        for rp in range(len(region.rendered)):
            result[region.origin + rp] = region.rendered[rp]

    with open("assm.bin", "wb") as binfile:
        binfile.write(result)

