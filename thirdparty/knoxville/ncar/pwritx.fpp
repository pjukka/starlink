      SUBROUTINE PWRITX(X,Y,IDPC,NCHAR,JSIZE,JOR,JCTR)
      CHARACTER       IDPC*(*)
C
C   IDPC contains the characters to be drawn, and the function codes.
C
C   IDPC must be of type character on input.
C
C
C  SAVE DATA VALUES FOR LATER PASSES
C
      COMMON/PWRSV1/NBWD,NUM15,INDLEN,IDDLEN,NUNIT
C
C
C NOTE THE SIZE OF IDD AND IND MAY BE MODIFED TO CONTAIN THE
C  NUMBER OF ELEMENTS EQUAL TO THE VALUE OF IDDLEN AND INDLEN
C  COMPUTED BELOW.
C
      COMMON/PWRC0/IDD(8625),IND(789)
C
C PWRC0 AND PWRC1 ARE FOR COMMUNICATION WITH SUBROUTINE XTCH.
C PWRC0 IS TO PASS VALUES TO XTCH AND PWRC1 IS TO PASS VALUES BACK.
      COMMON /PWRC1/ LC(150)
C PWRC2 IS FOR COMMUNICATION WITH SUBROUTINE XTCH AND BLOCK DATA PWRXBD.
      COMMON /PWRC2/ INDZER
C VARIABLES WHICH HAVE TO BE SAVED FOR SUBSEQUENT CALLS TO PWRITX AND
C HAVE TO BE INITIALIZED.
C PSAV1 IS ALSO CONTAINED IN PWRXBD.
      COMMON /PSAV1/ FINIT,IFNT,IC,IT,ITO,RLX,RLY,RLOX,RLOY
C VARIABLES WHICH HAVE TO BE SAVED BUT NOT INITIALIZED.
C PSAV2 IS NOT CONTAINED IN ANY OTHER ROUTINE.
      COMMON /PSAV2/ IAPOST, IQU
C
C COMMUNICATION WITH THE USER.
      COMMON /PUSER/ MODE
C
      EXTERNAL PWRXBD
C
      LOGICAL NFLAG
      LOGICAL FINIT
C
C  Character constants
C
      CHARACTER*1 IAPOST,IQU
C
C  Storage for current character of string
C
      CHARACTER*1 NC
C
C  Value of the character in the character-to-hollerith table
C
      INTEGER HOLIND
C
C   C O N S T A N T   D E F I N I T I O N S
C
C INFORMATION ABOUT THE SIZE OF THE FILES OF INTEGERS SUPPLIED BY NCAR
C TOGETHER WITH PWRITX.
C THESE CONSTANTS ARE NEVER USED IN THE CODE BUT REFERRED TO IN COMMENTS
C
C NUMBER OF CARD IMAGES NEEDED TO REPRESENT ARRAY IND.
      DATA ICNUM1 /49/
C NUMBER OF CARD IMAGES NEEDED TO REPRESENT ARRAY IDD.
      DATA ICNUM2 /575/
C
C DEFINE INDICES FOR FONT, SIZE, AND CASE DEFINITIONS.
C
C THESE INDICES ARE USED AS DISPLACEMENTS INTO THE ARRAY IND AND THEY
C DEFINE UNIQUELY FOR EACH CHARACTER TOGETHER WITH ITS REPRESENTATION
C IN DPC AN ENTRY IN THE ARRAY IND. THIS ENTRY CONTAINS A POINTER
C WHICH POINTS TO THE DIGITIZATION OF THE SYMBOL AS DEFINED BY FONT,
C SIZE, CASE, AND CHARACTER.
C
C DEFINE INDEX FOR ROMAN AND GREEK FONT.
      DATA INDROM, INDGRE /0,384/
C DEFINE INDEX FOR PRINCIPAL, INDEXICAL, AND CARTOGRAPHIC SIZE.
      DATA INDPRI, INDIND, INDCAR /0,128,256/
C DEFINE INDEX FOR UPPER AND LOWER CASE.
      DATA INDUPP, INDLOW /0,64/
C
C DEFINE CHARACTER SIZES IN PLOTTER ADDRESS UNITS (FOR RESOLUTION 10)
C
C FOR PRINCIPAL CHARACTER SIZE - HEIGHT,WIDTH
      DATA SPRIH, SPRIW /32.,16./
C FOR INDEXICAL SIZE - HEIGTH,WIDTH
      DATA SINDH,SINDW /20.,12./
C FOR CARTOGRAPHIC SIZE - HEIGTH,WIDTH
      DATA SCARH, SCARW /14.,8./
C
C SHIFTING FOR SUPER OR SUBSCRIPTING.
C
C NUMBER OF PLOTTER ADDRESS UNITS SHIFTED FOR PRINCIPAL CHARACTERS.
      DATA SSPR /10./
C NUMBER OF PLOTTER ADDRESS UNITS SHIFTED FOR INDEXICAL OR CARTOGRAPHIC
C CHARACTERS.
      DATA SSIC /7./
C
C CONSTANT USED TO CHANGE DEGREES INTO RADIANS.
C DEGRAD = 2*3.14/360
      DATA DEGRAD /0.01745329/
C T2 = PI/2
      DATA  T2 /1.5707963/
C
C
C **********************************************************************
C
C IMPLEMENTATION-DEPENDENT CONSTANTS
C
C
C THE UNIT NUMBER WHERE THE BINARY FILE SUPPLIED TO PWRITX CAN BE READ.
C
C     DATA INBIN /0/
      DATA INBIN /3/
C
C
C END OF IMPLEMENTATION-DEPENDENT CONSTANTS
C
C
C **********************************************************************
C
C **********************************************************************
C
C IMPLEMENTATION-DEPENDENT VARIABLES
C
C
C VARIABLES USED IN LOCATING SYSTEM DEPENDENT DATA FILE
C
      CHARACTER*1024 TRANS, FNAME  
      INTEGER IOS,I1,I2
C
C
C END OF IMPLEMENTATION-DEPENDENT VARIABLES
C
C
C **********************************************************************
C
C
C
C VARIABLES AND CONSTANTS USED IN PWRX:
C
C IND - POINTERS INTO ARRAY IDD
C IDD - DIGITIZED CHARACTERS
C LC - CONTAINS DIGITIZATION OF 1 CHARACTER, 1 DIGITIZATION UNIT PER
C      WORD.
C DISPLACEMENTS INTO THE ARRAY IND
C   INDROM - FOR ROMAN FONT
C   INDGRE - FOR GREEK FONT
C   INDPRI - FOR PRINCIPAL CHARACTER SIZE
C   INDIND - FOR INDEXICAL CHARACTER SIZE
C   INDCAR - FOR CARTOGRAPHIC CHARACTER SIZE
C   INDUPP - FOR UPPER CASE
C   INDLOW - FOR LOWER CASE
C CHARACTER SIZE AS DEFINED BY FUNCTION CODE (PLOTTER ADDRESS UNITS)
C   SPRIH - HEIGHT OF PRINCIPAL CHARACTERS
C   SPRIW - WIDTH OF PRINCIPAL CHARACTERS
C   SINDH - HEIGHT OF INDEXICAL CHARACTERS
C   SINDW - WIDTH OF INDEXICAL CHARACTERS
C   SCARH - HEIGHT OF CARTOGRAPHIC CHARACTERS
C   SCARW - WIDTH OF CARTOGRAPHIC CHARACTERS
C SHIFTING FOR SUPER OR SUBSCRIPTING (PLOTTER ADDRESS UNITS)
C   SSPR - SHIFT FOR PRINCIPAL CHARACTERS
C   SSIC - SHIFT FOR INDEXICAL OR CARTOGRAPHIC CHARACTERS
C II  - THE POSITION OF THE CHARACTER CURRENTLY BEING PROCESSED
C NC  - THE CHARACTER CURRENTLY BEING PROCESSED, RIGHT JUSTIFIED,
C       ZERO FILLED, ASCII REPRESENTATION.
C NCHOL - CHARACTER NC IN HOLLERITH REPRESENTATION.
C INDPOI - THE POSITION OF THE POINTER IN IND WHICH POINTS TO THE
C          DIGITIZATION OF CHARACTER NC IN THE ARRAY IDD.
C NUM - SIGNED INTEGER AS EXTRACTED FROM CHARACTER STRING IDPC
C IPASS = 1 : PASS TO CENTER THE STRING
C       = 2 : PASS TO DRAW OUT THE CHARACTERS
C L1  - DISTANCE FROM THE CENTER OF A CHARACTER TO ITS LEFT END
C       (AS A NEGATIVE NUMBER)
C L2  - DISTANCE FROM THE CENTER OF A CHARACTER TO ITS RIGHT END
C       (AS A POSITIVE NUMBER)
C IERR- ERROR COUNT
C NFLAG = .FALSE.  NORMAL
C       = .TRUE.  DIRECT CHARACTER ACCESS
C IT  - REPRESENTS CHARACTER SIZE
C       0   = PRICIPAL  128 = INDEXICAL   256 = CARTOGRAPHIC
C ITO - REPRESENTS PREVIOUS CHARACTER SIZE
C IC  - REPRESENTS LOWER CASE , UPPER CASE
C       =0 UPPER CASE
C       =64 LOWER CASE
C ICO - REPRESENTS PREVIOUS CASE
C IFNT = 0  ROMAN
C      = 384  GREEK
C IFLG = 0  NORMAL
C      = 1  DISTANCE BETWEEN CHARACTERS IS NOT TAKEN FROM DIGITIZATION
C           POSITION INSTEAD DEFINED BY HIGHER PRIORITY FUNCTION CODE
C           (C,Y,X)
C N   - NUMBER OF CHARACTERS IN INPUT STRING
C IDFLG = 0  WRITE ACROSS THE FRAME
C       = 1  WRITE DOWN THE FRAME
C FINIT = .TRUE. ONE TIME INITIALIZATION HAS BEEN DONE
C       = .FALSE. ONE TIME INITIALIZATION HAS NOT BEEN DONE YET
C RLX - CHARACTER HEIGHT ACCORDING TO FUNCTION CODE AND SIZE PARAMETER
C RLY - CHARACTER WIDTH ACCORDING TO FUNCTION CODE AND SIZE PARAMETER
C RLOX - PREVIOUS CHARACTER HEIGHT
C RLOY - PREVIOUS CHARACTER WIDTH
C N4  = 0  NO CHARACTERS TO BE WRITTEN DOWN
C     OTHERWISE  NUMBER OF CHARACTERS TO BE WRITTEN DOWN
C IN4 - NUMBER OF CHARACTER CURRENTLY BEING WRITTEN DOWN
C N3  - NUMBER AS COMPUTED BY GTNUM FOR COORDINATE DEFINITIONS OR
C       NUMBER AS COMPUTED BY GTNUMB FOR NUMERIC CHARACTER DEFINITIONS.
C N3T1 - TEMPORARY STORAGE FOR VARIABLE N3. ONLY USED IN SECTION FOR
C        FUNCTION CODE H.
C N3T2 - LIKE N3T1, BUT FOR FUNCTION CODE V.
C N2  - NUMBER OF CHARACTERS TO BE WRITTEN AS SUPERSCRIPT OR SUBSCRIPT
C IN2 - NUMBER OF CHARACTER CURRENTLY BEING WRITTEN AS SUPERSCRIPT OR
C       SUBSCRIPT
C N1  - NUMBER OF CHARACTERS TO BE WRITTEN IN LOWER CASE OR UPPER CASE
C IN1 - NUMBER OF CHARACTER CURRENTLY BEING WRITTEN IN LOWER CASE OR
C       UPPER CASE
C NF  =1  NORMAL LEVEL
C     =0  FLAG FOR SUPERSCRIPTING OR SUBSCRIPTING
C NIX,NIY - IN PASS 1 THE PARAMETER COORDINATES X AND Y IN METACODE
C           ADDRESS UNITS. IN PASS 2 THE ACTUAL COORDINATES OF THE FIRST
C           CHARACTER IN THE STRING IN METACODE ADDRESS UNITS.
C IX,IY - SAME AS NIX,NIY AS LONG AS NO CARRIAGE RETURN IS ENCOUNTERED.
C         AFTER EACH CARRIAGE RETURN THEY CONTAIN THE COORDINATES OF
C         THE FIRST CHARACTER IN THE NEW LINE.
C NXX,NYY - THE PARAMETER COORDINATES X AND Y IN METACODE ADDRESS UNITS.
C           NIX AND NIY CAN BE USED INSTEAD.
C XX,YY - THE CENTER OF THE CHARACTER TO BE DRAWN (CONSIDERED) NEXT
C XXO,YYO - THE CENTER OF THE LAST CHARACTER DRAWN (CONSIDERED)
C           BEFORE SUPER OR SUBSCRIPTING STARTED
C MX  - THE DISTANCE BETWEEN THE CHARACTER CURRENTLY BEING PROCESSED AND
C       THE CENTER OF THE NEXT CHARACTER TO BE PROCESSED,
C       IN DIGITIZATION UNITS
C MXO  LAST DISTANCE COMPUTED BEFORE SUPER OR SUBSCRIPTING STARTED
C NN  - INDEX VARIABLE IN THE LOOP FOR STRIKING OUT CHARACTERS
C JX,JY - CONTAIN COORDINATES WHEN CHARACTERS ARE BEING STROKED OUT
C MXEND,MYEND - TEMPORARY STORAGE FOR COORDINATES IN TERMINAL PORTION
C IAPOST - THE CHARACTER APOSTROPHE '
C IQU - THE CHARACTER Q
C NCCG - ONLY USED FOR COMPUTED GO TO IN FUNCTION MODE CONTROL SECTION.
C NUMDUN - THE NUMBER OF DIGITIZATION UNITS CONTAINED IN ARRAY LC
C          =0  NO DIGITIZATION FOUND
C INDZER - AN INDICATION FOR AN ALL-0-BITS DIGITIZATION UNIT. INDICATES
C          THAT NEXT MOVE IS PEN-UP.
C
C
C
C          I N I T I A L I Z A T I O N
C
C
C INITIALIZATION  -  ONCE PER LOADING OF ROUTINE
C
C
C CHECK IF INITIALIZATION IS ALREADY DONE.
      IF (FINIT) GOTO 100
C
C  FIND THE NUMBER OF BITS PER WORD
C
      NBWD = I1MACH(5)
C
C  COMPUTE THE NUMBER OF 15-BIT PARCELS PER WORD
C
      NUM15 = NBWD/15
C
C  CALCULATE THE AMOUNT OF ARRAY IND REQUIRED ON THIS MACHINE
C
      INDLEN = (ICNUM1*16-1)/NUM15+1
C
C  CALCULATE THE AMOUNT OF ARRAY IDD REQUIRED ON THIS MACHINE
C
      IDDLEN = (ICNUM2*16*15-1)/NBWD+1
C
C CHARACTERS USED FOR COMPARISONS.
C
      IAPOST = ''''
      IQU    = 'Q'
C
C Define the error file logical unit number
C
      NUNIT = I1MACH(4)
C
C Initialize the hash table for obtaining the hollerith code of a
C character.
C
      CALL HTABLE
C
C READ IN POINTER ARRAY AND CHARACTER DIGITIZATIONS
C
C LOCATE DATA FILE
C
      OPEN(UNIT=INBIN,FILE='/star/etc/pwritx.dat', IOSTAT=IOS,
     :     FORM='UNFORMATTED',
#if HAVE_FC_OPEN_READONLY          
     :     READONLY,
#endif
     :     STATUS='OLD')
     
      IF (IOS .NE. 0) THEN
           CALL GETENV('PATH', TRANS)
           LPATH = INDEX(TRANS, ' ')
           I1 = 1
95         CONTINUE
           I2 = INDEX(TRANS(I1:),':')
           IF (I2 .EQ. 0) THEN
                FNAME = TRANS(I1:LPATH-1)//'/../etc/'//'pwritx.dat'
           ELSE
                FNAME = TRANS(I1:I1+I2-2)//'/../etc/'//'pwritx.dat'
           ENDIF
           OPEN(UNIT=INBIN,FILE=FNAME, IOSTAT=IOS,
     :          FORM='UNFORMATTED',
#if HAVE_FC_OPEN_READONLY          
     :          READONLY,
#endif     
     :          STATUS='OLD')
           IF (IOS .EQ. 0) GOTO 96
           IF (I2 .EQ. 0) THEN
               CALL SETER
     +         ('PWRX - CANNOT LOCATE DATA FILE', 1, 2) 
               RETURN
           ELSE
               I1 = I1 + I2
               GOTO 95
           ENDIF
      ENDIF

96    CONTINUE

      IF (MODE .EQ. 1) GOTO 98
C
C READ IN COMPLEX SET.
C
      READ(INBIN) (IND(I),I=1,INDLEN)
      READ(INBIN) (IDD(I),I=1,IDDLEN)
      REWIND INBIN
      GOTO 97
C
   98 CONTINUE
C
C READ IN DUPLEX SET.
      READ(INBIN) DUMREA
      READ(INBIN) DUMREA
      READ(INBIN) (IND(I),I=1,INDLEN)
      READ(INBIN) (IDD(I),I=1,IDDLEN)
      REWIND INBIN
   97 CONTINUE
C
C SHORT TEST IF ARRAYS IDD AND IND ARE LOADED CORRECTLY.
      IF (MODE .EQ. 1) CALL DCHECK(LCHERR)
      IF (MODE .NE. 1) CALL CCHECK(LCHERR)
      IF (LCHERR .NE. 0) THEN
           CALL SETER
     +     ('PWRX - ARRAY IND OR IDD NOT LOADED CORRECTLY',LCHERR,2)
      ENDIF
   99 CONTINUE
C
C SET FLAG THAT INITIALIZATION IS DONE.
      FINIT = .TRUE.
C
  100 CONTINUE
C
C
C INITIALIZATION  -  ONCE PER CALL TO ROUTINE
C
C
C RETRIEVE RESOLUTION.
C
      CALL GETUSV('XF',LXSAVE)
      CALL GETUSV('YF',LYSAVE)
C
C DEFINE FACTOR TO CHANGE PLOTTER ADDRESS UNITS INTO METACODE UNITS.
C
      METPLA = ISHIFT(1,15-10)
C
C DEFINE FACTOR TO CHANGE USER PLOTTER ADDRESS UNITS INTO METACODE UNITS
C
      METUPA = ISHIFT(1,15-LXSAVE)
C
C COPY ARGUMENTS INTO LOCAL VARIABLES
C
      ICTR = JCTR
      IOR = JOR
      ISIZE = JSIZE
      N = NCHAR
C INSIDE PWRITX WE WORK ONLY WITH METACODE ADDRESS UNITS
      CALL FL2INT (X,Y,NIX,NIY)
C
C SAVE THE FOLLOWING CONSTANTS FOR PASS 2
C
      ID1 = IFNT
      ID2 = IC
      ID3 = IT
      ID4 = ITO
      R1 = RLX
      R2 = RLY
      R3 = RLOX
      R4 = RLOY
C
      IPASS = 1
C ONLY 1 PASS REQUIRED IF THE CHARACTER STRING IS CENTERED TO THE LEFT
      IF (ICTR .EQ. -1) IPASS = 2
C
C INITIALIZATION  -  ONCE PER PASS THROUGH ROUTINE
C
  102 CONTINUE
C POSITION PEN
      CALL PLOTIT(NIX,NIY,0)
C STORE CURRENT POSITION OF PEN
C IX AND IY ARE USED FOR CARRIAGE RETURNS. THEY DEFINE THE BEGINNING
C OF THE LINE CURRENTLY BEING WRITTEN.
      IX = NIX
      IY = NIY
      RX = NIX
      RY = NIY
      XXO = NIX
      YYO = NIY
      XX = NIX
      YY = NIY
C  Z  MULTIPLICATION OF DIGITIZED SIZE
      Z = 1. + FLOAT(ISIZE)/2.
      IF (ISIZE .EQ. 3) Z = 3.
      IF (ISIZE .GT. 3) Z = FLOAT(ISIZE)/21.
C TRANSLATE SIZE FROM PLOTTER ADDRESS UNITS TO METACODE ADDRESS UNITS.
      Z = Z*FLOAT(METPLA)
C SET INTENSITY
      INT = 0
      IF (Z .GT. 64.) INT = 1
C  T - ORIENTATION IN RADIANS
      T = FLOAT(IOR)*DEGRAD
C COMPUTE VALUES USED TO POSITION THE SUBSEQUENT CHARACTER DEPENDING
C ON ANGLE AND FUNCTION CODE.
C NORMAL CASE.
      SIT = SIN(T)
      COT = COS(T)
C USED FOR SUBSCRIPT, CARRIAGE RETURN, Y INCREMENT
      SIM = SIN(T-T2)
      COM = COS(T-T2)
C USED FOR SUPERSCRIPT AND Y INCREMENT
      SIP = SIN(T+T2)
      COP = COS(T+T2)
C MAKE POSITIONING ALSO DEPENDENT ON SIZE PARAMETER
      CT = Z*COT
      ST = Z*SIT
C ADJUST CHARACTER HEIGHT AND WIDTH ACCORDING TO SIZE PARAMETER
      RLX = RLX*Z
      RLY = RLY*Z
C
      MX = 0
C START PROCESSING FROM BEGINNING OF STRING
      II = 0
C FUNCTION CODES DEFINED ONLY FOR A SPECIFIED NUMBER OF CHARACTERS ARE
C NOT VALID ANY MORE. UNRESTRICTED FUNCTION CODES SET IN PREVIOUS CALLS
C TO PWRX ARE STILL VALID.
C CASE.
      N1 = 0
      IN1 = 0
C LEVEL.
      N2 = 0
      IN2 = 0
C DIRECTION.
      N4 = 0
      IN4 = 0
C THE FOLLOWING FUNCTIONS ARE RESET FOR EACH CALL TO PWRX.
C RESET PREVIOUS CASE TO UPPER.
      ICO = 0
C WRITE ACROSS FRAME.
      IDFLG = 0
C THE FOLLOWING INTERNAL FLAGS ARE RESET FOR EACH CALL TO PWRX.
C PROCEED NORMALLY IN X-DIRECTION
      IFLG = 0
C NO DIRECT CHARACTER ACCESS
      NFLAG = .FALSE.
      NF = 0
C
C
C  END INITIALIZATION
C
C-----------------------------------------------------------------------
C
C
C  S T A R T   T O   P R O C E S S   D A T A   S T R I N G
C
C IF IN DIRECT CHARACTER ACCESS MODE, GO TO FUNCTION PROCESSOR SECTION
  104 IF (NFLAG) GO TO 125
C LET II POINT TO THE NEXT CHARACTER IN IDPC
      II = II + 1
C CHECK IF NO CHARACTER LEFT IN STRING.
      IF (II .GT. N) GOTO 120
C RETRIEVE CHARACTER IN NC
      NC = IDPC(II:II)
C IF CHARACTER INDICATES BEGINNING OF FUNCTION CODE, GO TO FUNCTION
C PROCESSOR SECTION.
      IF (NC .EQ. IAPOST) GO TO 125
C FIND ENTRY IN POINTER TABLE POINTING TO DIGITIZATION OF CHARACTER NC
      CALL GETHOL (NC,NCHOL,IER2)
C ERROR IF NC IS NOT A FORTRAN CHARACTER OR AN APOSTROPHE
      IF (IER2 .NE. 0) GOTO 153
      INDPOI = NCHOL + IFNT + IC + IT
C CHECK IF THIS CASE IS ONLY FOR SPECIFIED NUMBER OF CHARACTERS
      IF (N1 .EQ. 0) GO TO 106
C INCREMENT COUNTER FOR CHARACTERS WRITTEN IN THIS CASE
      IN1 = IN1+1
C CHECK IF THIS CHARACTER IS TO BE WRITTEN DOWN
  106 IF (N4 .EQ. 0) GO TO 109
C        ***** PROCESS WRITING DOWN *****
C INCREMENT COUNTER FOR CHARACTERS WRITTEN DOWN
      IN4 = IN4+1
C CHECK IF ALL CHARACTERS SPECIFIED HAVE BEEN WRITTEN DOWN
      IF (IN4 .GT. N4) GO TO 108
C
      RX = XX+RAD*COM
      RY = YY+RAD*SIM
C SET FLAG TO NOT PROCEED IN X DIRECTION
  107 IFLG = 1
C
      MX = 0
      GO TO 109
C SET FLAG THAT ALL CHARACTERS SPECIFIED HAVE BEEN WRITTEN DOWN
  108 N4 = 0
C        ***** END OF WRITING DOWN PROCESSING *****
C
C  PROCESS ONE CHARACTER
C  ---------------------
C
C RETURN DIGITIZATION OF CHARACTER IN ARRAY LC
  109 CONTINUE
      CALL XTCH (INDPOI,IPASS,NUMDUN)
C IF NO DIGITIZATION WAS FOUND, JUST GET NEXT CHARACTER.
      IF (NUMDUN .EQ. 0) GOTO 104
C DEFINE DISTANCE FROM CENTER TO LEFT END OF CHARACTER.
      L1 = LC(1)
C DEFINE DISTANCE FROM CENTER TO RIGHT END OF CHARACTER.
      L2 = LC(2)
C IN THE NORMAL CASE, JUMP
      IF (IFLG .EQ. 0) GO TO 111
C FOR FUNCTION CODES C, Y, AND X NO BLANK SPACE IS LEFT
      L1 = 0
C RESET FLAG TO NORMAL
      IFLG = 0
  111 CONTINUE
C FIND THE CENTER OF THE NEXT CHARACTER TO BE DRAWN.
      MX = MX - L1
      XX = RX+FLOAT(MX)*CT
      YY = RY+FLOAT(MX)*ST
C DO NOT STROKE OUT CHARACTERS IN PASS 1.
      IF (IPASS .EQ. 1) GO TO 117
C
C STROKE OUT CHARACTER
C
      NN = 1
      LC(1) = INDZER
      DO 113 NN = 3,NUMDUN,2
C CHECK FOR INDICATION OF PEN-UP MOVE
      IF (LC(NN) .EQ. INDZER) GOTO 113
C FIND COORDINATES FOR NEXT PEN MOVE
      JX = XX + (FLOAT(LC(NN))*CT - FLOAT(LC(NN+1))*ST + .5)
      JY = YY + (FLOAT(LC(NN))*ST + FLOAT(LC(NN+1))*CT + .5)
C CHECK FOR PEN-UP OR PEN-DOWN
      IF (LC(NN-2) .NE. INDZER) GOTO 116
C PEN-UP MOVE.
      CALL PLOTIT (JX,JY,0)
      GOTO 113
C PEN-DOWN MOVE.
  116 CALL PLOTIT (JX,JY,1)
C
  113 CONTINUE
C
C RESET VARIABLES AFTER ONE CHARACTER HAS BEEN PROCESSED
C
C
  117 CONTINUE
C FIND THE RIGHT END OF THE LAST CHARACTER DRAWN.
      MX = MX + L2
C      ***** FIND CASE DEFINTION OF NEXT CHARACTER *****
C CHECK IF THE CURRENT CASE IS ONLY FOR A SPECIFIED NUMBER.
      IF (N1 .EQ. 0) GO TO 118
C CHECK IF SPECIFIED NUMBER OF CHARACTERS HAS ALREADY BEEN DRAWN.
      IF (IN1 .LT. N1) GO TO 118
C RESET INDICATORS FOR CASE SPECIFICATION.
      N1 = 0
      IN1 = 0
C SET CASE TO PREVIOUS CASE.
      IC = ICO
C CHECK IF THE CURRENT LEVEL IS ONLY FOR SPECIFIED NUMBER OF CHARACTERS.
  118 IF (N2 .EQ. 0) GO TO 104
C CHECK IF SPECIFIED NUMBER OF CHARACTERS HAS ALREADY BEEN DRAWN.
      IN2 = IN2+1
      IF (IN2 .LT. N2) GO TO 104
C SET LEVEL TO PREVIOUS LEVEL.
      IT = ITO
C
      RX = RNX
      RY = RNY
C SET CHARACTER HEIGHT AND WIDTH TO PREVIOUS VALUES
      RLX = RLOX
      RLY = RLOY
C STOP SUPER OR SUBSCRIPTING.
      N2 = 0
C CHECK IF WE WERE IN SUPER OR SUBSCRIPTING MODE BEFORE.
      IF (NF .EQ. 1) GO TO 119
C YES WE WERE. RETURN TO PREVIOUS CASE.
      IC = ICO
C
      XX = XXO
      YY = YYO
C
  119 MX = MXO
C RESET FLAG FOR SUPER OR SUBSCRIPTING TO NORMAL.
      NF = 0
C
      L2 = L2O
C
      GO TO 104
C
C TERMINAL PORTION AFTER WHOLE STRING HAS BEEN PROCESSED
C ------------------------------------------------------
C
  120 CONTINUE
C RESET CHARACTER HEIGHT AND WIDTH
      RLX = RLX/Z
      RLY = RLY/Z
      IF (IPASS .EQ. 2) THEN
          CALL PLOTIT(0,0,0)
          RETURN
      ENDIF
C
C GET READY FOR PASS 2
C
      IPASS = 2
C GET COORDINATES PASSED TO PWRX IN METACODE ADDRESS UNITS
      CALL FL2INT (X,Y,NXX,NYY)
C THE COORDINATES FOR THE END OF THE CHARACTER STRING IF THE FIRST
C CHARACTER HAD BEEN POSITIONED AT THE COORDINATES PASSED TO PWRX.
      MXEND = XX + FLOAT(L2)*CT
      MYEND = YY + FLOAT(L2)*ST
C COMPUTE LENGTH OF CHARACTER STRING TO BE DRAWN
      R     = SQRT(FLOAT(MXEND-NXX)**2 + FLOAT(MYEND-NYY)**2)
C CONSIDER CENTERING OPTION
      WFAC = -1.
      IF (ICTR .EQ. 0) WFAC = -0.5
C COMPUTE DISPLACEMENT FROM COORDINATES PASSED TO PWRX
      RCT = WFAC*R*COT
      RST = WFAC*R*SIT
C CHECK FOR WRITING DOWN OR ACROSS FRAME
      IF (IDFLG .EQ. 1) GO TO 122
C GET COORDINATES WHERE FIRST CHARACTER IN STRING HAS TO BE CENTERED
      XDIF = MXEND - NXX
      NIX = FLOAT(NXX) + XDIF*WFAC
      YDIF = MYEND - NYY
      NIY = FLOAT(NYY) + YDIF*WFAC
      GO TO 123
C GET COORDINATES WHERE FIRST CHARACTER IN STRING HAS TO BE CENTERED
  122 NIX = FLOAT(NXX) + RST
      NIY = FLOAT(NYY) - RCT
C
C REINITIALIZE VARIABLES FOR PASS 2
C SET ROMAN,UPPER CASE, PRINCIPAL
C SET PREVIOUS CHARACTER SIZE ALSO TO PRINCIPAL
  123 IFNT = ID1
      IC = ID2
      IT = ID3
      ITO = ID4
      RLX = R1
      RLY = R2
      RLOX = R3
      RLOY = R4
      GO TO 102
C
C-----------------------------------------------------------------------
C
C   F U N C T I O N   P R O C E S S O R   S E C T I O N
C
C
C  ERROR PROCESSOR
C
  124 IERR = IERR+1
      WRITE(NUNIT,1001) II,IERR
      IF (IERR .EQ. 10) GOTO 120
      GOTO 126
C
C
C  FUNCTION MODE CONTROL SECTION
C  -----------------------------
C
  125 IERR = 0
      NFLAG = .FALSE.
  126 CONTINUE
      II = II + 1
      IF (II .GT. N) GOTO 120
      NC = IDPC(II:II)
C                        Check for an invalid function character, and pr
C                        an error message if one is found.
      CALL GETHOL(NC, HOLIND, NERR)
      IF
     +   (( HOLIND .EQ. 0) .OR. (HOLIND .EQ. 47) .OR.
     +   (( HOLIND .GT. 34 ) .AND. ( HOLIND .LT. 46)) .OR.
     +    ( HOLIND .GT. 52) )
     +THEN
           IERR = IERR + 1
           WRITE( NUNIT, 1001) II, IERR
           IF (IERR .GT. 9) GOTO 120
           GOTO 126
      ENDIF
C                        Check to see if the character is an octal digit
      IF (( NC .GE. '0') .AND. (NC .LE. '7')) THEN
C
C NUMERIC CHARACTER DEFINITION
C ----------------------------
C
C SET FLAG FOR NUMERIC CHARACTER DEFINITION
           NFLAG = .TRUE.
C RETRIEVE OCTAL NUMBER IN N3
           CALL GTNUMB (IDPC,N,II,N3)
C IF END OF CHARACTER STRING REACHED GO TO TERMINAL PORTION
           IF (II .GT. N) GO TO 120
C CHECK IF THIS CASE IS ONLY FOR A SPECIFIED NUMBER OF CHARACTERS.
           IF (N1 .NE. 0) THEN
                IN1 = IN1+1
                IF (IN1 .GT. N1) THEN
                     N1 = 0
C RETURN TO PREVIOUS CASE.
                     IC = ICO
                ENDIF
           ENDIF
C
C SEE IF THE TERMINATING CHARACTER WAS AN APOSTROPHE OR NOT.  IF SO,
C SET 'NFLAG' FALSE TO SUSPEND FUNCTION-CODE SCANNING.
C
           NC = IDPC(II:II)
           IF (NC .EQ. IAPOST) NFLAG = .FALSE.
           INDPOI = N3
           GOTO 106
      ENDIF
C
      IF (NC .EQ. IAPOST) GOTO 104
      IF (NC .EQ. ',') GOTO 126
C
C                           Goto the appropriate section to process the
C                           alphabetic function code characters
C
      GOTO
C        A , B,  C,  D,  E,  F,  G,  H,  I,  J,  K,  L,  M,
     + (145,140,146,144,127,127,129,147,131,127,132,134,127,
C        N,  O,  P,  Q,  R,  S,  T,  U,  V,  W,  X,  Y,  Z
     +  141,127,130,126,128,135,127,133,148,127,149,150,127)
     + HOLIND
C
C                           Error handling section for invalid alphabeti
C                           function code.
C
 127  IERR = IERR + 1
      WRITE( NUNIT, 1001) II, IERR
      IF (IERR .GT. 9) GOTO 120
      GOTO 126
C
C FONT DEFINITION
C ---------------
C
C  ROMAN  R  22B
C
  128 CONTINUE
C DEFINE INDEX INTO POINTER TABLE
      IFNT = INDROM
C GO TO GET NEXT FUNCTION CODE
      GO TO 126
C
C  GREEK  G  07B
C
C EQUIVALENT TO ROMAN
  129 CONTINUE
      IFNT = INDGRE
      GO TO 126
C
C SIZE DEFINITION
C ---------------
C
C  PRINCIPAL SIZE  P  20B
C
  130 CONTINUE
C DEFINE INDEX INTO POINTER TABLE
      IT = INDPRI
C SET CHARACTER WIDTH
      RLX = SPRIW*Z
C SET CHARACTER HEIGHT
      RLY = SPRIH*Z
C GO TO GET NEXT FUNCTION CODE
      GO TO 126
C
C  INDEXICAL SIZE  I  11B
C
C EQUIVALENT TO PRINCIPAL SIZE DEFINITION
  131 CONTINUE
      IT = INDIND
      RLX = SINDW*Z
      RLY = SINDH*Z
      GO TO 126
C
C  CARTOGRAPHIC SIZE  K  13B
C
C EQUIVALENT TO PRINCIPAL SIZE DEFINITION
  132 CONTINUE
      IT = INDCAR
      RLX = SCARW*Z
      RLY = SCARH*Z
      GO TO 126
C
C CASE DEFINITION
C ---------------
C
C  UPPER CASE  U  25B
C
  133 CONTINUE
C Set previous case to lower, current case to
C upper, no characters drawn in this case yet.
      ICO = INDLOW
      IC  = INDUPP
      IN1 = 0
C Set the number of characters to be drawn in upper case.
C If no number is found, then all remaining characters
C should be in upper case.
      CALL GTNUM (IDPC,N,II,N1)
      IF (N1 .EQ. 0) N1 = N + 1 - II
      GO TO 126
C
C  LOWER CASE  L  14B
C
  134 CONTINUE
C Set previous case to upper, current case to
C lower, no characters drawn in this case yet.
      ICO = INDUPP
      IC  = INDLOW
      IN1 = 0
C Set the number of characters to be drawn in upper case.
C If no number is found, then all remaining characters
C should be in lower case.
      CALL GTNUM (IDPC,N,II,N1)
      IF (N1 .EQ. 0) N1 = N + 1 - II
      GO TO 126
C
C LEVEL DEFINITION
C ----------------
C
C  SUPERSCRIPT  S  23B
C
  135 CONTINUE
C DEFINE ANGLE FROM BASE TO FIRST SUPERSCRIPTED CHARACTER.
      TS = SIP
      TC = COP
      GOTO 136
C
C SUBSCRIPT  B  02B
C
  140 CONTINUE
C DEFINE ANGLE FROM BASE TO FIRST SUBSCRIPTED CHARACTER.
      TS = SIM
      TC = COM
C
C FOR SUPERSCRIPT AND SUBSCRIPT.
C
  136 CONTINUE
C DEFINE DISTANCE FROM BASE TO FIRST SUPER OR SUBSCRIPTED CHARACTER.
      RAD = SSPR*Z
      IF (IT .NE. INDPRI) RAD = SSIC*Z
C REMEMBER POSITION OF BASE CHARACTER.
      XXO = XX
      YYO = YY
C
C FOR SUPERSCRIPT, SUBSCRIPT, AND NORMAL.
C
  137 CONTINUE
C REMEMBER POSITION OF LAST CHARACTER BEFORE LEVEL CHANGE.
      RNX = RX
      RNY = RY
C FIND THE POSITION OF THE FIRST CHARACTER AFTER LEVEL CHANGE.
      RX = XX+RAD*TC
      RY = YY+RAD*TS
C RETRIEVE FOR HOW MANY CHARACTERS THE LEVEL HAS TO BE CHANGED.
      IN2 = 0
      CALL GTNUM (IDPC,N,II,N2)
      N2 = IABS(N2)
C REMEMBER SIZE OF CHARACTERS IN PREVIOUS LEVEL.
      RLOX = RLX
      RLOY = RLY
C
      IF (TS .EQ. SIT) GO TO 142
      MXO = MX
C
      MX = L2
      L2O = L2
      NF = 0
C REMEMBER CASE DEFINITION OF BASE CHARACTER.
      ICO = IC
C REMEMBER SIZE DEFINITION OF BASE CHARACTER
      ITO = IT
C ***** FIND CHARACTER SIZE AFTER LEVEL CHANGE *****
C CHECK IF BASE CHARACTER HAS PRINCIPAL SIZE DEFINITION.
      IF (IT .NE. INDPRI) GO TO 139
C BASE CHARACTER HAS PRINCIPAL SIZE. THEN SUPER OR SUBSCRIPT HAS
C INDEXICAL SIZE
  138 CONTINUE
      IT = INDIND
      RLX = SINDW*Z
      RLY = SINDH*Z
      GO TO 126
C BASE CHARACTER HAS INDEXICAL OR CARTOGRAPHIC SIZE. THEN SUPER OR
C SUBSCRIPT HAS CARTOGRAPHIC SIZE.
  139 CONTINUE
      IT = INDCAR
      RLX = SCARW*Z
      RLY = SCARH*Z
C CASE IS SET TO UPPER SINCE CARTOGRAPHIC DOES NOT HAVE LOWER CASE
C CHARACTERS.
      IC = INDUPP
      GO TO 126
C ***** CHARACTER SIZE FOR AFTER LEVEL CHANGE DEFINED *****
C
C  NORMAL  N  16B
C
  141 CONTINUE
C ANGLE BETWEEN LAST SUPER OR SUBSCRIPTED CHARACTER AND FIRST NORMAL
C CHARACTER.
      TS = SIT
      TC = COT
C DISTANCE BETWEEN LAST SUPER OR SUBSCRIPTED CHARACTER AND FIRST
C NORMAL CHARACTER.
      RAD = 0
      IF (IT .EQ. INDIND) RAD = SSPR*Z
      IF (IT .EQ. INDCAR) RAD = SSIC*Z
C GET THE CASE OF THE BASE CHARACTER.
      IC = ICO
C GET THE POSITION OF THE BASE CHARACTER.
      XX = XXO
      YY = YYO
      NF = 1
      GO TO 137
C
  142 CONTINUE
C ***** RESET CHARACTER SIZE WHEN RETURNING TO NORMAL LEVEL *****
      IF (IT .EQ. INDPRI) GO TO 126
C
      IF (IT .EQ. INDCAR .AND. ITO .EQ. INDCAR) GO TO 126
C
      IF (IT .EQ. INDIND) GO TO 143
C
      ITO = IT
      GO TO 138
C
  143 CONTINUE
C RESET CHARACTER SIZE TO PRINCIPAL.
      ITO = IT
      IT = INDPRI
      RLX = SPRIW*Z
      RLY = SPRIH*Z
C *****CHARACTER SIZE IS RESET TO NORMAL *****
      GO TO 126
C
C DIRECTION DEFINITION
C --------------------
C
C    WRITE DOWN  D  04B
C
  144 RAD = RLY
C NO CHARACTER IS CURRENTLY BEING WRITTEN DOWN
      IN4 = 0
C SET FLAG FOR WRITING DOWN
      IDFLG = 1
C GET NUMBER OF CHARACTERS TO BE WRITTEN DOWN
      CALL GTNUM (IDPC,N,II,N4)
C IF N APPEARS WITHOUT AN N OR IF N=0 , WRITE ALL CHARACTERS DOWN
C UNTIL AN 'A' IS ENCOUNTERED OR PWRX RETURNS.
      IF (N4 .EQ. 0) N4 = N
C IF N IS NEGATIVE USE ITS ABSOLUTE VALUE INSTEAD.
      N4 = IABS(N4)
C GO TO INTERPRET CHARACTER NC (ALREADY FETCHED)
      GO TO 126
C
C  ESCAPE FROM DOWN  A  01B
C
  145 CONTINUE
C 0 CHARACTERS TO BE WRITTEN DOWN
      N4 = 0
C *****
C RESET FLAG TO WRITING ACROSS.
      IDFLG = 0
C *****
      GO TO 126
C
C COORDINATE DEFINITION
C ---------------------
C
C  CARRIAGE RETURN  C  03B
C
  146 CONTINUE
C DEFINE DISTANCE TO NEXT LINE.
      RAD = RLY
      MX = 0
C DEFINE POSITION OF FIRST CHARACTER IN NEXT LINE.
      RX = FLOAT(IX)+RAD*COM
      RY = FLOAT(IY)+RAD*SIM
      XX = RX
      YY = RY
C DEFINE THE BEGINNING OF THE LINE CURRENTLY BEING WRITTEN.
      IX = RX
      IY = RY
      GO TO 126
C
C  INCREMENT X  H OR H Q  10B
C
  147 CONTINUE
C RETRIEVE NUMBER AFTER H IN N3
      CALL GTNUM (IDPC,N,II,N3)
C IF NO NUMBER IS PROVIDED IT WILL BE TAKEN TO BE 1.
      IF (N3 .EQ. 0) N3 = 1
      N3T1 = N3
C TRANSFORM UPA UNITS INTO METACODE UNITS.
      N3 = N3*METUPA
C IF HN IS FOLLOWED BY A Q THE SHIFT IS N CHARACTER WIDTHS
**************************************
*
*  Fix by PTW, Starlink, of
*  "HnQ doesn't work" bug
*
*  Original NCAR version:
*     NC = IDPC(II:II)
*
*  Modified version:
      NC = IDPC(II+1:II+1)
*
**************************************
      IF (NC .EQ. IQU) N3 = RLX*FLOAT(N3T1)
C
      RX = RX + FLOAT(N3)
C
      XX = RX+FLOAT(MX)*CT
      YY = RY+FLOAT(MX)*ST
      GO TO 126
C
C  INCREMENT Y  V OR V Q  26B
C
  148 CONTINUE
C RETRIEVE NUMBER AFTER V IN N3
      CALL GTNUM (IDPC,N,II,N3)
C IF NO NUMBER IS PROVIDED IT WILL BE TAKEN TO BE 1.
      IF (N3 .EQ. 0) N3 = 1
      N3T2 = N3
C TRANSFORM USER PLOTTER ADDRESS UNITS INTO METACODE ADDRESS UNITS.
      N3 = N3*METUPA
C IF VN IS FOLLOWED BY A Q THE SHIFT IS N CHARACTER HEIGHTS
**************************************
*
*  Fix by PTW, Starlink, of
*  "VnQ doesn't work" bug
*
*  Original NCAR version:
*     NC = IDPC(II:II)
*
*  Modified version:
      NC = IDPC(II+1:II+1)
*
**************************************
      IF (NC .EQ. IQU) N3 = RLY*FLOAT(N3T2)
C
      RY = RY + FLOAT(N3)
      XX = RX + FLOAT(MX)*CT
      YY = RY + FLOAT(MX)*ST
      GO TO 126
C
C  SET X  (SPECIFY CRT UNIT)  X  30B
C
  149 CONTINUE
C RETRIEVE NUMBER AFTER X IN N3
      CALL GTNUM (IDPC,N,II,N3)
C TRANSLATE USER PLOTTER ADDRESS UNITS INTO METACODE ADDRESS UNITS.
      N3 = N3*METUPA
C
      RX = N3
      XX = RX
      YY = RY + FLOAT(MX)*ST
C PREPARE TO NOT PROCEED IN X DIRECTION FOR NEXT CHARACTER DRAWN.
      MX = 0
      IFLG = 1
C
      GO TO 126
C
C  SET Y  (SPECIFY CRT UNIT)  Y  31B
C
  150 CONTINUE
C RETRIEVE NUMBER AFTER Y IN N3
      CALL GTNUM (IDPC,N,II,N3)
C TRANSLATE USER PLOTTER ADDRESS UNITS INTO METACODE ADDRESS UNITS.
      N3 = N3*METUPA
      RY = N3
      XX = RX+FLOAT(MX)*CT
      YY = RY
      GO TO 126
C
C END FUNCTION MODE PROCESSING
C
C-----------------------------------------------------------------------
C
C     ESCAPE CHARACTER ERROR
C
  153 CONTINUE
      WRITE(NUNIT,1002)II
      GO TO 104
C
 1001 FORMAT(' THE ',I5,'TH CHARACTER IN IDPC IS THE ',I3,
     +           'TH ILLEGAL FUNCTION CODE.')
 1002 FORMAT(' THE ',I5,'TH CHARACTER IN IDPC IS ILLEGAL')
C
      END
