@Ip 0

$10 > Test
$0 > RamAddr

@Lbl LineDrawingLoop

$BoopReturn > TmpC
$Boop > Ip
@Lbl BoopReturn

Test > OpA
$-1 > OpB
Add > Test

$LineDrawingLoop > IpTest


$1 > Pulse
Ip > Ip

@Lbl Boop
    $240 > RamIn
    RamAddr > OpA
    $34 > OpB
    Add > RamAddr
TmpC > Ip

