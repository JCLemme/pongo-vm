# Source code for Pongo Pong
# (sorry in advance)


# -- CONSTANTS --
@Pc 0

# Color table
@Lbl White
@Data 255
@Lbl Grey
@Data 240
@Lbl Red
@Data 160
@Lbl Green
@Data 34

# Locations of things
@Lbl ConstantZero
@Data 0

@Lbl ConstantOne
@Data 1

@Lbl DividerY
@Data 3

@Lbl ScoreRightX
@Data 22

@Lbl PaddleLeftY
@Data 15

@Lbl PaddleRightY
@Data 20

@Lbl RightGutter
@Data 30

# Game variables


# -- STEP 1: DRAW THE PLAYFIELD --
@Pc 20

# Load "grey" color
IncAc
LdCo

# Draw the divider
LdDy DividerY
LdDx ConstantZero
IncDx
LdLp 15
@Write
IncDx
Jlp -3
LdLp 13
@Write
IncDx
Jlp -3

# Draw the score ticks
LdDx ConstantOne
LdDy ConstantOne
LdLp 4
@Write
IncDx
IncDx
Jlp -4

LdDx ScoreRightX
LdLp 4
@Write
IncDx
IncDx
Jlp -4


# -- STEP 2: DRAW THE GAME --

# Load "white" color
LdAc ConstantZero
LdCo

# Draw paddles 
LdDx RightGutter
LdDy PaddleRightY
LdLp 4
@Write
IncDy
Jlp -3

LdDx ConstantOne
LdDy PaddleLeftY
LdLp 4
@Write
IncDy
Jlp -3


