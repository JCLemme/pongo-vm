/**
 * PongoVM Emulator - JavaScript Port
 * Converted from pongofour.py
 */

// ============================================================================
// Opcodes
// ============================================================================

const Opcodes = {
    AsMovD: 0b00,  // Move value at address A to D
    AMovD:  0b01,  // Move literal A to D
    DMovAs: 0b10,  // Move D to address A
    PushA:  0b11   // Push to A register
};

// ============================================================================
// Register Addresses
// ============================================================================

const Regs = {
    IpLo:    0,  // Instruction pointer, low byte
    IpHi:    1,  // Instruction pointer, high byte
    LoopLo:  2,  // Loop register, low byte
    LoopHi:  3,  // Loop register, high byte
    IndiLo:  4,  // Indirect register, low byte
    IndiHi:  5,  // Indirect register, high byte
    Nand:    6,  // NAND computation register
    Flow:    7   // Flow control register
};

// ============================================================================
// Flow Control Flags
// ============================================================================

const FlowLines = {
    SixteenWide:   0x01,  // Next operation is 16-bit
    InhibitIfZero: 0x02,  // Block next D>A* if loop register is zero
    LoopDown:      0x04,  // Decrement loop register
    IndirectUp:    0x08,  // Increment indirect register
    StoreIndirect: 0x10,  // Next D>A* uses indirect register
    LoadIndirect:  0x20,  // Next A*>D uses indirect register
    IndirectDown:  0x40,  // Decrement indirect register
    WaitForFrame:  0x80   // Pause execution until next frame
};

// ============================================================================
// PongoCore Emulator
// ============================================================================

class PongoCore {
    /**
     * Create a new PongoVM core
     * @param {Uint8Array|Array} rom - ROM data (should be 32KB, loaded at $8000)
     * @param {Function} ioHandler - I/O handler function(addr, data=undefined)
     */
    constructor(rom, ioHandler = null) {
        this.rom = new Uint8Array(32768);

        // Copy ROM data
        if (rom) {
            for (let i = 0; i < Math.min(rom.length, 32768); i++) {
                this.rom[i] = rom[i] & 0xFF;
            }
        }

        this.ioHandler = ioHandler;
        this.reset(true);
    }

    /**
     * Reset the core state
     * @param {boolean} alsoRam - Whether to also clear RAM
     */
    reset(alsoRam = false) {
        if (alsoRam) {
            this.ram = new Uint8Array(16384);
        }

        // Set IP to $8000 (ROM start)
        this.ram[Regs.IpHi] = 0x80;
        this.ram[Regs.IpLo] = 0x00;

        this.a = 0;
        this.d = 0;
        this.numPushes = 0;
        this.nextSixteen = false;
        this.nextLoadIndirect = false;
        this.nextStoreIndirect = false;
        this.nextInhibit = false;
    }

    /**
     * Calculate final A value with sign extension
     * @param {number} instA - 6-bit value from instruction
     * @returns {number} Sign-extended 16-bit value
     */
    finalA(instA) {
        let calcA = (this.a | instA) & 0xFFFF;

        if (this.numPushes === 0) {
            // 6-bit value with sign extension
            if (calcA & 0x0020) {
                return calcA | (~0x3F & 0xFFFF);
            } else {
                return calcA & 0x3F;
            }
        } else if (this.numPushes === 1) {
            // 12-bit value with sign extension
            if (calcA & 0x0800) {
                return calcA | (~0xFFF & 0xFFFF);
            } else {
                return calcA & 0xFFF;
            }
        } else if (this.numPushes === 2) {
            // Full 16-bit value
            return calcA;
        } else {
            console.warn("Too many pushes in a row");
            return calcA;
        }
    }

    /**
     * Increment a 16-bit counter register
     * @param {number} baseAddr - Base address of the counter (low byte)
     */
    counterUp(baseAddr) {
        let thisByte = (this.ram[baseAddr] + 1) & 0xFF;
        this.ram[baseAddr] = thisByte;

        if (thisByte === 0x00) {
            thisByte = (this.ram[baseAddr + 1] + 1) & 0xFF;
            this.ram[baseAddr + 1] = thisByte;
        }
    }

    /**
     * Decrement a 16-bit counter register
     * @param {number} baseAddr - Base address of the counter (low byte)
     */
    counterDown(baseAddr) {
        let thisByte = (this.ram[baseAddr] - 1) & 0xFF;
        this.ram[baseAddr] = thisByte;

        if (thisByte === 0xFF) {
            thisByte = (this.ram[baseAddr + 1] - 1) & 0xFF;
            this.ram[baseAddr + 1] = thisByte;
        }
    }

    /**
     * Get a byte from memory
     * @param {number} addr - 16-bit address
     * @returns {number} Byte value
     */
    get(addr) {
        addr &= 0xFFFF;

        if (addr < 16384) {
            // RAM ($0000 - $3FFF)
            if (addr === Regs.Nand) {
                // Special register: NAND of IndiLo and IndiHi
                return (~(this.ram[Regs.IndiLo] & this.ram[Regs.IndiHi])) & 0xFF;
            } else if (addr === Regs.Flow) {
                // Special register: Rotate right
                return ((this.ram[Regs.IndiLo] >> 1) |
                        (this.ram[Regs.IndiLo] & 0x1 ? 0x80 : 0x00)) & 0xFF;
            } else {
                return this.ram[addr] & 0xFF;
            }
        } else if (addr < 32768) {
            // I/O region ($4000 - $7FFF)
            if (this.ioHandler) {
                return this.ioHandler(addr - 16384) & 0xFF;
            } else {
                return 0xEA; // Default I/O value
            }
        } else if (addr < 65536) {
            // ROM ($8000 - $FFFF)
            return this.rom[addr - 32768] & 0xFF;
        } else {
            console.warn("Read out of bounds:", addr);
            return 0;
        }
    }

    /**
     * Set a byte in memory
     * @param {number} addr - 16-bit address
     * @param {number} data - Byte value to write
     */
    set(addr, data) {
        addr &= 0xFFFF;
        data &= 0xFF;

        if (addr < 16384) {
            // RAM ($0000 - $3FFF)
            this.ram[addr] = data;

            // Handle flow control register writes
            if (addr === Regs.Flow) {
                if (data & FlowLines.SixteenWide) this.nextSixteen = true;
                if (data & FlowLines.InhibitIfZero) this.nextInhibit = true;
                if (data & FlowLines.LoadIndirect) this.nextLoadIndirect = true;
                if (data & FlowLines.StoreIndirect) this.nextStoreIndirect = true;

                if (data & FlowLines.LoopDown) this.counterDown(Regs.LoopLo);
                if (data & FlowLines.IndirectUp) this.counterUp(Regs.IndiLo);
                if (data & FlowLines.IndirectDown) this.counterDown(Regs.IndiLo);
            }
        } else if (addr < 32768) {
            // I/O region ($4000 - $7FFF)
            if (this.ioHandler) {
                this.ioHandler((addr - 16384) & 0xFFFF, data);
            }
        } else {
            console.warn("Write to ROM ignored:", addr);
        }
    }

    /**
     * Execute a single instruction
     */
    spin() {
        const thisIp = (this.get(Regs.IpHi) << 8) | this.get(Regs.IpLo);
        const thisInst = this.get(thisIp);
        const thisOpcode = thisInst >> 6;
        const thisData = thisInst & 0x3F;

        // Increment instruction pointer
        this.counterUp(Regs.IpLo);

        if (thisOpcode === Opcodes.PushA) {
            // Push data to A register
            if (this.numPushes % 2 === 0) {
                this.a = (this.a & ~0xFC0) | (thisData << 6);
            } else {
                this.a = (this.a & ~0xF000) | (thisData << 12);
            }
            this.numPushes++;

        } else if (thisOpcode === Opcodes.AMovD) {
            // Move literal A to D
            this.d = this.finalA(thisData);
            this.numPushes = 0;

        } else {
            // AsMovD or DMovAs
            let thisAddress = this.finalA(thisData);
            const doSixteen = this.nextSixteen;

            if (thisOpcode === Opcodes.AsMovD) {
                // Load from address to D
                if (this.nextLoadIndirect) {
                    thisAddress = (this.get(Regs.IndiHi) << 8) | this.get(Regs.IndiLo);
                    this.nextLoadIndirect = false;
                }

                let newData = this.get(thisAddress);
                if (doSixteen) {
                    newData = (this.get(thisAddress + 1) << 8) | newData;
                }
                this.d = newData;

            } else if (thisOpcode === Opcodes.DMovAs) {
                // Store D to address
                let shouldMove = true;

                if (this.nextInhibit) {
                    const thisLoop = (this.get(Regs.LoopHi) << 8) | this.get(Regs.LoopLo);
                    if (thisLoop === 0) shouldMove = false;
                    this.nextInhibit = false;
                }

                if (shouldMove) {
                    if (this.nextStoreIndirect) {
                        thisAddress = (this.get(Regs.IndiHi) << 8) | this.get(Regs.IndiLo);
                        this.nextStoreIndirect = false;
                    }

                    this.set(thisAddress, this.d);
                    if (doSixteen) {
                        this.set(thisAddress + 1, this.d >> 8);
                    }
                }

                // Clear sixteen flag after store
                if (doSixteen) this.nextSixteen = false;
            }

            this.numPushes = 0;
        }

        this.a &= 0xFFFF;
        this.d &= 0xFFFF;
    }

    /**
     * Get a copy of current state for debugging
     */
    getState() {
        const ip = (this.get(Regs.IpHi) << 8) | this.get(Regs.IpLo);
        const loop = (this.get(Regs.LoopHi) << 8) | this.get(Regs.LoopLo);
        const indi = (this.get(Regs.IndiHi) << 8) | this.get(Regs.IndiLo);

        return {
            ip: ip,
            a: this.a,
            d: this.d,
            loop: loop,
            indi: indi,
            instruction: this.get(ip),
            flags: {
                sixteen: this.nextSixteen,
                inhibit: this.nextInhibit,
                loadIndirect: this.nextLoadIndirect,
                storeIndirect: this.nextStoreIndirect
            },
            tmpRegs: {
                tmpA: this.ram[0xb],
                tmpB: this.ram[0xc],
                tmpC: this.ram[0xd],
                tmpD: this.ram[0xe],
                tmpE: this.ram[0xf]
            }
        };
    }
}

// ============================================================================
// Disassembler Utility
// ============================================================================

/**
 * Disassemble a single instruction byte
 * @param {number} inst - Instruction byte
 * @returns {string} Disassembled instruction
 */
function disassemble(inst) {
    const opcode = inst >> 6;
    const data = inst & 0x3F;

    switch (opcode) {
        case Opcodes.AsMovD:
            return `A*[${data.toString(16).padStart(2, '0')}] > D`;
        case Opcodes.AMovD:
            return `A[${data.toString(16).padStart(2, '0')}] > D`;
        case Opcodes.DMovAs:
            return `D > A*[${data.toString(16).padStart(2, '0')}]`;
        case Opcodes.PushA:
            return `PUSH[${data.toString(16).padStart(2, '0')}] > A`;
        default:
            return `???[${inst.toString(16).padStart(2, '0')}]`;
    }
}

// ============================================================================
// Exports
// ============================================================================

if (typeof window !== 'undefined') {
    window.PongoEmu = {
        PongoCore,
        Opcodes,
        Regs,
        FlowLines,
        disassemble
    };
}
