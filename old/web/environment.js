/**
 * PongoVM Assembler - JavaScript Port
 * Converted from environment.lisp
 */

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Convert a number to instruction chunks
 * @param {number} num - 16-bit number to convert
 * @returns {number[]} Array of instruction chunks
 */
function numberToChunks(num) {
    const fat = num & 0xFFFF;
    const out0 = (fat >> 12) & 0xF;
    const out1 = (fat >> 6) & 0x3F;
    const out2 = fat & 0x3F;
    const isNegative = (fat & 0x8000) !== 0;

    if (isNegative) {
        if (out0 === 0xF && out1 === 0x3F && (out2 & 0x20) !== 0) {
            return [out2];
        } else if (out0 === 0xF && out1 === 0x3F && (out2 & 0x20) === 0) {
            return [0x3F, out2];
        } else if (out0 === 0xF && (out1 & 0x20) !== 0) {
            return [out1, out2];
        } else {
            return [out1, out0, out2];
        }
    } else {
        if (out0 === 0x0 && out1 === 0x00 && (out2 & 0x20) === 0) {
            return [out2];
        } else if (out0 === 0x0 && out1 === 0x00 && (out2 & 0x20) !== 0) {
            return [0, out2];
        } else if (out0 === 0x0 && (out1 & 0x20) === 0) {
            return [out1, out2];
        } else {
            return [out1, out0, out2];
        }
    }
}

// ============================================================================
// Opcodes
// ============================================================================

const OPCODE_A_PTR_TO_D = 0b00;  // Move value in address a to d
const OPCODE_A_TO_D = 0b01;       // Move literal a to d
const OPCODE_D_TO_A_PTR = 0b10;   // Move d to address a
const OPCODE_PUSH = 0b11;         // Push literal chunk to a

// ============================================================================
// Type System
// ============================================================================

/**
 * Extract value without type information
 * @param {number|Array} val - Value or [value, type] pair
 * @returns {number} Raw value
 */
function noType(val) {
    return Array.isArray(val) ? val[0] : val;
}

/**
 * Attach type information to a value
 * @param {string} typ - Type name (:val, :ptr, :wid, :ind)
 * @param {number} val - Value
 * @returns {Array} [value, type] pair
 */
function asType(typ, val) {
    return [noType(val), typ];
}

/**
 * Extract type information from a value
 * @param {number|Array} val - Value or [value, type] pair
 * @returns {string} Type name
 */
function extractType(val) {
    return Array.isArray(val) ? val[1] : ':val';
}

/**
 * Check if value has specific type
 * @param {string} typ - Type to check for
 * @param {number|Array} val - Value to check
 * @returns {boolean} True if value has the type
 */
function isType(typ, val) {
    return extractType(val) === typ;
}

// ============================================================================
// Raw Instruction Building
// ============================================================================

/**
 * Assemble a single raw instruction
 * @param {number} opcode - 2-bit opcode
 * @param {number} data - 6-bit data
 * @returns {number} 8-bit instruction
 */
function assembleOneRawInstruction(opcode, data) {
    return ((opcode & 0x3) << 6 | (data & 0x3F)) & 0xFF;
}

/**
 * Build raw instructions with automatic pushing
 * @param {number} opcode - Opcode for final instruction
 * @param {number[]} data - Data chunks
 * @returns {number[]} Array of assembled instructions
 */
function buildRawInstructions(opcode, data) {
    const instructions = [];

    // Push high chunks first (all but the last)
    if (data.length > 1) {
        for (let i = data.length - 1; i > 0; i--) {
            instructions.push(assembleOneRawInstruction(OPCODE_PUSH, data[i]));
        }
    }

    // Final instruction with the opcode
    instructions.push(assembleOneRawInstruction(opcode, data[0]));

    return instructions;
}

// ============================================================================
// Primitive Instruction Types
// ============================================================================

/**
 * Load from address to D register
 * @param {number|Array} addr - Address
 * @returns {number[]} Instruction bytes
 */
function aPtrToD(addr) {
    return buildRawInstructions(OPCODE_A_PTR_TO_D, numberToChunks(noType(addr)));
}

/**
 * Load immediate value to D register
 * @param {number|Array} val - Value
 * @returns {number[]} Instruction bytes
 */
function aToD(val) {
    return buildRawInstructions(OPCODE_A_TO_D, numberToChunks(noType(val)));
}

/**
 * Store D register to address
 * @param {number|Array} addr - Address
 * @returns {number[]} Instruction bytes
 */
function dToAPtr(addr) {
    return buildRawInstructions(OPCODE_D_TO_A_PTR, numberToChunks(noType(addr)));
}

/**
 * Push value to A register
 * @param {number|Array} val - Value
 * @returns {number} Instruction byte
 */
function pushA(val) {
    return assembleOneRawInstruction(OPCODE_PUSH, noType(val));
}

// ============================================================================
// Pseudoprimitives
// ============================================================================

/**
 * Raw data insertion
 * @param {number|number[]} val - Value or array of values
 * @returns {Object} Primitive descriptor
 */
function rawData(val) {
    return {
        type: 'raw-data',
        data: Array.isArray(val) ? val : [val]
    };
}

/**
 * Set origin address
 * @param {number} val - Origin address
 * @returns {Object} Primitive descriptor
 */
function atOrigin(val) {
    return {
        type: 'at-origin',
        address: val
    };
}

/**
 * Define a label
 * @param {string} name - Label name
 * @returns {Object} Primitive descriptor
 */
function atLabel(name) {
    return {
        type: 'at-label',
        name: name
    };
}

/**
 * Reference a label
 * @param {string} name - Label name
 * @returns {Object} Label reference
 */
function label(name) {
    return {
        type: 'label-ref',
        name: name
    };
}

// ============================================================================
// Unique ID Generator
// ============================================================================

let uniqueCallsCounter = 0;

/**
 * Generate a unique identifier
 * @param {string} prefix - Prefix for the ID
 * @returns {string} Unique ID
 */
function uniqueId(prefix) {
    return prefix + (uniqueCallsCounter++);
}

// ============================================================================
// Register and Flag Constants
// ============================================================================

// Registers
const REG_IPLO = asType(':ptr', 0x0);     // Instruction pointer, low byte
const REG_IPHI = asType(':ptr', 0x1);     // Instruction pointer, high byte
const REG_LOOPLO = asType(':ptr', 0x2);   // Loop register, low byte
const REG_LOOPHI = asType(':ptr', 0x3);   // Loop register, high byte
const REG_INDILO = asType(':ptr', 0x4);   // Indirect register, low byte
const REG_INDIHI = asType(':ptr', 0x5);   // Indirect register, high byte
const REG_NAND = asType(':ptr', 0x6);     // Bitwise NAND of IndiLo and IndiHi
const REG_FLOW = asType(':ptr', 0x7);     // Processor control flow bits

// Flow flags
const FLOW_SIXTEEN_WIDE = 0x01;
const FLOW_INHIBIT_IF_ZERO = 0x02;
const FLOW_LOOP_DOWN = 0x04;
const FLOW_INDIRECT_UP = 0x08;
const FLOW_STORE_INDIRECT = 0x10;
const FLOW_LOAD_INDIRECT = 0x20;
const FLOW_INDIRECT_DOWN = 0x40;
const FLOW_UNUSED = 0x80;

// Emulator registers
const EMUREG_VRAM = 0x4000;
const EMUREG_PADDLE_A = asType(':ptr', 0x4400);
const EMUREG_BUTTONS_A = asType(':ptr', 0x4401);
const EMUREG_PADDLE_B = asType(':ptr', 0x4402);
const EMUREG_BUTTONS_B = asType(':ptr', 0x4403);
const EMUREG_RANDOM = asType(':ptr', 0x4404);
const EMUREG_FLOW = asType(':ptr', 0x4407);

// Emulator flow flags
const EMUFLOW_WAIT_FRAME = 0x01;

// Wide registers
const REG_IP = asType(':wid', REG_IPLO);
const REG_LOOP = asType(':wid', REG_LOOPLO);
const REG_INDI = asType(':wid', REG_INDILO);

// Other registers
const REG_OPA = asType(':ptr', 0x8);
const REG_OPB = asType(':ptr', 0x9);
const REG_ADD = asType(':ptr', 0xa);
const REG_TMPA = asType(':ptr', 0xb);
const REG_TMPB = asType(':ptr', 0xc);
const REG_TMPC = asType(':ptr', 0xd);
const REG_TMPD = asType(':ptr', 0xe);
const REG_TMPE = asType(':ptr', 0xf);

// ============================================================================
// High-Level Instructions (Macro System)
// ============================================================================

/**
 * Helper to evaluate a value (resolve labels at assembly time)
 */
function evalValue(val, labelMapping) {
    if (val && typeof val === 'object' && val.type === 'label-ref') {
        const resolved = labelMapping.get(val.name);
        if (resolved === undefined) {
            throw new Error(`Undefined label: ${val.name}`);
        }
        return resolved;
    }
    return val;
}

/**
 * Set flow flags
 * @param {number} mask - Flag mask
 * @returns {Object[]} Instruction sequence
 */
function doFlow(mask) {
    return [
        { fn: aToD, args: [mask] },
        { fn: dToAPtr, args: [noType(REG_FLOW)] }
    ];
}

/**
 * Set emulator flow flags
 * @param {number} mask - Flag mask
 * @returns {Object[]} Instruction sequence
 */
function doEmuflow(mask) {
    return [
        { fn: aToD, args: [mask] },
        { fn: dToAPtr, args: [noType(EMUREG_FLOW)] }
    ];
}

/**
 * Move operation with automatic flag setting
 * @param {number} flags - Initial flags
 * @param {*} left - Source
 * @param {*} right - Destination
 * @returns {Object[]} Instruction sequence
 */
function doMove(flags, left, right) {
    let cflags = flags;

    // Set flags based on types
    if (isType(':ind', left)) cflags |= FLOW_LOAD_INDIRECT;
    if (isType(':ind', right)) cflags |= FLOW_STORE_INDIRECT;
    if (isType(':wid', left)) cflags |= FLOW_SIXTEEN_WIDE;
    if (isType(':wid', right)) cflags |= FLOW_SIXTEEN_WIDE;

    const instructions = [];

    // Set flags if needed
    if (cflags !== 0) {
        instructions.push(...doFlow(cflags));
    }

    // Load from source
    const isPointerLike = isType(':ptr', left) || isType(':wid', left) || isType(':ind', left);
    instructions.push({
        fn: isPointerLike ? aPtrToD : aToD,
        args: [left]
    });

    // Store to destination
    instructions.push({ fn: dToAPtr, args: [right] });

    return instructions;
}

/**
 * Basic move instruction
 */
function move(left, right) {
    return doMove(0, left, right);
}

/**
 * Conditional move instruction
 */
function moveIf(left, right) {
    return doMove(FLOW_INHIBIT_IF_ZERO, left, right);
}

/**
 * Jump to address
 */
function jumpTo(addr) {
    return move(addr, REG_IP);
}

/**
 * Conditional jump
 */
function jumpIf(addr) {
    return moveIf(addr, REG_IP);
}

/**
 * Infinite loop
 * @param {Object[]} body - Loop body instructions
 * @returns {Object[]} Instruction sequence
 */
function loopForever(body) {
    const begl = uniqueId('lfv-beg');
    const endl = uniqueId('lfv-end');

    return [
        atLabel(begl),
        ...body,
        ...jumpTo(label(begl)),
        atLabel(endl)
    ];
}

/**
 * Loop for N iterations
 * @param {number} len - Loop count
 * @param {Object[]} body - Loop body instructions
 * @returns {Object[]} Instruction sequence
 */
function loopFor(len, body) {
    const begl = uniqueId('lfr-beg');
    const endl = uniqueId('lfr-end');

    return [
        ...move(len, REG_LOOP),
        atLabel(begl),
        ...body,
        ...doFlow(FLOW_LOOP_DOWN),
        ...jumpIf(label(begl)),
        atLabel(endl)
    ];
}

/**
 * Loop while condition is true
 * @param {Object[]} body - Loop body instructions
 * @returns {Object[]} Instruction sequence
 */
function loopIf(body) {
    const begl = uniqueId('lfv-beg');
    const endl = uniqueId('lfv-end');

    return [
        ...move(0x0000, REG_LOOP),
        atLabel(begl),
        ...body,
        ...jumpIf(label(begl)),
        atLabel(endl)
    ];
}

/**
 * Store value via indirect register
 */
function storeIndirect(left) {
    return move(left, asType(':ind', REG_INDILO));
}

/**
 * Load value via indirect register
 */
function loadIndirect(right) {
    return move(asType(':ind', REG_INDILO), right);
}

/**
 * Increment indirect register
 */
function indiPlusPlus() {
    return doFlow(FLOW_INDIRECT_UP);
}

/**
 * Decrement indirect register
 */
function indiMinusMinus() {
    return doFlow(FLOW_INDIRECT_DOWN);
}

/**
 * Decrement loop register
 */
function loopMinusMinus() {
    return doFlow(FLOW_LOOP_DOWN);
}

/**
 * Fill memory with a value
 * @param {number} addr - Start address
 * @param {number} len - Number of bytes
 * @param {number} val - Value to write
 * @returns {Object[]} Instruction sequence
 */
function memset(addr, len, val) {
    return [
        ...move(addr, REG_INDI),
        ...loopFor(len, [
            ...storeIndirect(val),
            ...indiPlusPlus()
        ])
    ];
}

/**
 * Copy memory
 * @param {number} src - Source address
 * @param {number} dest - Destination address
 * @param {number} len - Number of bytes
 * @returns {Object[]} Instruction sequence
 */
function memcpy(src, dest, len) {
    return [
        ...move(src, asType(':wid', REG_TMPB)),
        ...move(dest, asType(':wid', REG_TMPD)),
        ...loopFor(len, [
            ...move(asType(':wid', REG_TMPD), REG_INDI),
            ...loadIndirect(REG_TMPA),
            ...indiPlusPlus(),
            ...move(REG_INDI, asType(':wid', REG_TMPD)),

            ...move(asType(':wid', REG_TMPB), REG_INDI),
            ...storeIndirect(REG_TMPA),
            ...indiPlusPlus(),
            ...move(REG_INDI, asType(':wid', REG_TMPB))
        ])
    ];
}

/**
 * Addition operation
 */
function doAdd() {
    return [
        ...move(REG_OPA, REG_INDILO),
        ...loopFor(REG_OPB, [
            ...indiPlusPlus()
        ]),
        ...move(REG_INDILO, REG_ADD)
    ];
}

/**
 * Halt execution
 */
function halt() {
    return loopForever([]);
}

/**
 * Wait for next frame
 */
function waitForFrame() {
    return doEmuflow(EMUFLOW_WAIT_FRAME);
}

// ============================================================================
// Assembler
// ============================================================================

/**
 * Flatten instruction tree into primitives
 * @param {*} program - Program structure
 * @returns {Array} Flattened primitives
 */
function decompose(program) {
    if (!Array.isArray(program)) {
        return [];
    }

    const result = [];

    for (const item of program) {
        if (!item) continue;

        if (typeof item === 'object' && item.type) {
            // It's a primitive (at-origin, at-label, raw-data, label-ref)
            result.push(item);
        } else if (typeof item === 'object' && item.fn) {
            // It's an instruction descriptor
            result.push(item);
        } else if (Array.isArray(item)) {
            // Recursively decompose
            result.push(...decompose(item));
        } else {
            result.push(item);
        }
    }

    return result;
}

/**
 * First pass: identify all labels
 * @param {Array} statements - Decomposed statements
 * @param {Map} labelMapping - Label map to populate
 */
function labelPass(statements, labelMapping) {
    for (const stm of statements) {
        if (stm && stm.type === 'at-label') {
            // Fill with dummy value for size calculation
            labelMapping.set(stm.name, 0xEAEA);
        }
    }
}

/**
 * Second pass: calculate label positions
 * @param {Array} statements - Decomposed statements
 * @param {Map} labelMapping - Label map to update
 */
function spacingPass(statements, labelMapping) {
    let currentOrigin = 0;

    for (const stm of statements) {
        if (!stm) continue;

        if (stm.type === 'at-label') {
            labelMapping.set(stm.name, currentOrigin);
        } else if (stm.type === 'at-origin') {
            currentOrigin = stm.address;
        } else if (stm.type === 'raw-data') {
            currentOrigin += stm.data.length;
        } else if (stm.fn) {
            // Evaluate instruction to get length
            const resolved = stm.args.map(arg => evalValue(arg, labelMapping));
            const bytes = stm.fn(...resolved);
            currentOrigin += bytes.length;
        }
    }
}

/**
 * Third pass: generate binary
 * @param {Array} statements - Decomposed statements
 * @param {Map} labelMapping - Label map with final addresses
 * @returns {Uint8Array} Binary output
 */
function binaryPass(statements, labelMapping) {
    const outBin = new Uint8Array(65536);
    let currentOrigin = 0;

    for (const stm of statements) {
        if (!stm) continue;

        if (stm.type === 'at-label') {
            // Labels don't generate code
            continue;
        } else if (stm.type === 'at-origin') {
            currentOrigin = stm.address;
        } else if (stm.type === 'raw-data') {
            for (const byte of stm.data) {
                outBin[currentOrigin++] = byte & 0xFF;
            }
        } else if (stm.fn) {
            // Evaluate instruction
            const resolved = stm.args.map(arg => evalValue(arg, labelMapping));
            const bytes = stm.fn(...resolved);
            for (const byte of bytes) {
                outBin[currentOrigin++] = byte & 0xFF;
            }
        }
    }

    return outBin;
}

/**
 * Main assembler function
 * @param {Array} program - Program structure (array of instruction calls)
 * @returns {Uint8Array} Assembled binary
 */
function assemble(program) {
    // Reset unique counter for consistent output
    uniqueCallsCounter = 0;

    // Decompose program into flat list
    const decomposed = decompose(program);

    // Create label mapping
    const labelMapping = new Map();

    // Three-pass assembly
    labelPass(decomposed, labelMapping);
    spacingPass(decomposed, labelMapping);
    const binary = binaryPass(decomposed, labelMapping);

    return binary;
}

// ============================================================================
// Exports
// ============================================================================

// Export everything for use in browser
if (typeof window !== 'undefined') {
    window.PongoAsm = {
        // Utilities
        numberToChunks,
        noType,
        asType,
        extractType,
        isType,
        uniqueId,

        // Primitives
        aPtrToD,
        aToD,
        dToAPtr,
        pushA,
        rawData,
        atOrigin,
        atLabel,
        label,

        // Constants
        OPCODE_A_PTR_TO_D,
        OPCODE_A_TO_D,
        OPCODE_D_TO_A_PTR,
        OPCODE_PUSH,

        // Registers
        REG_IPLO, REG_IPHI, REG_LOOPLO, REG_LOOPHI,
        REG_INDILO, REG_INDIHI, REG_NAND, REG_FLOW,
        REG_IP, REG_LOOP, REG_INDI,
        REG_OPA, REG_OPB, REG_ADD,
        REG_TMPA, REG_TMPB, REG_TMPC, REG_TMPD, REG_TMPE,

        // Emulator registers
        EMUREG_VRAM, EMUREG_PADDLE_A, EMUREG_BUTTONS_A,
        EMUREG_PADDLE_B, EMUREG_BUTTONS_B, EMUREG_RANDOM,
        EMUREG_FLOW,

        // Flags
        FLOW_SIXTEEN_WIDE, FLOW_INHIBIT_IF_ZERO, FLOW_LOOP_DOWN,
        FLOW_INDIRECT_UP, FLOW_STORE_INDIRECT, FLOW_LOAD_INDIRECT,
        FLOW_INDIRECT_DOWN, FLOW_UNUSED,
        EMUFLOW_WAIT_FRAME,

        // High-level instructions
        doFlow,
        doEmuflow,
        doMove,
        move,
        moveIf,
        jumpTo,
        jumpIf,
        loopForever,
        loopFor,
        loopIf,
        storeIndirect,
        loadIndirect,
        indiPlusPlus,
        indiMinusMinus,
        loopMinusMinus,
        memset,
        memcpy,
        doAdd,
        halt,
        waitForFrame,

        // Assembler
        assemble,
        decompose
    };
}
