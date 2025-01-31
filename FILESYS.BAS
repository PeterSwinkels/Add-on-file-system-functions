'$DYNAMIC
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
 BX AS INTEGER
 CX AS INTEGER
 DX AS INTEGER
 BP AS INTEGER
 SI AS INTEGER
 DI AS INTEGER
 Flags AS INTEGER
 DS AS INTEGER
 ES AS INTEGER
END TYPE

DECLARE FUNCTION CurDir$ ()
DECLARE FUNCTION CurDrive$ ()
DECLARE FUNCTION DriveCount ()
DECLARE FUNCTION FileExists (FileName AS STRING)
DECLARE SUB Dir (Pattern AS STRING, Attributes AS INTEGER, DTA AS DTAStr)
DECLARE SUB GetDirectory (Pattern AS STRING, Attributes AS INTEGER, FileNames() AS STRING)
DECLARE SUB INTERRUPTX (intnum AS INTEGER, inreg AS RegTypeX, outreg AS RegTypeX)
DECLARE SUB SetDrive (Drive AS STRING)

DIM FileNames(0 TO 0) AS STRING

 CLS
 PRINT CurDir$
 GetDirectory "*.*", 255, FileNames()
 FOR Index = LBOUND(FileNames) TO UBOUND(FileNames)
  PRINT FileNames(Index)
 NEXT Index
END

REM $STATIC
FUNCTION CurDir$
DIM Buffer AS STRING
DIM Registers AS RegTypeX

 Buffer = STRING$(&H40, " ")
 Registers.AX = &H4700
 Registers.DX = &H0
 Registers.DS = VARSEG(Buffer)
 Registers.SI = SADD(Buffer)
 INTERRUPTX &H21, Registers, Registers
 CurDir$ = CurDrive$ + ":\" + RTRIM$(Buffer)
END FUNCTION

FUNCTION CurDrive$
DIM Registers AS RegTypeX

 Registers.AX = &H1900
 INTERRUPTX &H21, Registers, Registers

 CurDrive$ = CHR$((Registers.AX AND &HFF) + &H41)
END FUNCTION

SUB Dir (Pattern AS STRING, Attributes AS INTEGER, DTA AS DTAStr)
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
  Pattern = Pattern + CHR$(0)

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

FUNCTION FileExists (FileName AS STRING)
DIM DTA AS DTAStr
DIM Pattern AS STRING
DIM Registers AS RegTypeX

 Registers.AX = &H1A00
 Registers.DX = VARPTR(DTA)
 Registers.DS = VARSEG(DTA)
 INTERRUPTX &H21, Registers, Registers

 Attributes = 0
 Pattern = FileName + CHR$(0)

 Registers.AX = &H4E00
 Registers.CX = Attributes
 Registers.DX = SADD(Pattern$)
 Registers.DS = VARSEG(Pattern$)
 INTERRUPTX &H21, Registers, Registers

 FileExists = (INSTR(DTA.FileName, CHR$(0)) > 1)
END FUNCTION

SUB GetDirectory (Pattern AS STRING, Attributes AS INTEGER, FileNames() AS STRING)
DIM Count AS INTEGER
DIM DTA AS DTAStr
DIM FileName AS STRING
DIM PreviousName AS STRING

 Count = 0
 Dir Pattern, Attributes, DTA
 DO
  PreviousName = FileName
  Count = Count + 1
  FileName = LEFT$(DTA.FileName, INSTR(DTA.FileName, CHR$(&H0)) - 1)
  Dir "", 0, DTA
 LOOP UNTIL FileName = PreviousName

 REDIM FileNames(0 TO Count - 1) AS STRING
 Index = 0
 Dir Pattern, Attributes, DTA
 DO
  PreviousName = FileName
  FileName = LEFT$(DTA.FileName, INSTR(DTA.FileName, CHR$(&H0)) - 1)
  FileNames(Index) = FileName
  Index = Index + 1
  Dir "", 0, DTA
 LOOP UNTIL FileName = PreviousName
END SUB

SUB SetDrive (Drive AS STRING)
DIM Registers AS RegTypeX

 Registers.AX = &HE00
 Registers.DX = ASC(Drive) - &H41
 INTERRUPTX &H21, Registers, Registers
END SUB

