@Def CurrentColor $1024
@Def CurrentPixel $1025


@Lbl Mainloop

# Load color and save the next one
CurrentColor > RamAddr
RamOut > TmpA

TmpA > OpA
$1 > OpB
Add > RamIn

# Load screen address and write pixel 
CurrentPixel > RamAddr
RamOut > TmpB
TmpB > RamAddr
TmpA > RamIn

# Increment screen address, cap to 1024
TmpB > OpA
Add > TmpC

TmpC > OpA
$-1024 > OpB
Add > Test

$PixelTooBig > IpTest
$PixelOK > Ip

@Lbl PixelTooBig
$0 > TmpC

@Lbl PixelOK 
CurrentPixel > RamAddr
TmpC > RamIn

$1 > Pulse

$Mainloop > Ip
