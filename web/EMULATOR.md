# PongoVM Emulator - Browser Edition

A complete JavaScript port of the Python-based PongoVM emulator. Run your assembled programs directly in the browser with full visualization and debugging capabilities.

## Quick Start

1. Open `emulator.html` in a web browser
2. Load a ROM file or use a quick example
3. Click "Start" to run the program
4. Watch the 32x32 display come to life!

## Features

### Display
- **32x32 pixel display** with 256-color palette (XTerm colors)
- **16x zoom** for easy viewing
- Real-time canvas rendering
- Smooth 60 FPS animation

### Input Devices
- **Paddle A**: Mouse X position (0-31)
- **Paddle B**: Mouse Y position (0-31)
- **Button A**: Left mouse button
- **Button B**: Right mouse button
- **Random**: Hardware random number generator

### Controls

#### Execution
- **Start/Pause**: Toggle program execution
- **Step**: Execute a single instruction
- **Reset**: Reset CPU and clear memory
- **Stop**: Stop execution

#### Loading Programs
- **Load ROM**: Load a `.bin` file from disk
- **From Assembler**: Load from the assembler page (via localStorage)
- **Quick Examples**: Built-in test programs

#### Speed Control
- Adjustable execution speed (1-10,000 instructions per frame)
- Configurable target framerate
- Real-time performance monitoring

### Debug Interface

#### CPU State Display
- **IP (Program Counter)**: Current instruction address
- **A Register**: Accumulator register
- **D Register**: Data register
- **Loop Counter**: Loop iteration counter
- **Indirect Pointer**: Memory pointer for indirect ops

#### Live Debugging
- **Current instruction** disassembly
- **CPU flags** visualization (16W, INH, LDI, STI)
- **Temp registers** (TmpA-E) display
- **Cycle counter** for performance tracking

## Memory Map

```
$0000 - $3FFF   RAM (16 KB)
  $0000 - $0007   Special registers (IP, Loop, Indi, Nand, Flow)
  $0008 - $000F   General purpose registers
  $0010 - $3FFF   General RAM

$4000 - $7FFF   I/O Region (16 KB)
  $4000 - $43FF   VRAM (1024 bytes = 32x32 display)
  $4400           Paddle A position
  $4401           Button A state
  $4402           Paddle B position
  $4403           Button B state
  $4404           Random number
  $4407           Emulator flow control

$8000 - $FFFF   ROM (32 KB)
```

## Quick Examples

### Fill Screen
Fills the entire display with a solid color (0xEA - cyan):
```javascript
...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0xEA)
```

### Pattern
Generates a gradient pattern based on memory address:
```javascript
...PongoAsm.move(PongoAsm.EMUREG_VRAM, PongoAsm.REG_INDI),
...PongoAsm.loopFor(1024, [
    ...PongoAsm.move(PongoAsm.REG_INDILO, PongoAsm.REG_TMPA),
    ...PongoAsm.storeIndirect(PongoAsm.REG_TMPA),
    ...PongoAsm.indiPlusPlus()
])
```

### Counter
Animated counter that increments every frame:
```javascript
...PongoAsm.move(PongoAsm.REG_INDILO, PongoAsm.asType(':ptr', PongoAsm.EMUREG_VRAM)),
...PongoAsm.indiPlusPlus(),
...PongoAsm.waitForFrame()
```

## CPU Architecture

### Registers (8-bit unless noted)

**Special Registers:**
- `IpLo/IpHi`: 16-bit instruction pointer
- `LoopLo/LoopHi`: 16-bit loop counter
- `IndiLo/IndiHi`: 16-bit indirect pointer
- `Nand`: Computed NAND of IndiLo & IndiHi
- `Flow`: Flow control flags

**General Registers:**
- `TmpA-E`: 5 temporary registers
- `OpA, OpB`: Operand registers
- `Add`: Addition result register

### Instruction Set

#### Opcodes (2-bit opcode + 6-bit data)

```
00 (AsMovD): Load from address A to D
01 (AMovD):  Load immediate A to D
10 (DMovAs): Store D to address A
11 (PushA):  Push chunk to A register
```

#### Flow Control Flags

```
0x01: SixteenWide   - Next operation is 16-bit
0x02: InhibitIfZero - Block next store if Loop == 0
0x04: LoopDown      - Decrement Loop register
0x08: IndirectUp    - Increment Indi register
0x10: StoreIndirect - Next store uses Indi
0x20: LoadIndirect  - Next load uses Indi
0x40: IndirectDown  - Decrement Indi register
0x80: WaitForFrame  - Pause until next frame
```

### Number Encoding

The CPU uses a chunked encoding system for multi-byte values:
- **6-bit**: Single byte, sign-extended
- **12-bit**: Two bytes via PUSH
- **16-bit**: Three bytes via two PUSHes

## Emulator I/O

### VRAM (Display Memory)
Writing to addresses `$4000-$43FF` updates the display:
- Each byte is a color index (0-255)
- Display is 32x32 pixels
- Address = `$4000 + (y * 32 + x)`
- Uses XTerm 256-color palette

### Input Devices
Reading from I/O addresses:
- `$4400`: Paddle A (mouse X, 0-31)
- `$4401`: Button A (left click, 0 or 1)
- `$4402`: Paddle B (mouse Y, 0-31)
- `$4403`: Button B (right click, 0 or 1)
- `$4404`: Random (0-255)

### Frame Synchronization
Writing `0x01` to `$4407` pauses execution until next frame.
This allows smooth 60 FPS animation.

## Loading Programs

### From Assembler
1. Write code in `index.html` (assembler page)
2. Click "Assemble"
3. Click "Load in Emulator"
4. Emulator opens with program loaded

### From File
1. Click "Load ROM" in emulator
2. Select a `.bin` file (64KB format)
3. Program loads at `$8000`

### Quick Examples
Click any quick example button to load and run immediately.

## Performance

The emulator includes automatic benchmarking:
- Measures instruction throughput
- Adjusts speed for target framerate
- Typical performance: 10,000+ instructions/frame

Default setting: 1,000 instructions per frame at ~75 FPS

## Keyboard Shortcuts

- **P**: Toggle pause/run (if implemented)
- **O**: Toggle debug output (if implemented)
- **Escape**: Stop emulator (if implemented)

## Browser Compatibility

Requires modern browser with:
- Canvas 2D API
- ES6 JavaScript
- RequestAnimationFrame
- Uint8Array

Tested in Chrome, Firefox, Safari, and Edge.

## Architecture Notes

### Instruction Execution Flow

1. **Fetch**: Read instruction at IP
2. **Decode**: Extract opcode and data
3. **Execute**: Perform operation
4. **Increment**: Update IP
5. **Flags**: Process flow control flags

### Memory Access

- RAM reads/writes are direct
- I/O reads/writes call `ioHandler`
- ROM is read-only
- Special registers computed on read

### Sign Extension

Values are sign-extended based on push count:
- 0 pushes: 6-bit (bit 5 is sign)
- 1 push: 12-bit (bit 11 is sign)
- 2 pushes: 16-bit (full value)

## Differences from Python Version

1. **No Pygame**: Uses HTML Canvas instead
2. **No File I/O**: Uses File API and localStorage
3. **Palette**: Simplified XTerm color generation
4. **Timing**: Uses requestAnimationFrame instead of pygame.time
5. **Input**: Mouse instead of keyboard for paddle simulation

## File Structure

```
web/
├── emulator.js      # Core emulator (PongoCore class)
├── emulator.html    # Emulator UI and controls
├── environment.js   # Assembler (for quick examples)
└── EMULATOR.md      # This file
```

## Tips & Tricks

### Debugging
- Use "Step" to execute one instruction at a time
- Watch the flags to understand control flow
- Check temp registers for intermediate values

### Performance
- Lower instructions/frame for easier debugging
- Raise instructions/frame for full-speed execution
- Watch cycle counter to optimize loops

### Programming
- Use `waitForFrame()` for animation
- Read paddles for interactive programs
- Use indirect addressing for efficient loops
- Remember: 16-bit operations auto-clear the flag

## Example: Interactive Drawing

```javascript
const program = [
    PongoAsm.atOrigin(0x8000),
    PongoAsm.atLabel('loop'),

    // Get paddle positions
    ...PongoAsm.move(PongoAsm.EMUREG_PADDLE_A, PongoAsm.REG_TMPA),
    ...PongoAsm.move(PongoAsm.EMUREG_PADDLE_B, PongoAsm.REG_TMPB),

    // Calculate address: VRAM + (y * 32 + x)
    // ... (address calculation logic)

    // Draw pixel if button pressed
    ...PongoAsm.move(PongoAsm.EMUREG_BUTTONS_A, PongoAsm.REG_TMPC),
    // ... (conditional draw logic)

    ...PongoAsm.waitForFrame(),
    ...PongoAsm.jumpTo(PongoAsm.label('loop'))
];
```

## Contributing

Found a bug? Want to add features?
- The emulator is fully self-contained
- No build process required
- Just edit and refresh!

## License

Same as the original PongoVM project.
