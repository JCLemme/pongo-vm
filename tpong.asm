
# Tpong - pongo pong v3 source


# Color table.
@Def White $255
@Def Grey $240
@Def Red $160
@Def Green $34
@Def Black $0 

# Game state, in high memory.
@Def LeftScore      $1024
@Def RightScore     $1025

@Def BallX          $1026
@Def BallY          $1027
@Def BallXDir       $1028
@Def BallYDir       $1029
@Def BallXCount     $1030
@Def BallYCount     $1031

@Def BallSpeed      $10
@Def BallAngle      $5

@Def LeftPos        $1032
@Def RightPos       $1033

# Various constants.
@Def PaddleSize     $5
@Def DividerSize    $30
@Def ScreenLineLen  $32


# --------------------

@Lbl GameEntry

# Set default values for scores and whatnot.

LeftScore > RamAddr
$6 > RamIn
RightScore > RamAddr
$6 > RamIn

LeftPos > RamAddr
$6 > RamIn
RightPos > RamAddr
$40 > RamIn

BallXDir > RamAddr
$1 > RamIn
BallYDir > RamAddr
$1 > RamIn

@Lbl GameSet

# A new set has begun. Reset game state.

BallX > RamAddr
$16 > RamIn

BallXDir > RamAddr
RamOut > OpA
RamOut > OpB
Nand > OpA
$1 > OpB
Add > RamIn

BallXCount > RamAddr
BallSpeed > RamIn

BallY > RamAddr
$16 > RamIn

BallYDir > RamAddr
RamOut > OpA
RamOut > OpB
Nand > OpA
$1 > OpB
Add > RamIn

BallYCount > RamAddr
BallAngle > RamIn

# Draw static elements.

$PostSetClear > TmpC
$SubClearScreen > Ip
@Lbl PostSetClear

$PostDrawField > TmpC
$SubDrawField > Ip
@Lbl PostDrawField

# Let the user panic for a moment.

$20 > Test
$-1 > OpB
@Lbl SetDelayLoop
    Test > OpA
    Add > Test
    $1 > Pulse
    $SetDelayLoop > IpTest

@Lbl SetLoop

# Remove all sprites from the screen.

Black > TmpA

$1 > TmpB
LeftPos > RamAddr
$PostClearLeft > TmpC
$SubDrawPaddle > Ip
@Lbl PostClearLeft

RightPos > RamAddr
$30 > TmpB
$PostClearRight > TmpC
$SubDrawPaddle > Ip
@Lbl PostClearRight

$PostBallClear > TmpC
$SubBallAddress > Ip
@Lbl PostBallClear
Black > RamIn

# Get paddle position and redraw.

LeftPos > RamAddr
PadA > RamIn
RightPos > RamAddr 
PadB > RamIn

White > TmpA

$1 > TmpB
LeftPos > RamAddr
$PostDrawLeft > TmpC
$SubDrawPaddle > Ip
@Lbl PostDrawLeft

RightPos > RamAddr
$30 > TmpB
$PostDrawRight > TmpC
$SubDrawPaddle > Ip
@Lbl PostDrawRight

# Recalculate ball Y position. (This is the easy one.)

BallYCount > RamAddr
RamOut > OpA
$-1 > OpB
Add > Test
Add > RamIn
$BallYTimerOK > IpTest

    # Timer's done - reset.
    BallAngle > RamIn

    # Check for edges.
    BallY > RamAddr
    RamOut > OpA
    $-4 > OpB
    Add > Test
    $BallYNoTopBounce > IpTest
    $BallYDidBounce > Ip

    @Lbl BallYNoTopBounce
    RamOut > OpA
    $-30 > OpB
    Add > Test
    $BallYDidBounce > IpTest
    $BallYNoBounce > Ip

    @Lbl BallYDidBounce
    # We got here - invert direction.
    BallYDir > RamAddr
    RamOut > OpA
    RamOut > OpB
    Nand > OpA 
    $1 > OpB
    Add > RamIn

    # That's all squared - move the ball.
    @Lbl BallYNoBounce
    BallYDir > RamAddr
    RamOut > OpB
    BallY > RamAddr
    RamOut > OpA
    Add > RamIn

@Lbl BallYTimerOK

# Recalculate ball X position and check for misses.

BallXCount > RamAddr
RamOut > OpA
$-1 > OpB
Add > Test
Add > RamIn
$BallXTimerOK > IpTest

    # Timer's done - reset.
    BallSpeed > RamIn

    # Check for edges.
    BallX > RamAddr
    RamOut > Test
    $BallXNoLeftHit > IpTest
        
        # Left loses a point.
        LeftScore > RamAddr
        RamOut > OpA
        $-1 > OpB
        Add > RamIn
        $GameSet > Ip

    @Lbl BallXNoLeftHit
    RamOut > OpA
    $-30 > OpB
    Add > Test
    $BallXRightHit > IpTest
    $BallXNoHit > Ip
    @Lbl BallXRightHit
   
        # Right loses a point.
        RightScore > RamAddr
        RamOut > OpA
        $-1 > OpB
        Add > RamIn
        $GameSet > Ip

    # That's all squared - move the ball.
    @Lbl BallXNoHit
    BallXDir > RamAddr
    RamOut > OpB
    BallX > RamAddr
    RamOut > OpA
    Add > RamIn

@Lbl BallXTimerOK


# Timers are in place. Check for collisions and draw the ball.

$PostBallDraw > TmpC
$SubBallAddress > Ip
@Lbl PostBallDraw

RamOut > Test
$BallSmack > IpTest
$BallNoSmack > Ip
@Lbl BallSmack

    # We hit a paddle - reverse a little.
    BallXDir > RamAddr
    RamOut > OpA
    RamOut > OpB
    Nand > OpA 
    $1 > OpB
    Add > RamIn

    BallXDir > RamAddr
    RamOut > OpB
    BallX > RamAddr
    RamOut > OpA
    Add > RamIn

    $PostBallDrawRedo > TmpC
    $SubBallAddress > Ip
    @Lbl PostBallDrawRedo
    
# ...do that "drawing the ball" thing I was talking about.

@Lbl BallNoSmack
White > RamIn

# Present.

$1 > Pulse
#Ip > Ip
$SetLoop > Ip























# --------------------

@Lbl SubClearScreen
    $1023 > Test
    $-1 > OpB
    @Lbl SCSLoop
        Test > RamAddr
        $0 > RamIn
        Test > OpA
        Add > Test
        $SCSLoop > IpTest
    TmpC > Ip

@Lbl SubDrawField
    # Draw divider.
    $97 > RamAddr # (1, 3)
    DividerSize > Test
    @Lbl SDFDivLoop
        Grey > RamIn
        RamAddr > OpA
        $1 > OpB
        Add > RamAddr
        Test > OpA
        $-1 > OpB
        Add > Test
        $SDFDivLoop > IpTest
    # Draw left's score.
    LeftScore > RamAddr
    RamOut > Test
    $33 > RamAddr # (1, 1)
    @Lbl SDFLeftLoop
        Grey > RamIn
        RamAddr > OpA
        $2 > OpB
        Add > RamAddr
        Test > OpA
        $-1 > OpB
        Add > Test
        $SDFLeftLoop > IpTest
    # Draw right's score.
    RightScore > RamAddr
    RamOut > Test
    $62 > RamAddr # (30, 1)
    @Lbl SDFRightLoop
        Grey > RamIn
        RamAddr > OpA
        $-2 > OpB
        Add > RamAddr
        Test > OpA
        $-1 > OpB
        Add > Test
        $SDFRightLoop > IpTest
    # Return.
    TmpC > Ip

@Lbl SubDrawPaddle
    # Clamp paddle position to be within the field.
    RamOut > OpA
    $4 > OpB
    Add > OpA
    $-27 > OpB # paddle size minus screen bounds
    Add > Test
    $SDPWasBad > IpTest
    OpA > Test
    $SDPWasOkay > Ip
    @Lbl SDPWasBad
        # We overran - push the paddle back in.
        OpA > RamAddr # sneaky temp variable
        Test > OpA
        Test > OpB
        Nand > OpA
        $1 > OpB
        Add > OpB
        RamAddr > OpA # same sneaky
        Add > Test
    @Lbl SDPWasOkay
    # Generate address. (This is a five-bit left shift.)
    Test > OpA
    Test > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    TmpB > OpB
    Add > RamAddr
    # Now loop it.
    PaddleSize > Test
    @Lbl SDPDrawLoop
        TmpA > RamIn
        RamAddr > OpA
        $32 > OpB
        Add > RamAddr
        Test > OpA
        $-1 > OpB
        Add > Test
        $SDPDrawLoop > IpTest
    # Return.
    TmpC > Ip

@Lbl SubBallAddress
    BallX > RamAddr
    RamOut > TmpA
    BallY > RamAddr
    RamOut > TmpB
@Lbl SubCoordToPosition
    # X in TmpA and Y in TmpB.
    TmpB > OpA
    TmpB > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    OpA > OpB
    Add > OpA
    TmpA > OpB
    Add > RamAddr
    # Return.
    TmpC > Ip
