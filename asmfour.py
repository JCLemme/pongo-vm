import os
import sys
from enum import IntEnum

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

# A raw machine instruction.
class Instruction():
    def __init__(self, opcode: int, data: int):
        self.opcode = opcode
        self.data = data

    @classmethod
    def decode(cls, inst: int):
        opcode = (inst & 0xC0) >> 6
        data = inst & 0x3F
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
            return f"({hex(self.data)}* > D)"
        elif self.opcode == pf.Opcodes.DmovAs:
            return f"(D > {hex(self.data)}*)"
        else:
            return f"({hex(self.data)} +)"


class Statement():
    @staticmethod
    def parseNumber(num: str) -> int:
        num = num.lower().replace("#", "")
        if num.startswith("$"):
            return int(num[1:], 16)
        elif num.startswith("0x"):
            return int(num[2:], 16)
        elif num.startswith("0b"):
            return int(num[2:], 2)
        else:
            return int(num)

    def __init__(self, tokens: list[str], raw: tuple):
        self.tokens = tokens
        self.raw = raw
        self.instructions = []


class Region():
    def __init__(self, origin: int):
        self.origin = origin
        self.statements = []

    def add(self, state):
        self.statements.append(state)

class Label():
    def __init__(self, name, origin_hint):
        self.name = name
        self.location = None
        # Try to guess how wide A will be.
        if origin_hint < 0x32:
            self.width = 1
        elif origin_hint < 0x2048:
            self.width = 2
        else:
            self.width = 3

class Macro():
    def __init__(self, name: str, signature: list[str]):
        self.name = name
        self.signature = signature
        self.contents = []

    def add(self, state):
        self.contents.append(state)




"""
General order of ops:

    Pass 1: 
        break file into regions by Ip, 
        extract macros, 
        remove blank/comment lines, 
        note labels globally, along with potential width
        process local labels,
        
    For each region:
        replace macros,
        decompose statements into insts,
        record global labels
"""

def crash_out(line, msg, char=None):
    print(f"{sys.argv[1]}:{line[0]}:{'' if char is None else str(char) + ':'} error: {msg}")
    print(line[1])
    sys.exit(-1)

with open(sys.argv[1], "r") as srcfile:
    srclines = srcfile.read().splitlines()

# --- --- --- --- ---

regions = []
labels = {}
macros = {}

this_region = Region(0)
this_macro = None
last_label = ""

# PASS 1: preprocessing and tokenization
# --- --- --- --- ---
for l in range(len(srclines)):
    # The format we'll use to pass around source file lines (debugging, etc.)
    raw_line = (l, srclines[l])

    # Remove comments and blanks.
    line_toks = raw_line[1].split(";")
    if len(line_toks) == 0: continue
    if line_toks[0] == "": continue

    line_toks = line_toks[0].split()
    if len(line_toks) == 0: continue

    # Look for new regions.
    if line_toks[0] == "!Ip":
        # Error handling.
        if this_macro is not None: crash_out(raw_line, "can't set the origin inside a macro")
        if len(line_toks) != 2: crash_out(raw_line, f"expected one number, got {len(line_toks)}")
        try: new_origin = Statement.parseNumber(line_toks[1])
        except Exception: crash_out(raw_line, "couldn't parse number")

        this_region = Region(new_origin)
        regions.append(this_region)

    elif line_toks[0] == "!Macro":
        # More error handling.
        if this_macro is not None: crash_out(raw_line, "can't nest macro definitions")

        this_macro = Macro(line_toks[1], line_toks[2:])

    elif line_toks[0] == "!End":
        if this_macro is None: crash_out(raw_line, "wasn't in a macro definition")

        macros[this_macro.name] = this_macro
        this_macro = None

    else:
        # Does it define a label?
        if line_toks[0].endswith(":"):
            # Yes, so store it.
            new_label_name = line_toks[0][:-1]
            if new_label_name[0] == "_": new_label_name = last_label + new_label_name
            else: last_label = new_label_name

            this_label = Label(new_label_name, this_region.origin)
            this_region.add(this_label)
            labels[this_label.name] = this_label
            line_toks = line_toks[1:]

        # Might be a label on its own line.
        if len(line_toks) == 0: continue

        # We'll deal with the rest later.
        this_statement = Statement(line_toks, raw_line)
        if this_macro is None:
            this_region.add(this_statement)
        else:
            this_macro.add(this_statement)



print(f"{len(macros)} macros, {len(labels)} labels, {len(regions)} regions")

for im in macros:
    m = macros[im]
    print(m.name)
    for s in m.contents:
        print(s)

print("---")

for il in labels:
    l = labels[il]
    print(l.name, l.width)

print("---")

for r in regions:
    print(r.origin)
    for s in r.statements:
        if isinstance(s, Label): print(s.name + ":")
        else: print(s.tokens)
