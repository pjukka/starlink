      SUBROUTINE RDSTK(CPARAM,STK_NPTS,STK_STOKES_I,STK_STOKES_Q,
     &                STK_STOKES_QV,STK_STOKES_U,
     &                STK_STOKES_UV,STK_LAMBDA,STK_TITLE,TOP_STK,OUT_LU)
C+
C
C Subroutine:
C
C     R D S T K
C
C
C Author: Tim Harries (tjh@st-and.ac.uk)
C
C Parameters:
C
C CPARAM (<), STK_NPTS (>), STK_STOKES_I (>), STK_STOKES_Q (>),
C STK_STOKES_QV (>), STK_STOKES_U (>),
C STK_STOKES_UV (>), STK_LAMBDA (>), STK_TITLE (>), TOP_STK (>),OUT_LU (<)
C
C History:
C
C   May 1994 Created
C
C
C
C
C
C This routine reads in a stack of polarization spectra from disk.
C
C
C
C
C-
      IMPLICIT NONE
      INTEGER OUT_LU
C
C HDS etc includes
C
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
C
      INCLUDE 'ARRAY_SIZE'
      INCLUDE 'CNF_PAR'
C
C The stack arrays
C
      INTEGER STK_NPTS(MAXSPEC)
      REAL STK_STOKES_I(MAXPTS,MAXSPEC)
      REAL STK_STOKES_Q(MAXPTS,MAXSPEC)
      REAL STK_STOKES_QV(MAXPTS,MAXSPEC)
      REAL STK_STOKES_U(MAXPTS,MAXSPEC)
      REAL STK_STOKES_UV(MAXPTS,MAXSPEC)
      REAL STK_LAMBDA(MAXPTS,MAXSPEC)
      CHARACTER*(*) STK_TITLE(MAXSPEC)
      INTEGER TOP_STK
C
C Misc
C
      INTEGER SP
      INTEGER DIMS(10),NDIMS
C
      CHARACTER*(*) CPARAM
      CHARACTER*80 PATH
      CHARACTER*(80) TMP_STK_TITLE(MAXSPEC)
      INTEGER SPEC_SIZE
      INTEGER QPTR,NPTR
      INTEGER APTR,NO_IN_SAVE
      INTEGER UPTR,QVPTR,UVPTR
      INTEGER NELM,NDF1,NDF2,NDF3,NDF4,NDF5,IPTR
      CHARACTER*(DAT__SZLOC) PLOC,LOC
      INTEGER STATUS
C
      STATUS = SAI__OK
C
C Add a .sdf extenstion if required
C
      CALL SSTRIP(CPARAM)
      SP = INDEX(CPARAM,' ')
      SP = SP-1
      PATH = CPARAM(:SP)
      IF ( PATH((SP-3):SP).NE.'.sdf') THEN
       PATH = PATH(1:SP)//'.sdf'
      ENDIF
C
C Start the NDF system
C
      CALL NDF_BEGIN
C
C Import the locator into the NDF system
C
      CALL HDS_START(STATUS)
      CALL HDS_OPEN(PATH,'READ',LOC,STATUS)
      CALL NDF_IMPRT(LOC,NDF1,STATUS)
C
C Map the arrays
C
      CALL NDF_CGET(NDF1,'TITLE',STK_TITLE,STATUS)
      CALL NDF_DIM(NDF1,10,DIMS,NDIMS,STATUS)
      NO_IN_SAVE = DIMS(2)
      SPEC_SIZE = DIMS(1)
      CALL NDF_MAP(NDF1,'DATA','_REAL','READ',IPTR,NELM,STATUS)
      CALL NDF_XLOC(NDF1,'POLARIMETRY','READ',PLOC,STATUS)
      CALL NDF_FIND(PLOC,'STOKES_Q',NDF2,STATUS)
      CALL NDF_MAP(NDF2,'DATA','_REAL','READ',QPTR,NELM,STATUS)
      CALL NDF_MAP(NDF2,'VARIANCE','_REAL','READ',QVPTR,NELM,STATUS)
      CALL NDF_FIND(PLOC,'STOKES_U',NDF3,STATUS)
      CALL NDF_MAP(NDF3,'DATA','_REAL','READ',UPTR,NELM,STATUS)
      CALL NDF_MAP(NDF3,'VARIANCE','_REAL','READ',UVPTR,NELM,STATUS)
      CALL NDF_FIND(PLOC,'NPTS',NDF4,STATUS)
      CALL NDF_MAP(NDF4,'DATA','_INTEGER','READ',NPTR,NELM,STATUS)
      CALL NDF_FIND(PLOC,'LAMBDA',NDF5,STATUS)
      CALL NDF_MAP(NDF5,'DATA','_REAL','READ',APTR,NELM,STATUS)
C
C Read in the titles
C
      CALL CMP_GETVC(PLOC,'TITLES',MAXSPEC,
     &               TMP_STK_TITLE,NO_IN_SAVE,STATUS)
C
C If everything was OK then read in the mapped arrays onto the end
C of the stack
C
      IF (SPEC_SIZE.LE.MAXPTS) THEN
       IF (STATUS.EQ.SAI__OK) THEN
       CALL READ_STK(TOP_STK,STK_NPTS,STK_LAMBDA,
     &              STK_STOKES_I,STK_STOKES_Q,
     &      STK_STOKES_QV,STK_STOKES_U,STK_STOKES_UV,STK_TITLE,
     &      NO_IN_SAVE,SPEC_SIZE,%VAL(CNF_PVAL(NPTR)),
     &      %VAL(CNF_PVAL(APTR)),%VAL(CNF_PVAL(IPTR)),
     &      %VAL(CNF_PVAL(QPTR)),%VAL(CNF_PVAL(QVPTR)),
     &      %VAL(CNF_PVAL(UPTR)),%VAL(CNF_PVAL(UVPTR)),
     &      TMP_STK_TITLE,OUT_LU)
      ENDIF
       ELSE
       CALL WR_ERROR('Stack spectra are too big',OUT_LU)
      ENDIF
C
C Annul the locators and close them down
C
      CALL DAT_ANNUL(PLOC,STATUS)
      CALL NDF_END(STATUS)
      CALL HDS_CLOSE(LOC,STATUS)
      CALL HDS_STOP(STATUS)
      END
