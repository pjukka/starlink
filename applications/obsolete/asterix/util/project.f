*+  PROJECT - collapse one or more axes of nD dataset
      SUBROUTINE PROJECT(STATUS)
*    Description :
*    Parameters :
*    Method :
*    Deficiencies :
*    Authors :
*     Bob Vallance (BHVAD::RJV)
*    History :
*      3 May 90 : Original (RJV)
*     24 Nov 94 : V1.8-0 Now use USI for user interface (DJA)
*     27 Mar 95 : V1.8-1 Uses BIT_ (RJV)
*     24 Apr 95 : V1.8-2 Updated data interfaces (DJA)
*
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'ADI_PAR'
*    Status :
      INTEGER STATUS
*    Local Constants :

      CHARACTER*(30) VERSION		! version ID
         PARAMETER (VERSION='PROJECT Version 1.8-2')

*    Local variables :
      CHARACTER*80           TEXT(8)    ! history text
      CHARACTER*80           ITEXT(4)   ! name of input file
      CHARACTER*80           OTEXT(4)   ! name of output file
      CHARACTER*80           STRING     ! Axis labels/units
      LOGICAL OK			! data valid
      LOGICAL VOK			! Data VARIANCE present
      LOGICAL QOK                       ! data quality present
      INTEGER NDIM			! # dimensions
      INTEGER NVQDIM			! # dimensions
      INTEGER DIMS(ADI__MXDIM)   	! data_array dimensions
      INTEGER VQDIMS(ADI__MXDIM)   	! data_array dimensions
      INTEGER NP			! length of projected axis
      INTEGER EQDIM(ADI__MXDIM)		! equivalent output bins in input
      INTEGER ONDIM			! # dimensions for output
      INTEGER ODIMS(ADI__MXDIM)   	! data_array dimensions
      INTEGER PAX                       ! projection axis
      INTEGER DPTR	              ! data
      INTEGER QPTR	              ! quality
      INTEGER VPTR	              ! data VARIANCE
      INTEGER DPTRO	              ! data
      INTEGER QPTRO	              ! quality
      INTEGER VPTRO	              ! data VARIANCE
      INTEGER I,J

      INTEGER			IFID			! Input dataset id
      INTEGER			OFID			! Output dataset id

      BYTE MASK                      	! QUALITY mask
      INTEGER INLINES                	! # lines input name
      INTEGER ONLINES                	! # line output name
      LOGICAL NORM
*-
      CALL MSG_PRNT (VERSION)

      CALL AST_INIT()

* Associate input dataset
      CALL USI_TASSOC2('INP','OUT','READ',IFID,OFID,STATUS)
      CALL USI_NAMEI(INLINES,ITEXT,STATUS)

* Check input dataset
      CALL BDI_CHKDATA(IFID,OK,NDIM,DIMS,STATUS)

      IF(.NOT.OK) THEN
        CALL MSG_PRNT('AST_ERR: invalid input data')
        STATUS=SAI__ERROR
      ELSEIF (NDIM.EQ.1) THEN
        CALL MSG_PRNT('AST_ERR: cannot project a 1D dataset')
        STATUS=SAI__ERROR
      ENDIF

      IF (STATUS .NE. SAI__OK) GOTO 9000

* find out axes to project
      DO I=1,NDIM
        CALL BDI_GETAXLABEL(IFID,I,STRING,STATUS)
        CALL MSG_SETC('STRING',STRING)
        CALL MSG_SETI('I',I)
        CALL MSG_PRNT( 'Axis ^I is ^STRING' )
      ENDDO

      CALL USI_GET0I('AXIS',PAX,STATUS)

      IF (PAX.LT.1.OR.PAX.GT.NDIM) THEN
        CALL MSG_PRNT('AST_ERR: invalid axis number')
        STATUS=SAI__ERROR
      ENDIF

* check if projected axis normalised
      CALL BDI_GETAXNORM(IFID,PAX,NORM,STATUS)
      NP=DIMS(PAX)

* set up dummy dimensions for coerced data (coerced to 7-D)
      DO I=NDIM+1,7
        DIMS(I)=1
      ENDDO

* map DATA
      CALL BDI_MAPDATA(IFID,'READ',DPTR,STATUS)

* map QUALITY if present
      CALL BDI_CHKQUAL(IFID,QOK,NVQDIM,VQDIMS,STATUS)
      IF (QOK) THEN
        CALL BDI_MAPQUAL(IFID,'READ',QPTR,STATUS)
        CALL BDI_GETMASK(IFID,MASK,STATUS)
      ENDIF

* map VARIANCE if present
      CALL BDI_CHKVAR(IFID,VOK,NVQDIM,VQDIMS,STATUS)
      IF(VOK) THEN
        CALL BDI_MAPVAR(IFID,'READ',VPTR,STATUS)
      ENDIF

* work out output dimensions taking projection into account
      J=1
      DO I=1,7
        IF (I.NE.PAX) THEN
          ODIMS(J)=DIMS(I)
          EQDIM(J)=I
          J=J+1
        ENDIF
      ENDDO
      ONDIM=NDIM-1

* create output data components

* textual lables
      CALL BDI_COPTEXT(IFID,OFID,STATUS)

* DATA
      CALL BDI_CREDATA(OFID,ONDIM,ODIMS,STATUS)
      CALL BDI_MAPDATA(OFID,'WRITE',DPTRO,STATUS)
* QUALITY
      IF (QOK) THEN
        CALL BDI_CREQUAL(OFID,ONDIM,ODIMS,STATUS)
        CALL BDI_MAPQUAL(OFID,'WRITE',QPTRO,STATUS)
        CALL BDI_PUTMASK(OFID,MASK,STATUS)
      ENDIF
* VARIANCE if required
      IF(VOK) THEN
        CALL BDI_CREVAR(OFID,ONDIM,ODIMS,STATUS)
        CALL BDI_MAPVAR(OFID,'WRITE',VPTRO,STATUS)
      ENDIF

      CALL BDI_CREAXES(OFID,ONDIM,STATUS)
      DO I=1,ONDIM
* copy axis values etc from input
        CALL BDI_COPAXIS(IFID,OFID,EQDIM(I),I,STATUS)
      ENDDO


* do projection
      CALL PROJECT_DOIT(
     :       DIMS(1),DIMS(2),DIMS(3),DIMS(4),DIMS(5),DIMS(6),DIMS(7),
     :       PAX,NP,NORM,VOK,QOK,%VAL(DPTR),%VAL(VPTR),%VAL(QPTR),MASK,
     :       ODIMS(1),ODIMS(2),ODIMS(3),ODIMS(4),ODIMS(5),ODIMS(6),
     :       %VAL(DPTRO),%VAL(VPTRO),%VAL(QPTRO),STATUS)

* Copy and update history
      CALL HSI_COPY(IFID,OFID,STATUS)
      CALL HSI_ADD(OFID,VERSION,STATUS)
      CALL HSI_PTXT(OFID,INLINES,ITEXT,STATUS)
      CALL USI_NAMEO(ONLINES,OTEXT,STATUS)
      CALL HSI_PTXT(OFID,ONLINES,OTEXT,STATUS)
      TEXT(1)='Axis   collapsed'
      WRITE(TEXT(1)(6:6),'(I1)') PAX
* Write this into history structure
      CALL HSI_PTXT(OFID,2,TEXT,STATUS)

* Copy over ancillary components
      CALL BDI_COPMORE(IFID,OFID,STATUS)

* Tidy up
9000  CONTINUE

      CALL BDI_RELEASE(OFID,STATUS)
      CALL BDI_RELEASE(IFID,STATUS)
      CALL USI_TANNUL(IFID,STATUS)
      CALL USI_TANNUL(OFID,STATUS)

      CALL AST_CLOSE()
      CALL AST_ERR(STATUS)

      END


      SUBROUTINE PROJECT_DOIT(ID1,ID2,ID3,ID4,ID5,ID6,ID7,PAX,DPAX,NORM,
     :                 VOK,QOK,IN,VIN,QIN,MASK,OD1,OD2,OD3,OD4,OD5,OD6,
     :                                            OUT,VOUT,QOUT,STATUS)
*    Description :
*    Bugs :
*    Authors :
*    History :
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'QUAL_PAR'
*    Import :
      INTEGER ID1,ID2,ID3,ID4,ID5,ID6,ID7
      REAL IN(ID1,ID2,ID3,ID4,ID5,ID6,ID7)
      REAL VIN(ID1,ID2,ID3,ID4,ID5,ID6,ID7)
      BYTE QIN(ID1,ID2,ID3,ID4,ID5,ID6,ID7)
      BYTE MASK
      INTEGER PAX
      INTEGER DPAX
      LOGICAL NORM
      LOGICAL VOK,QOK
      INTEGER OD1,OD2,OD3,OD4,OD5,OD6
*    Import-Export :
*    Export :
      REAL OUT(OD1,OD2,OD3,OD4,OD5,OD6)
      REAL VOUT(OD1,OD2,OD3,OD4,OD5,OD6)
      BYTE QOUT(OD1,OD2,OD3,OD4,OD5,OD6)
*    Status :
      INTEGER STATUS
*    Local Constants :
*    Functions :
      BYTE BIT_ANDUB,BIT_ORUB
*    Local variables :
      INTEGER I(7),I1,I2,I3,I4,I5,I6,I7
      EQUIVALENCE (I(1),I1),(I(2),I2),(I(3),I3),(I(4),I4),(I(5),I5),
     :            (I(6),I6),(I(7),I7)
      INTEGER J(6),J1,J2,J3,J4,J5,J6
      EQUIVALENCE (J(1),J1),(J(2),J2),(J(3),J3),(J(4),J4),(J(5),J5),
     :            (J(6),J6)
      INTEGER II,JJ
      INTEGER IPAX
      INTEGER N
      BYTE QUAL
      LOGICAL GOOD
*-

      IF (STATUS.EQ.SAI__OK) THEN

*  loop through output dataset
        DO J6=1,OD6
          DO J5=1,OD5
            DO J4=1,OD4
              DO J3=1,OD3
                DO J2=1,OD2
                  DO J1=1,OD1

*  set equivalent dimensions for input dataset
                    JJ=1
                    DO II=1,7
                      IF (II.NE.PAX) THEN
                        I(II)=J(JJ)
                        JJ=JJ+1
                      ENDIF
                    ENDDO

*  initialise output bin
                    N=0
                    OUT(J1,J2,J3,J4,J5,J6)=0.0
                    IF (VOK) THEN
                      VOUT(J1,J2,J3,J4,J5,J6)=0.0
                    ENDIF
                    QUAL=QUAL__GOOD

*  sum along projected axis
                    DO IPAX=1,DPAX
                      I(PAX)=IPAX

                      IF (QOK) THEN
                        GOOD=(BIT_ANDUB(QIN(I1,I2,I3,I4,I5,I6,I7),
     :                                         MASK).EQ.QUAL__GOOD)
                        QUAL=BIT_ORUB(QUAL,
     :                         QIN(I1,I2,I3,I4,I5,I6,I7))
                      ELSE
                        GOOD=.TRUE.
                      ENDIF

                      IF (GOOD) THEN
                        N=N+1
                        OUT(J1,J2,J3,J4,J5,J6)=
     :                      OUT(J1,J2,J3,J4,J5,J6) +
     :                         IN(I1,I2,I3,I4,I5,I6,I7)

                        IF (VOK) THEN
                          VOUT(J1,J2,J3,J4,J5,J6)=
     :                       VOUT(J1,J2,J3,J4,J5,J6) +
     :                          VIN(I1,I2,I3,I4,I5,I6,I7)
                        ENDIF

                      ENDIF

                    ENDDO

*  renormalise where necessary and set output quality
                    IF (N.GT.0) THEN
                      IF (QOK) THEN
                        QOUT(J1,J2,J3,J4,J5,J6)=QUAL__GOOD
                      ENDIF
                      IF (NORM) THEN
                        OUT(J1,J2,J3,J4,J5,J6)=
     :                      OUT(J1,J2,J3,J4,J5,J6)/REAL(N)
                        IF (VOK) THEN
                          VOUT(J1,J2,J3,J4,J5,J6)=
     :                      VOUT(J1,J2,J3,J4,J5,J6)/
     :                                                  REAL(N*N)
                        ENDIF
                      ENDIF
                    ELSE
                      IF (QOK) THEN
                        QOUT(J1,J2,J3,J4,J5,J6)=QUAL
                      ENDIF
                    ENDIF


                  ENDDO
                ENDDO
              ENDDO
            ENDDO
          ENDDO
        ENDDO

      ENDIF

      END
