

# These are some macros.
[ Invert value dest
    value > OpA
    value > OpB
    Nand > dest
]

[ DoNothing
    Temp > Temp
]

[ Swap
    OpB > Temp
    OpA > OpB
    DoNothing
    Temp > OpA
]

# And now let's use them.
Invert $2 Temp
DoNothing
Swap
