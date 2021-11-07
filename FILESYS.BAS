DEFINT A-Z

TYPE DTAStr
 Reserved AS STRING * 20
 Attribute AS INTEGER
 FileTime AS INTEGER
 FileDate AS INTEGER
 FileSize AS LONG
 FileName AS STRING * 13
END TYPE

TYPE RegTypeX
 AX AS INTEGER
 bx AS INTEGER
 CX AS INTEGER
 DX AS INTEGER
 bp AS INTEGER
 si AS INTEGER
 di AS INTEGER
 Flags AS INTEGER
 DS AS INTEGER
 es AS INTEGER
END TYPE

DECLARE FUNCTION CurDir$ ()
DECLARE FUNCTION CurDrive$ ()
DECLARE FUNCTION DriveCount ()
DECLARE FUNCTION FileExists (FileName$)
DECLARE SUB Dir (Pattern$, Attributes, DTA AS DTAStr)
DECLARE SUB INTERRUPTX (intnum AS INTEGER, inreg AS RegTypeX, outreg AS RegTypeX)
DECLARE SUB ListDirectory (Pattern$, Attributes)
DECLARE SUB SetDrive (Drive$)

CLS
PRINT CurDir$
ListDirectory "*.*", 255

FUNCTION CurDir$
DIM Buffer$
DIM Registers AS RegTypeX

 Buffer$ = STRING$(&H40, " ")
 Registers.AX = &H4700
 Registers.DX = &H0
 Registers.DS = VARSEG(Buffer$)
 Registers.si = SADD(Buffer$)
 INTERRUPTX &H21, Registers, Registers
 CurDir$ = CurDrive$ + ":\" + RTRIM$(Buffer$)
END FUNCTION

FUNCTION CurDrive$
DIM Registers AS RegTypeX

 Registers.AX = &H1900
 INTERRUPTX &H21, Registers, Registers

 CurDrive$ = CHR$((Registers.AX AND &HFF) + &H41)
END FUNCTION

SUB Dir (Pattern$, Attributes, DTA AS DTAStr)
DIM Registers AS RegTypeX

 IF Pattern$ = "" THEN
  Registers.AX = &H4F00
  INTERRUPTX &H21, Registers, Registers
 ELSE
  Registers.AX = &H1A00
  Registers.DX = VARPTR(DTA)
  Registers.DS = VARSEG(DTA)
  INTERRUPTX &H21, Registers, Registers

  Attributes = 0
  Pattern$ = "*.*" + CHR$(0)

  Registers.AX = &H4E00
  Registers.CX = Attributes
  Registers.DX = SADD(Pattern$)
  Registers.DS = VARSEG(Pattern$)
  INTERRUPTX &H21, Registers, Registers
 END IF
END SUB

FUNCTION DriveCount
DIM Registers AS RegTypeX

 Registers.AX = &HE00
 Registers.DX = ASC(CurDrive$) - &H41
 INTERRUPTX &H21, Registers, Registers

 DriveCount = Registers.AX AND &HFF
END FUNCTION

FUNCTION FileExists (FileName$)
DIM DTA AS DTAStr
DIM Registers AS RegTypeX

 Registers.AX = &H1A00
 Registers.DX = VARPTR(DTA)
 Registers.DS = VARSEG(DTA)
 INTERRUPTX &H21, Registers, Registers

 Attributes = 0
 Pattern$ = FileName$ + CHR$(0)

 Registers.AX = &H4E00
 Registers.CX = Attributes
 Registers.DX = SADD(Pattern$)
 Registers.DS = VARSEG(Pattern$)
 INTERRUPTX &H21, Registers, Registers

 FileExists = (INSTR(DTA.FileName, CHR$(0)) > 1)
END FUNCTION

SUB ListDirectory (Pattern$, Attributes)
DIM DTA AS DTAStr

 Dir Pattern$, Attributes, DTA
 DO
  PreviousName$ = FileName$
  PRINT FileName$
  FileName$ = DTA.FileName
  FileName$ = LEFT$(FileName$, INSTR(FileName$, CHR$(&H0)) - 1)
  Dir "", 0, DTA
  IF FileName$ = PreviousName$ THEN EXIT DO
 LOOP
END SUB

SUB SetDrive (Drive$)
DIM Registers AS RegTypeX

 Registers.AX = &HE00
 Registers.DX = ASC(Drive$) - &H41
 INTERRUPTX &H21, Registers, Registers
END SUB

