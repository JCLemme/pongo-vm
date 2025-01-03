# Makes a diagonal line

# Get outta here
@Pc 0
Jmp 4

# Color to write
@Data 255

# Starting X and Y
@Lbl StartX
@Data 3
@Lbl StartY
@Data 3

# Load colors and position regs
IncAc
LdCo
LdDx StartX
LdDy StartY

# Loop five times
LdLp 5
@Write
IncDx
Jlp -3

# Halt
Jmp 0
