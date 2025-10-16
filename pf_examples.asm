; Memset

!Ip 0x1000
SetTo: !Dat 0 
Target: !Dat 0 1
Len: !Dat 0 0

!Macro DoAdd(opA, opB, res)
    *opA > IndiHi
    *opB > IndiLo
    Nand > *TmpA
    
!End

!Ip 0x8000

; Set parameters
#0xFFE1 > *Target
#0xEA > *SetTo
#256 > *Len

; Set the mem
Sub_Memset:
    *Target > Indi
    *Len > Loop
    *SetTo > TmpA+
    _CopyLoop:
        *SetTo > **Indi
        #[IndirectUp,LoopDown] > Flow ; this is the kicker
        DoAdd(3, 2, opA)
        _CopyDone ?> Ip
        _CopyLoop > Ip
    _CopyDone:
    
{23 +
    2 +
    5* > D} ;help me
    {D > 8*}

; TODO: not this

!Dat "this is a string bb\n"


