# PongoVM Browser Suite

Welcome to the complete browser-based development environment for PongoVM!

## 🚀 What You Have

A complete suite of tools for developing and running PongoVM programs, all running in your browser:

### 1. **Assembler** - `index.html`
Convert high-level assembly code to PongoVM bytecode
- Interactive code editor
- Real-time assembly
- Hex dump viewer
- Binary download
- Direct emulator integration

### 2. **Emulator** - `emulator.html`
Run and debug PongoVM programs
- 32x32 pixel display (256 colors)
- Mouse input (paddles & buttons)
- CPU state visualization
- Step-by-step debugging
- Adjustable execution speed
- Built-in examples

### 3. **Development Libraries**
- `environment.js` - Assembler core
- `emulator.js` - CPU emulation

## 📖 Documentation

- **README.md** - Assembler API reference
- **EMULATOR.md** - Emulator usage guide
- **INDEX.md** - This file

## 🎯 Workflow

### Writing Your First Program

1. **Open the Assembler**
   ```bash
   open index.html
   ```

2. **Write Your Code**
   ```javascript
   const program = [
       PongoAsm.atOrigin(0x8000),
       ...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0xEA),
       ...PongoAsm.waitForFrame(),
       ...PongoAsm.halt()
   ];

   assemble(program);
   ```

3. **Assemble It**
   - Click "Assemble" button
   - View hex output
   - Check for errors

4. **Run It**
   - Click "Load in Emulator"
   - Watch it execute!

### Loading Existing Programs

1. **Open the Emulator**
   ```bash
   open emulator.html
   ```

2. **Load a ROM**
   - Click "Load ROM"
   - Select your `.bin` file
   - Click "Start"

### Debugging

1. **Step Through Code**
   - Load program in emulator
   - Click "Step" to execute one instruction
   - Watch registers and flags change

2. **Adjust Speed**
   - Use speed slider for different execution rates
   - Low speed: Good for debugging
   - High speed: Full-speed execution

## 🎮 Quick Examples

All examples are built-in to both pages. Try them!

### Fill Screen (Assembler)
```javascript
const program = [
    PongoAsm.atOrigin(0x8000),
    ...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0xEA),
    ...PongoAsm.halt()
];
```

### Pattern Generator (Emulator)
Click "Pattern" quick example to see address-based gradient.

### Interactive Counter (Emulator)
Click "Counter" to see animated incrementing display.

## 💡 Pro Tips

### For Assembly
- Use spread operator `...` to flatten instruction arrays
- Check the hex output to verify your code
- Download binaries to save your work
- Use labels for jumps and branches

### For Emulation
- Mouse X/Y controls paddle A/B
- Left click = Button A
- Right click = Button B
- Watch the flags to understand control flow
- Use "Step" mode for learning/debugging

## 🏗️ Architecture Overview

### Memory Map
```
$0000-$3FFF : RAM (16 KB)
$4000-$7FFF : I/O (16 KB)
  $4000-$43FF : VRAM (1 KB = 32x32 display)
  $4400      : Paddle A
  $4401      : Button A
  $4402      : Paddle B
  $4403      : Button B
  $4404      : Random
  $4407      : Emulator flow
$8000-$FFFF : ROM (32 KB)
```

### Registers
- **IP**: Instruction pointer (16-bit)
- **A**: Accumulator (16-bit)
- **D**: Data register (16-bit)
- **Loop**: Loop counter (16-bit)
- **Indi**: Indirect pointer (16-bit)
- **Tmp A-E**: Temporary storage (8-bit each)

### Instruction Set
```
A*>D : Load from address
A>D  : Load immediate
D>A* : Store to address
PUSH : Multi-byte push
```

## 📊 Feature Comparison

| Feature | Lisp/Python | JavaScript |
|---------|-------------|------------|
| Assembler | ✅ SBCL | ✅ Browser |
| Emulator | ✅ Pygame | ✅ Canvas |
| File I/O | ✅ Disk | ✅ File API |
| Display | ✅ SDL | ✅ Canvas |
| Input | ✅ Keyboard | ✅ Mouse |
| Debugging | ✅ Print | ✅ UI |
| Speed | ⚡ Native | ⚡ JIT |

## 🎨 Color Palette

The display uses XTerm 256-color palette:
- **0-15**: Standard colors
- **16-231**: 6×6×6 RGB cube
- **232-255**: Grayscale ramp

Common colors:
- `0xEA (234)`: Cyan/bright cyan
- `0xEC (236)`: Light gray
- `0x00`: Black
- `0xFF`: White

## 🔧 Advanced Usage

### Custom I/O Handlers

You can extend the emulator with custom I/O:

```javascript
function customIO(addr, data) {
    if (data === undefined) {
        // Read operation
        if (addr === 1029) return myCustomValue;
    } else {
        // Write operation
        if (addr === 1029) handleCustomWrite(data);
    }
}

const core = new PongoEmu.PongoCore(rom, customIO);
```

### Macro Programming

Create reusable assembly patterns:

```javascript
function drawPixel(x, y, color) {
    const addr = PongoAsm.EMUREG_VRAM + (y * 32 + x);
    return [
        ...PongoAsm.move(color, PongoAsm.asType(':ptr', addr))
    ];
}

const program = [
    PongoAsm.atOrigin(0x8000),
    ...drawPixel(10, 10, 0xFF),
    ...drawPixel(10, 11, 0xFF),
    ...PongoAsm.halt()
];
```

## 🐛 Troubleshooting

### Program Won't Assemble
- Check for syntax errors in JavaScript
- Ensure all labels are defined
- Verify register constants are correct

### Emulator Won't Run
- Make sure ROM is loaded
- Check browser console for errors
- Verify program starts at $8000

### Display Issues
- Check VRAM writes are in range $4000-$43FF
- Verify color values are 0-255
- Make sure waitForFrame() is called for animation

### Performance Issues
- Lower instructions per frame
- Check for infinite loops without waitForFrame()
- Use browser dev tools to profile

## 📚 Learning Path

1. **Start with Examples** - Run the built-in quick examples
2. **Read the Docs** - Check README.md and EMULATOR.md
3. **Modify Examples** - Change colors, patterns, timing
4. **Write Simple Programs** - Fill screen, draw shapes
5. **Add Input** - Read paddles and buttons
6. **Create Animations** - Use waitForFrame() for motion
7. **Build Games** - Combine everything!

## 🎓 Example Programs

### Hello World (Fill Screen)
```javascript
...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0xEA)
```

### Blinking Pixel
```javascript
PongoAsm.atLabel('loop'),
...PongoAsm.move(0xFF, PongoAsm.asType(':ptr', PongoAsm.EMUREG_VRAM)),
...PongoAsm.waitForFrame(),
...PongoAsm.move(0x00, PongoAsm.asType(':ptr', PongoAsm.EMUREG_VRAM)),
...PongoAsm.waitForFrame(),
...PongoAsm.jumpTo(PongoAsm.label('loop'))
```

### Mouse Tracker
```javascript
PongoAsm.atLabel('loop'),
...PongoAsm.memset(PongoAsm.EMUREG_VRAM, 1024, 0x00), // Clear
...PongoAsm.move(PongoAsm.EMUREG_PADDLE_A, PongoAsm.REG_TMPA), // X
...PongoAsm.move(PongoAsm.EMUREG_PADDLE_B, PongoAsm.REG_TMPB), // Y
// Calculate address and draw pixel...
...PongoAsm.waitForFrame(),
...PongoAsm.jumpTo(PongoAsm.label('loop'))
```

## 🌟 What's Next?

Now that you have the complete browser suite:

1. **Experiment** - Try the examples and modify them
2. **Create** - Write your own programs
3. **Share** - Show off your creations
4. **Learn** - Explore the architecture
5. **Extend** - Add new features to the tools

## 🙏 Credits

- **Original Lisp Assembler**: environment.lisp
- **Original Python Emulator**: pongofour.py
- **JavaScript Port**: Converted by Claude Code

---

**Ready to start?** Open `index.html` and begin coding! 🚀
