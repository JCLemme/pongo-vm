# PongoVM - Browser Edition

Complete JavaScript ports of the PongoVM assembler and emulator. Write, assemble, and run PongoVM programs entirely in your web browser - no installation required!

## What's Included

- **Assembler** (`index.html`) - Convert high-level instructions to bytecode
- **Emulator** (`emulator.html`) - Run programs with full visualization and debugging
- **Zero dependencies** - Pure JavaScript, just open in a browser

## Quick Start

1. Open `index.html` to write and assemble programs
2. Click "Load in Emulator" to run them
3. Or open `emulator.html` directly to load existing ROM files

---

# Assembler Documentation

This is a JavaScript port of the Common Lisp assembler from `environment.lisp`. It allows you to assemble PongoVM programs directly in a web browser.

## Quick Start

1. Open `index.html` in a web browser
2. Write or select an example program
3. Click "Assemble" to generate bytecode
4. View the hex output and download the binary

## Usage

### Opening the Assembler

Simply open `index.html` in any modern web browser. No build tools or npm required!

```bash
# From the web directory:
open index.html          # macOS
xdg-open index.html      # Linux
start index.html         # Windows
```

### Writing Programs

Programs are written in JavaScript using the `PongoAsm` API. Here's a simple example:

```javascript
const program = [
    PongoAsm.atOrigin(0x8000),
    ...PongoAsm.move(0x42, PongoAsm.REG_TMPA),
    ...PongoAsm.move(PongoAsm.REG_TMPA, PongoAsm.REG_TMPB),
    ...PongoAsm.halt()
];

assemble(program);
```

## API Reference

### Core Functions

#### `assemble(program)`
Assembles a program array into a 64KB binary.

```javascript
const binary = PongoAsm.assemble(program);
```

### Primitives

#### `atOrigin(address)`
Set the current assembly origin address.

```javascript
PongoAsm.atOrigin(0x8000)
```

#### `atLabel(name)`
Define a label at the current position.

```javascript
PongoAsm.atLabel('myLabel')
```

#### `label(name)`
Reference a label (resolves to its address).

```javascript
PongoAsm.label('myLabel')
```

#### `rawData(values)`
Insert raw byte data.

```javascript
PongoAsm.rawData([0x01, 0x02, 0x03])
PongoAsm.rawData(0x42)
```

### Instructions

#### `move(source, destination)`
Move data from source to destination.

```javascript
...PongoAsm.move(0x42, PongoAsm.REG_TMPA)           // Immediate to register
...PongoAsm.move(PongoAsm.REG_TMPA, PongoAsm.REG_TMPB)  // Register to register
```

#### `moveIf(source, destination)`
Conditional move (only if zero flag not set).

```javascript
...PongoAsm.moveIf(0x1000, PongoAsm.REG_IP)
```

#### `jumpTo(address)`
Unconditional jump.

```javascript
...PongoAsm.jumpTo(0x8000)
...PongoAsm.jumpTo(PongoAsm.label('start'))
```

#### `jumpIf(address)`
Conditional jump.

```javascript
...PongoAsm.jumpIf(PongoAsm.label('loop'))
```

### Control Flow

#### `loopForever(body)`
Infinite loop.

```javascript
...PongoAsm.loopForever([
    ...PongoAsm.move(0xFF, PongoAsm.REG_TMPA)
])
```

#### `loopFor(count, body)`
Loop for N iterations.

```javascript
...PongoAsm.loopFor(10, [
    ...PongoAsm.move(0xFF, PongoAsm.REG_TMPA),
    ...PongoAsm.indiPlusPlus()
])
```

#### `loopIf(body)`
Loop while condition is true.

```javascript
...PongoAsm.loopIf([
    ...PongoAsm.move(PongoAsm.EMUREG_BUTTONS_A, PongoAsm.REG_LOOPLO)
])
```

### Memory Operations

#### `memset(address, length, value)`
Fill memory with a value.

```javascript
...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0xEA)
```

#### `memcpy(source, destination, length)`
Copy memory.

```javascript
...PongoAsm.memcpy(0x8000, PongoAsm.EMUREG_VRAM, 1024)
```

#### `storeIndirect(value)`
Store value at address in indirect register.

```javascript
...PongoAsm.storeIndirect(0xFF)
```

#### `loadIndirect(destination)`
Load value from address in indirect register.

```javascript
...PongoAsm.loadIndirect(PongoAsm.REG_TMPA)
```

### Register Manipulation

#### `indiPlusPlus()`
Increment indirect register.

```javascript
...PongoAsm.indiPlusPlus()
```

#### `indiMinusMinus()`
Decrement indirect register.

```javascript
...PongoAsm.indiMinusMinus()
```

### Other

#### `halt()`
Halt execution (infinite empty loop).

```javascript
...PongoAsm.halt()
```

#### `waitForFrame()`
Wait for next video frame (emulator feature).

```javascript
...PongoAsm.waitForFrame()
```

## Registers

### General Purpose
- `REG_TMPA` - `REG_TMPE`: Temporary registers (5 available)
- `REG_OPA`, `REG_OPB`: Operand registers
- `REG_ADD`: Addition result register

### Special Registers
- `REG_IP` / `REG_IPLO` / `REG_IPHI`: Instruction pointer (16-bit / low / high)
- `REG_LOOP` / `REG_LOOPLO` / `REG_LOOPHI`: Loop counter (16-bit / low / high)
- `REG_INDI` / `REG_INDILO` / `REG_INDIHI`: Indirect pointer (16-bit / low / high)
- `REG_NAND`: NAND result register
- `REG_FLOW`: Flow control flags

### Emulator Registers
- `EMUREG_VRAM`: Video RAM start (0x4000)
- `EMUREG_PADDLE_A`, `EMUREG_PADDLE_B`: Paddle positions
- `EMUREG_BUTTONS_A`, `EMUREG_BUTTONS_B`: Button states
- `EMUREG_RANDOM`: Random number generator
- `EMUREG_FLOW`: Emulator flow control

## Type System

The assembler uses a type system to handle different addressing modes:

- `:val` - Immediate value (default)
- `:ptr` - Pointer/register address
- `:wid` - Wide (16-bit) value
- `:ind` - Indirect addressing

Use `asType(type, value)` to create typed values:

```javascript
const wideReg = PongoAsm.asType(':wid', PongoAsm.REG_TMPA);
const indirect = PongoAsm.asType(':ind', PongoAsm.REG_INDILO);
```

## Examples

See the `index.html` page for interactive examples, or check these patterns:

### Basic Program
```javascript
const program = [
    PongoAsm.atOrigin(0x8000),
    ...PongoAsm.move(42, PongoAsm.REG_TMPA),
    ...PongoAsm.halt()
];
```

### Using Labels
```javascript
const program = [
    PongoAsm.atOrigin(0x8000),
    PongoAsm.atLabel('start'),
    ...PongoAsm.move(0, PongoAsm.REG_TMPA),
    ...PongoAsm.jumpTo(PongoAsm.label('start'))
];
```

### Memory Operations
```javascript
const program = [
    PongoAsm.atOrigin(0x8000),

    // Fill VRAM with pattern
    ...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0xEA),

    // Wait for frame
    ...PongoAsm.waitForFrame(),

    ...PongoAsm.halt()
];
```

## Differences from Lisp Version

1. **Syntax**: JavaScript syntax instead of Lisp S-expressions
2. **Spread Operator**: Use `...` to flatten instruction arrays
3. **No REPL**: Programs are assembled in-browser, not at command line
4. **Type Strings**: Types use strings (`:ptr`) instead of keywords

## File Structure

```
web/
├── environment.js    # Core assembler library
├── index.html        # Interactive web interface
└── README.md         # This file
```

## Browser Compatibility

Works in all modern browsers that support:
- ES6 (arrow functions, const/let, template literals)
- Typed Arrays (Uint8Array)
- Map/Set

Tested in Chrome, Firefox, Safari, and Edge.
