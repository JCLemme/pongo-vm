# Pongo Pong v2
# this time with a tta

# Color table
@Def White $255
@Def Grey $240
@Def Red $160
@Def Green $34

# Locations on screen
@Def DividerY $3
@Def NegDividerY $-4
@Def ScoreRightX $22
@Def PaddleLeftY $21
@Def PaddleRightY $20
@Def RightGutter $30

# Object sizes
@Def DividerSize $29
@Def PaddleSize $5
@Def PaddleDrawSize $4

@Ip 15

# Game variables
@Lbl BallX
@Data 16

@Lbl BallXDir
@Data 1

@Lbl BallXCt
@Data 0


@Lbl BallY
@Data 16

@Lbl BallYDir
@Data 1

@Lbl BallYCt
@Data 0


@Lbl BallSpeed
@Data 10

@Lbl BallAngle
@Data 5


@Lbl LeftScore
@Data 5

@Lbl RightScore 
@Data 5

@Lbl PaddleLeftPos
@Data 0

@Lbl PaddleRightPos
@Data 0


# -- STEP 0: SET UP THE GAME (and also get paddle position) --
@Start
BallSpeed > BallXCt
BallAngle > BallYCt
PaddleLeftY > PaddleLeftPos
PaddleRightY > PaddleRightPos

@Lbl GameLoopStart

PadA > OpA
$4 > OpB 
Add > PaddleLeftPos
PadB > OpA
Add > PaddleRightPos

# -- STEP 1: DRAW THE PLAYFIELD --

# Clear what was there
^ Clear

# Load "grey" color
Grey > Col

# Draw the divider
DividerY > Dy
$1 > Dx
DividerSize > Loop
@Lbl WritingDivider
^ Plot
^ IncDx
$WritingDivider > IpLoop

# Draw the score ticks
$1 > Dx
$1 > Dy
LeftScore > OpA
$-1 > OpB
Add > Loop
@Lbl WritingLeftScore
^ Plot
^ IncDx 
^ IncDx
$WritingLeftScore > IpLoop

ScoreRightX > Dx
RightScore > OpA
Add > Loop
@Lbl WritingRightScore
^ Plot
^ IncDx
^ IncDx
$WritingRightScore > IpLoop


# -- STEP 2: DRAW THE GAME --

# Load "white" color
White > Col

# Draw paddles 
RightGutter > Dx
PaddleRightPos > Dy
PaddleDrawSize > Loop
@Lbl WritingRightPaddle
^ Plot
^ IncDy
$WritingRightPaddle > IpLoop

$1 > Dx
PaddleLeftPos > Dy
PaddleDrawSize > Loop
@Lbl WritingLeftPaddle
^ Plot
^ IncDy
$WritingLeftPaddle > IpLoop

# Draw the ball
BallX > Dx
BallY > Dy
^ Plot


# -- STEP 3: DO GAME LOGIC --


# Handle ball's Y counter - easy, just reflects 
BallYCt > OpA
$-1 > OpB
Add > BallYCt
Add > Loop

$BallYStillCounting > IpLoop

    BallAngle > BallYCt
    BallY > OpA
    BallYDir > OpB
    Add > BallY

    BallY > OpA
    NegDividerY > OpB
    Add > Loop
    $BallYNotZero > IpLoop

        BallYDir > OpA
        Inv > OpA
        $1 > OpB
        Add > BallYDir

    @Lbl BallYNotZero

    BallY > OpA
    $-30 > OpB
    Add > Loop
    $BallYYesEdge > IpLoop
    $BallYNotEdge > Ip

    @Lbl BallYYesEdge
        BallYDir > OpA
        Inv > OpA
        $1 > OpB
        Add > BallYDir

    @Lbl BallYNotEdge

@Lbl BallYStillCounting


# Handle ball's X counter - harder, subs points
BallXCt > OpA
$-1 > OpB
Add > BallXCt
Add > Loop

# --> If we get here, the counter expired
$BallXStillCounting > IpLoop

    # --> Move the ball
    BallSpeed > BallXCt
    BallX > OpA
    BallXDir > OpB
    Add > BallX

    # --> Is the ball on the left edge?
    BallX > OpA
    $-1 > OpB
    Add > Loop
    $BallXNotZero > IpLoop

        # A note on paddle collision: we're treating the paddle as being one pixel longer in either direction.
        # This is to correct for ball movement. We check for collisions at the same time that we update the ball's
        # position, so the player doesn't see the faulting position of the ball. This makes it possible to miss a 
        # return when you hit a heavily englished ball on a paddle edge, even though visually it looks right.
        
        # TODO: unify all these paddle sizes and shit - either they all do math or they're all hardcoded

        # ----> Are we lower than the paddle?
        PaddleLeftPos > OpA
        PaddleSize > OpB
        Add > OpA
        $1 > OpB
        Add > OpA
        Inv > OpA
        $1 > OpB
        Add > OpB
        BallY > OpA
        Add > Loop
        $LeftPaddleNoContact > IpLoop

        # ----> Are we higher than the paddle?
        @Lbl LeftPaddleYesContact
        PaddleLeftPos > OpA
        $-1 > OpB
        Add > OpA
        Inv > OpA
        $1 > OpB
        Add > OpA
        BallY > OpB
        Add > Loop
        $LeftPaddleYesBounce > IpLoop
        $LeftPaddleNoContact > Ip

        # ----> You got lucky this time.
        @Lbl LeftPaddleYesBounce
        BallXDir > OpA
        Inv > OpA
        $1 > OpB
        Add > BallXDir    

        # ----> Jog the ball to make the visuals line up.
        BallX > OpA
        BallXDir > OpB
        Add > BallX
        BallX > OpA
        Add > BallX

        $BallXStillCounting > Ip

        @Lbl LeftPaddleNoContact

        # ----> Paddle didn't save you; lose a point
        LeftScore > OpA
        $-1 > OpB
        Add > LeftScore
        $LostAPoint > Ip

    @Lbl BallXNotZero

    # --> Is the ball on the right edge?
    BallX > OpA
    $-29 > OpB
    Add > Loop
    $BallXYesEdge > IpLoop
    $BallXNotEdge > Ip
    @Lbl BallXYesEdge

        # ----> Are we lower than the paddle?
        PaddleRightPos > OpA
        PaddleSize > OpB
        Add > OpA
        $1 > OpB
        Add > OpA
        Inv > OpA
        $1 > OpB
        Add > OpB
        BallY > OpA
        Add > Loop
        $RightPaddleNoContact > IpLoop

        # ----> Are we higher than the paddle?
        @Lbl RightPaddleYesContact
        PaddleRightPos > OpA
        $-1 > OpB
        Add > OpA
        Inv > OpA
        $1 > OpB
        Add > OpA
        BallY > OpB
        Add > Loop
        $RightPaddleYesBounce > IpLoop
        $RightPaddleNoContact > Ip

        # ----> You got lucky this time.
        @Lbl RightPaddleYesBounce
        BallXDir > OpA
        Inv > OpA
        $1 > OpB
        Add > BallXDir    

        # ----> Jog the ball to make the visuals line up.
        BallX > OpA
        BallXDir > OpB
        Add > BallX
        BallX > OpA
        Add > BallX

        $BallXStillCounting > Ip

        @Lbl RightPaddleNoContact

        # ----> Paddle didn't save you; lose a point
        RightScore > OpA
        $-1 > OpB
        Add > RightScore
        $LostAPoint > Ip

    @Lbl BallXNotEdge

# --> Done handling the X axis
@Lbl BallXStillCounting


# -- STEP n: DO IT ALL AGAIN --
^ WaitEx
$GameLoopStart > Ip



# -- STEP ??: LOSE A POINT --

@Lbl LostAPoint

# Did anyone lose fr?
LeftScore > Loop
$LeftHasPoints > IpLoop
$GameOver > Ip
@Lbl LeftHasPoints

RightScore > Loop
$RightHasPoints > IpLoop
$GameOver > Ip
@Lbl RightHasPoints

# Reverse direction
BallXDir > OpA
Inv > OpA
$1 > OpB
Add > BallXDir

# Move back to center
$16 > BallX
$16 > BallY
$16 > Loop

# Lil time penalty
@Lbl LosePointDelay
^ WaitEx
$LosePointDelay > IpLoop

$GameLoopStart > Ip


# -- STEP 3#8: YOU LOST --
@Lbl GameOver

$GameOver > Ip
