      SUBROUTINE FIT_GETDAT( ID, GENUS, FSTAT, WORKSPACE, WEIGHTS,
     :                       NDS, OBDAT, NGOOD, SSCALE, PREDDAT,
     :                       INSTR, STATUS )
*+
*  Name:
*     FIT_GETDAT

*  Purpose:
*     Get data for fitting

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL FIT_GETDAT( ID, GENUS, FSTAT, WORKSPACE, WEIGHTS, NDS, OBDAT,
*                      NGOOD, SSCALE, PREDDAT, INSTR, STATUS )

*  Description:
*     Gets data arrays, errors etc and response matrices (if available) from
*     multiple datasets. In the case of likelihood fitting, background
*     datasets and effective exposure times (=factor by which data must be
*     multiplied to get back to raw counts) are also acquired.
*     Sets up data weights for use in chi-squared evaluation if WEIGHTS=true.
*     If WORKSPACE is set true then workspace for the chi-squared gradient
*     calculation (performed by FIT_DERIVS) is set up in a temporary object.
*     (Note that this is not required for a simple fitstat evaluation,
*     only where gradients are needed.)
*     NOTE: If an instrument response is found in a dataset then it is assumed
*     that the model data require folding through it. If no INSTR_RESP is
*     present then the model and data spaces are assumed to be identical.

*  Arguments:
*     ID = INTEGER (given)
*        Top level fit dataset, either a FileSet or a fit source file
*     GENUS = CHARACTER*(*) (given)
*        The fit genus
*     FSTAT = INTEGER (given)
*        Fit statistic code, either FIT__CHISQ or FIT__LOGL
*     WORKSPACE = LOGICAL (given)
*        Set up workspace for minimisation?
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     The identifier ID may refer to either a single dataset, or an object
*     containing a collection of references, for input of multiple datasets.
*     Data quality is taken into account if present, so that bad data are
*     given zero weight. Good data take a weight equal to their inverse
*     variance for chisq fitting, whilst for likelihood, the data are
*     scaled up by TEFF (and any b/g subtracted is added back on) to recover
*     the raw counts (so that the errors can be treated as Poissonian).
*     Background data are found via a BGREF reference in each dataset,
*     and are checked to ensure that they have the same dimensions as the
*     main data array. For spectral sets, the background is required to
*     be a parallel set. B/g data may be the RAW b/g counts
*     predicted in the data, or they can be time normalised, in which
*     case they are scaled by TEFF by the software.
*     The response matrix is acquired, if it is present in the
*     dataset, and its channel range is checked against that of the data.
*     In the special case of spectral sets, a 2D array is accessed as a set
*     of 1D spectra, AXIS(1) being the spectral dimension. In this case
*     OBDAT.D_ID points to the same container file for each member of the
*     set, and OBDAT.SETINDEX indicates the position in the set. For normal
*     spectra OBDAT.SETINDEX is set to zero.
*     The quantity SSCALE is used to scale the fit statistic to give a number
*     closer to unity within FIT_MIN. For the likelihood case this is set
*     to the total number of counts in the data, whilst for the chisq case,
*     it need not be set up at this stage, since the number of degrees of
*     freedom will be used.
*     NOTE:
*     Temporary storage is set up by the DYN_ system; this should be
*     initialised in the calling program with an AST_INIT, and cleared up
*     at the end of execution with AST_CLOSE.

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     FIT Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/fit.html

*  Keywords:
*     package:fit, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     TJP: Trevor Ponman (University of Birmingham)
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     17 Mar 1987 (TJP):
*        Original version (FIT_DATGET)
*     11 Jun 1987 (TJP):
*        Data object names found and returned
*     26 Jun 1987 (TJP):
*        Various minor fixes
*     14 Apr 1988 (TJP):
*        Changed structures - renamed to FIT_DATINGET
*     12 Aug 1988 (TJP):
*        DLOC incorporated in OBDAT structure
*     16 Aug 1988 (TJP):
*        WEIGHTS argument allows disabling of weights
*     21 Oct 1988 (TJP):
*        FIT_MSPACE renamed to FIT_PREDSET
*     31 Oct 1988 (TJP):
*        Bug with bad quality (e.g. IGNOREd) data fixed
*     24 May 1989 (TJP):
*        ASTERIX88 conversion, handling of spectral sets
*      7 Jun 1989 (TJP):
*        Selection of detectors from spectral sets
*     19 Jun 1989 (TJP):
*        Spectral number included in OBDAT.DATNAME for sets
*     23 Jun 1989 (TJP):
*        Slice mapping for SPECTRAL_SETs fixed
*      7 Jul 1989 (TJP):
*        DCLOC not annulled
*     18 May 1990 (TJP):
*        Use of SPEC_SETSEARCH to establish SPECTRAL_SET type
*     10 Jun 1992 (TJP):
*        Error handling corrected. Obj.name replaced by filename
*     18 Jun 1992 (TJP):
*        Likelihood fitting catered for
*     19 Jun 1992 (TJP):
*        Handle case of b/g subtracted data for LIK fitting
*     24 Jun 1992 (TJP):
*        Both NGOOD and SSCALE passed back
*      1 Jul 1992 (TJP):
*        Bug fix when handling SPECTRAL_SET directly
*      8 Jul 1992 (DJA):
*        Don't get instrument response when GENUS is 'CLUS'
*     26 Nov 1992 (DJA):
*        Use quality when finding SSCALE
*     15 Nov 1993 (DJA):
*        Use PRO_GET routine to read PROCESSING flags
*     21 Jul 1994 (DJA):
*        Store background locator in dataset structure
*     10 Mar 1995 (DJA):
*        Adapted from old FIT_DATINGET. PRO_ -> PRF_ etc
*      1 Aug 1995 (DJA):
*        Added ability to read vignetting file.
*     29 Nov 1995 (DJA):
*        ADI port. Use new BDI routines, FSI for spectral set access.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'
      INCLUDE 'FIT_PAR'

*  Structure Declarations:
      INCLUDE 'FIT_STRUC'

*  Arguments Given:
      INTEGER			ID			! Input data (or ref)
      CHARACTER*(*)             GENUS           	! Model GENUS
      INTEGER                   FSTAT           	! Fit statistic flag
      LOGICAL                   WORKSPACE               ! Set up workspace?

*  Arguments Given and Returned:
      LOGICAL 			WEIGHTS                 ! Set up data weights?

*  Arguments Returned:
      INTEGER 			NDS                     ! No of datasets
      RECORD /DATASET/ 		OBDAT(NDSMAX)  		! Observed datasets
      INTEGER 			NGOOD                   ! No of good data elements
      INTEGER 			SSCALE                  ! Factor for scaling fitstat
      RECORD /PREDICTION/ 	PREDDAT(NDSMAX) 	! Data predicted by model
      RECORD /INSTR_RESP/ 	INSTR(NDSMAX) 		! Instrument responses

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			CHR_LEN
        INTEGER 		CHR_LEN

*  Local Variables:
	CHARACTER*100 FILE		! File name for HDS_TRACE
	CHARACTER*2 SPECH		! Spectrum number (within set)

	LOGICAL LOG			! General purpose logical
	LOGICAL OK			! Data present and defined?
	LOGICAL QUAL			! Data quality info available?
	LOGICAL BG			! B/g data file found?
	LOGICAL BGSUB			! B/g subtracted flag set in data?

      REAL			RSUM			! Real SSCALE
      REAL 			TEFF			! Effective exposure time

      INTEGER 			BDIMS(ADI__MXDIM)	! B/g array dimensions
      INTEGER			BFID(NDSMAX)		! Bgnd datasets
      INTEGER			DCFID(NDSMAX)		! Source datasets
      INTEGER 			DIMS(ADI__MXDIM)	! Data array dimensions
      INTEGER 			I			! Index
      INTEGER 			NDIM			! I/p dimensionality
      INTEGER 			NDSC			! # dataset files
      INTEGER 			NDSTOP			! NDS at end of current container
      INTEGER			NVDIM			! Vignetting dim'ality
      INTEGER 			PTR			! General pointer
      INTEGER 			SETSIZE			! # spectra in set
      INTEGER			TIMID			! Timing info
      INTEGER			TPTR			! Temp pointer
      INTEGER			VDIMS(ADI__MXDIM)	! Vignetting dims
      INTEGER			VFID(NDSMAX)		! Vignetting datasets

      LOGICAL 			BGCOR			! B/g data been exposure corrected?
      LOGICAL 			CHISTAT			! Chi-squared fitting?
      LOGICAL 			LIKSTAT			! Likelihood fitting?
      LOGICAL 			REF			! Input from ref file?
      LOGICAL 			SPECSET(NDSCMAX)	! I/p is spectral set?
      LOGICAL			VIG			! Vignetting present?

	INTEGER NBDIM			! B/g array dimensionality
	INTEGER N			! Dataset index
	INTEGER INDEX			! Current spectral set selection no
	INTEGER LDIM(2)			! Lower bound for array slice
	INTEGER UDIM(2)			! Upper bound for array slice
	INTEGER NGDAT			! No of good data in dataset
	INTEGER NCH			! No of characters in string
	INTEGER DETNO(NDSCMAX)		! No of detectors selected from set
	INTEGER DETSEL(NDETMAX,NDSCMAX)	! Detectors selected from set
        INTEGER SPECNO			! Current spectrum no (from set)
	INTEGER IERR,NERR		! Error arguments for VEC_* routines
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Is the input a file set?
      CALL ADI_DERVD( ID, 'FileSet', REF, STATUS )

*  Set statistic flags
      IF ( FSTAT .EQ. FIT__LOGL ) THEN
	LIKSTAT = .TRUE.
        CHISTAT = .FALSE.
        WEIGHTS = .FALSE.
      ELSE
	LIKSTAT = .FALSE.
	CHISTAT = .TRUE.
      END IF

* Find datasets - get locators
      IF ( .NOT. REF ) THEN

*    Single input dataset container (directly referenced)
	NDSC = 1
        CALL ADI_CLONE( ID, DCFID(1), STATUS )

*    Spectral set?
        CALL SPEC_SETSRCH( DCFID(NDSC), SPECSET(NDSC), STATUS )
	IF (SPECSET(1)) DETNO(1)=0		! Flag to use all spectra

      ELSE

*    User has supplied a file set
        CALL ADI_CGET0I( ID, 'NFILE', NDSC, STATUS )

*    Loop over each referenced file in the file set
        DO I = 1, NDSC

*      Open the referenced file
          CALL FSI_FOPEN( ID, I, 'BinDS', DCFID(I), STATUS )

*      Is it a spectral set?
	  CALL SPEC_SETSRCH( DCFID(I), SPECSET(I), STATUS )

*      Find which spectra to use in a spectral set
          IF ( SPECSET(I) ) THEN

*        Get selection
            CALL FSI_GETSEL( DCFID(I), I, NDETMAX, DETSEL(1,I),
     :                       DETNO(I), STATUS )

*        Trap selection absent
            IF ( STATUS .NE. SAI__OK ) THEN
              DETNO(I) = 0
              CALL ERR_ANNUL( STATUS )
            END IF

          END IF

        END DO

      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Abort if maximum permitted number of datasets is exceeded
      IF ( NDSC .GT. NDSMAX ) THEN
	STATUS=SAI__ERROR
        CALL ERR_REP(' ','Maximum number of input datasets exceeded',
     :    STATUS)
	GOTO 99
      END IF

*  Loop through dataset containers
      NGOOD = 0
      SSCALE = 0
      NDS = 0
      DO N = 1, NDSC

*    Get dataset container file name and display
        CALL ADI_FOBNAM( DCFID(N), FILE, I, STATUS )
	IF ( NDSC .EQ. 1 ) THEN
          CALL MSG_PRNT( 'Dataset :-' )
          CALL MSG_PRNT( '   File : '//FILE(:I) )
	ELSE
          CALL MSG_SETI( 'N', N )
          CALL MSG_PRNT( 'Dataset ^N :-' )
          CALL MSG_PRNT( '      File : '//FILE(:I) )
        END IF
	IF ( STATUS .NE. SAI__OK ) CALL ERR_FLUSH( STATUS )

*    Check main data array
        CALL BDI_CHK( DCFID(N), 'Data', OK, STATUS )
        CALL BDI_GETSHP( DCFID(N), ADI__MXDIM, DIMS, NDIM, STATUS )
	IF ( .NOT. OK ) THEN
	  STATUS = SAI__ERROR
	  CALL ERR_REP(' ','Error accessing data array',STATUS )
        END IF
	IF (STATUS.NE.SAI__OK) GOTO 99

*    Check that spectrum is exposure corrected (i.e in ct/s)
        CALL PRF_GET( DCFID(N), 'CORRECTED.EXPOSURE', LOG, STATUS )
        IF ( .NOT. LOG ) THEN
	  CALL MSG_PRNT(' ')
	  CALL MSG_PRNT('!! Warning - data must be corrected to ct/s')
          CALL MSG_PRNT(' ')
	END IF

*    Check existance of vignetting data
        CALL FRI_CHK( DCFID(N), 'VIGN', VIG, STATUS )
        IF ( VIG ) THEN

*      Open vignetting data
          CALL FRI_FOPEN( DCFID(N), 'VIGN', 'BinDS', 'READ', VFID(N),
     :                    STATUS )
	  IF ( STATUS .NE. SAI__OK ) THEN
	    CALL ERR_ANNUL( STATUS )
	    VIG = .FALSE.
          END IF

        END IF

*    Check that vignetting data array is same size as main data array
        IF ( VIG ) THEN
          CALL BDI_CHK( VFID(N), 'Data', OK, STATUS )
          CALL BDI_GETSHP( VFID(N), ADI__MXDIM, VDIMS, NVDIM, STATUS )
          IF (STATUS.NE.SAI__OK) THEN
	    CALL ERR_FLUSH(STATUS)
	    VIG=.FALSE.
	  ELSE IF (.NOT.OK) THEN
	    CALL MSG_PRNT('Error accessing vignetting data array')
	    VIG=.FALSE.
          END IF
	  IF (NVDIM.EQ.NDIM) THEN
	    DO I=1,NDIM
	      IF (VDIMS(I).NE.DIMS(I)) VIG=.FALSE.
	    END DO
          ELSE
	    VIG=.FALSE.
          END IF

        END IF

*    Likelihood case?
	IF ( LIKSTAT ) THEN

*      Get effective exposure time
          CALL TCI_GETID( DCFID(N), TIMID, STATUS )
          CALL ADI_CGET0R( TIMID, 'EffExposure', TEFF, STATUS )

	  IF (STATUS.EQ.SAI__OK) THEN
	    CALL MSG_SETR('TEFF',TEFF)
            CALL MSG_PRNT('    Effective exposure time ^TEFF')
	  ELSE
	    CALL ERR_ANNUL(STATUS)
            CALL ADI_CGET0R( TIMID, 'Exposure', TEFF, STATUS )
	    IF (STATUS.EQ.SAI__OK) THEN
	      CALL MSG_SETR('TEFF',TEFF)
	      CALL MSG_PRNT('Effective exposure time not found - '//
     :          'using EXPOSURE_TIME value of ^TEFF')
            ELSE
	      CALL ERR_REP(' ','No exposure times found in dataset',
     :          STATUS)
	      GOTO 99
	    END IF
          END IF

*      Have data been b/g subtracted?
          CALL PRF_GET( DCFID(N), 'BGND_SUBTRACTED', BGSUB, STATUS )
	  IF ( BGSUB ) THEN
	    CALL MSG_PRNT('    Background-subtracted data')
	  ELSE
	    CALL MSG_PRNT('    Not background-subtracted')
	  END IF

*      Check existance of b/g data
          CALL FRI_CHK( DCFID(N), 'BGND', BG, STATUS )
          IF ( BG ) THEN

*        Open b/g data
            CALL FRI_FOPEN( DCFID(N), 'BGND', 'BinDS', 'READ', BFID(N),
     :                      STATUS )
	    IF ( STATUS .NE. SAI__OK ) THEN
	      CALL ERR_ANNUL( STATUS )
	      BG = .FALSE.
            END IF
          END IF

*      Check that background data array is same size as main data array
	    IF ( BG ) THEN
              CALL BDI_CHK( BFID(N), 'Data', OK, STATUS )
              CALL BDI_GETSHP( BFID(N), ADI__MXDIM, BDIMS, NBDIM,
     :                         STATUS )
	      IF (STATUS.NE.SAI__OK) THEN
	        CALL ERR_FLUSH(STATUS)
	        BG=.FALSE.
	      ELSE IF (.NOT.OK) THEN
	        CALL MSG_PRNT('Error accessing b/g data array')
	        BG=.FALSE.
	      END IF
	      IF (NBDIM.EQ.NDIM) THEN
	        DO I=1,NDIM
	          IF (BDIMS(I).NE.DIMS(I)) BG=.FALSE.
	        END DO
	      ELSE
	        BG=.FALSE.
	      END IF

*         Warn user and exit if it doesn't match
	      IF (.NOT.BG) THEN
	        STATUS=SAI__ERROR
	        CALL ERR_REP(' ','Background array does not match'//
     :          ' data array',STATUS)
	        GOTO 99
	      END IF

*      Abort if b/g has been subtracted, but is not available
	      IF (BGSUB.AND.(.NOT.BG)) THEN
	        STATUS=SAI__ERROR
	        CALL ERR_REP('NOBG','Subtracted background data is'//
     :          ' not available',STATUS)
	        GOTO 99
	      END IF

*      Has background been exposure corrected? (We will require raw count
*                               contribution from b/g expected in the data)
              CALL PRF_GET( BFID(N), 'CORRECTED.EXPOSURE', BGCOR,
     :                      STATUS )

	    END IF

	    IF (.NOT.BG) THEN
	      CALL MSG_PRNT('    No background data found -'//
     :        ' assumed negligible')
	    END IF
	  END IF

*    Is container a spectral set?
	  IF (SPECSET(N)) THEN

*    Spectral set - find number of component spectra
	    IF (NDIM.NE.2) THEN
	      STATUS=SAI__ERROR
	      CALL ERR_REP(' ','Spectral set has incorrect '//
     :        'dimensionality',STATUS)
	    END IF
	    IF (STATUS.NE.SAI__OK) GOTO 99
	    CALL MSG_SETI('NSPEC',DIMS(2))
	    CALL MSG_PRNT('Spectral set containing ^NSPEC spectra')
	    IF (DETNO(N).GT.0) THEN
	      IF (DETNO(N).LT.DIMS(2)) THEN
	        SETSIZE=DETNO(N)
	      ELSE
	        SETSIZE=DIMS(2)
	        DETNO(N)=0		! Flag for `use all spectra'
	      END IF
	      IF (SETSIZE.EQ.1) THEN
	        WRITE(*,100) (DETSEL(I,N),I=1,SETSIZE)
 100	        FORMAT(' Using component number: ',I3)
	      ELSE
	        WRITE(*,110) (DETSEL(I,N),I=1,SETSIZE)
 110	        FORMAT(' Using numbers: ',<SETSIZE>(I3))
	      END IF
	    ELSE
	      SETSIZE = DIMS(2)
	      CALL MSG_PRNT( 'Using all spectra' )
	    END IF

	  ELSE

*    Not a spectral set
	    SETSIZE = 1

	  END IF

*    Loop through component spectra required from a given dataset
	  INDEX = 0
	  NDSTOP = NDS + SETSIZE
	  DO WHILE ( NDS .LT. NDSTOP )
	    NDS=NDS+1

*       Abort if maximum permitted number of datasets is exceeded
	    IF (NDS.GT.NDSMAX) THEN
	      STATUS=SAI__ERROR
	      CALL ERR_REP(' ','Maximum number of input datasets '//
     :        'exceeded',STATUS)
	      GOTO 99
	    END IF

*       Set up name, locator and set position
            CALL ADI_CLONE( DCFID(N), OBDAT(NDS).D_ID, STATUS )

	    IF (SPECSET(N)) THEN
	      INDEX=INDEX+1
	      IF (DETNO(N).GT.0) THEN
	        SPECNO=DETSEL(INDEX,N)
	      ELSE
	        SPECNO=INDEX
	      END IF
	      CALL CHR_ITOC(SPECNO,SPECH,NCH)
	      OBDAT(NDS).DATNAME=FILE(1:CHR_LEN(FILE))//' Spectrum '/
     :                         /SPECH
	    ELSE
	      SPECNO=0
	      OBDAT(NDS).DATNAME = FILE
	    END IF
	    OBDAT(NDS).SETINDEX = SPECNO

*       Map the data array
            CALL BDI_MAPR( OBDAT(NDS).D_ID, 'Data', 'READ', TPTR,
     :                     STATUS )

*       Find and map data array
	    IF ( SPECSET(N) ) THEN

*          Map dynamic memory for slice
              CALL DYN_MAPR( 1, DIMS(1), OBDAT(NDS).DPTR, STATUS )

*          Define the slice
	      LDIM(1) = 1
	      LDIM(2) = SPECNO
	      UDIM(1) = DIMS(1)
	      UDIM(2) = SPECNO
	      OBDAT(NDS).NDIM = 1
	      OBDAT(NDS).IDIM(1) = DIMS(1)
	      OBDAT(NDS).NDAT = DIMS(1)

*          Copy the slice
              CALL ARR_SLCOPR( 2, DIMS, %VAL(TPTR), LDIM, UDIM,
     :                         %VAL(OBDAT(NDS).DPTR), STATUS )

	    ELSE

*          Simple mapping
	      OBDAT(NDS).NDIM = NDIM
	      DO I = 1,OBDAT(NDS).NDIM
	        OBDAT(NDS).IDIM(I) = DIMS(I)
	      END DO
              OBDAT(NDS).DPTR = TPTR
              CALL ARR_SUMDIM( NDIM, DIMS, OBDAT(NDS).NDAT )

	    END IF
	    IF ( STATUS .NE. SAI__OK ) GOTO 99

*         For likelihood case scale to give raw counts, & accumulate SSCALE
	    IF ( LIKSTAT ) THEN
	      PTR = OBDAT(NDS).DPTR
	      CALL DYN_MAPR(1,OBDAT(NDS).NDAT,OBDAT(NDS).DPTR,STATUS)
	      CALL ARR_COP1R(OBDAT(NDS).NDAT,%VAL(PTR),
     :        %VAL(OBDAT(NDS).DPTR),STATUS)
	      IF (STATUS.NE.SAI__OK) GOTO 99
	      CALL ARR_MULTR(TEFF,OBDAT(NDS).NDAT,%VAL(OBDAT(NDS).DPTR))
	    END IF

*       Map variance and quality and use to set up array of data weights

*          Get variance (slice in case of spectral set)
            CALL BDI_CHK( OBDAT(NDS).D_ID, 'Variance', OK, STATUS )
	    IF ( OK ) THEN
	      CALL BDI_MAPR(OBDAT(NDS).D_ID,'Variance','READ',TPTR,
     :                      STATUS)
	      IF (SPECSET(N)) THEN
                CALL ARR_SLCOPR( 2, DIMS, %VAL(TPTR), LDIM, UDIM,
     :                           %VAL(OBDAT(NDS).VPTR), STATUS )
	      ELSE
                OBDAT(NDS).VPTR = TPTR
	      END IF
	    ELSE
	      IF ( WEIGHTS ) THEN
	        CALL MSG_SETI('NDS',NDS)
	        STATUS=SAI__ERROR
	        CALL ERR_REP( ' ', 'No error information available '//
     :          'in dataset ^NDS',STATUS)
	      ELSE
	        OBDAT(NDS).VPTR=0			! Flag
	      END IF
	    END IF
	    IF (STATUS.NE.SAI__OK) GOTO 99

*          Get quality
            CALL BDI_CHK( OBDAT(NDS).D_ID, 'Quality', QUAL, STATUS )
	    IF (QUAL) THEN
	      CALL BDI_MAPL( OBDAT(NDS).D_ID, 'LogicalQuality',
     :                       'READ', TPTR, STATUS )
	      IF (SPECSET(N)) THEN
                CALL ARR_SLCOPL( 2, DIMS, %VAL(TPTR), LDIM, UDIM,
     :                           %VAL(OBDAT(NDS).QPTR), STATUS )
	      ELSE
                OBDAT(NDS).QPTR = TPTR
	      END IF

*         Set quality flag
	      OBDAT(NDS).QFLAG = .TRUE.

	    ELSE
	      OBDAT(NDS).QFLAG=.FALSE.
	      OBDAT(NDS).QPTR=0
	    END IF

	    IF (STATUS.NE.SAI__OK) THEN
	      CALL ERR_ANNUL(STATUS)
	      QUAL=.FALSE.
	    END IF

*        Accumulate counts for data in likelihood case
            IF ( LIKSTAT ) THEN
              IF ( OBDAT(NDS).QFLAG ) THEN
	        CALL FIT_GETDAT_COUNTSQ(OBDAT(NDS).NDAT,
     :                      %VAL(OBDAT(NDS).DPTR),
     :                      %VAL(OBDAT(NDS).QPTR),SSCALE)
              ELSE
	        CALL ARR_SUM1R( OBDAT(NDS).NDAT, %VAL(OBDAT(NDS).DPTR),
     :                          RSUM, STATUS )
                SSCALE = SSCALE + NINT(RSUM)
              END IF
            END IF

*          Map weights as 1D array
	    IF (WEIGHTS) THEN
	      CALL DYN_MAPR(1,OBDAT(NDS).NDAT,OBDAT(NDS).WPTR,STATUS)
	      IF (STATUS.NE.SAI__OK) GOTO 99
	    ELSE
	      OBDAT(NDS).WPTR=0				! Flag
	    END IF

*        Enter weights (=inverse variances)
	    CALL FIT_GETDAT_WTS(WEIGHTS,OBDAT(NDS).NDAT,
     :      %VAL(OBDAT(NDS).VPTR),QUAL,%VAL(OBDAT(NDS).QPTR),
     :      %VAL(OBDAT(NDS).WPTR),NGDAT)
	    IF (NGDAT.EQ.0) THEN
	      CALL MSG_SETI('NDS',NDS)
	      STATUS=SAI__ERROR
	      CALL ERR_REP('NO_GOOD','No good data in dataset ^NDS',STATUS)
	      GOTO 99
	    ELSE
	      NGOOD=NGOOD+NGDAT
	    END IF

*        Default value for vignetting object
            OBDAT(NDS).V_ID = ADI__NULLID
            IF ( VIG ) THEN

*        Store identifier
              OBDAT(NDS).V_ID = VFID(N)

*        Map vignetting array
              CALL BDI_MAPR( VFID(N), 'Data', 'READ', OBDAT(N).VIGPTR,
     :                          STATUS )
	      CALL MSG_PRNT('Loaded associated vignetting array')

            END IF

*        Default value for background object
            OBDAT(NDS).B_ID = ADI__NULLID

*        For likelihood case, Set up OBDAT.TEFF and get background data
	    IF ( LIKSTAT ) THEN
	      OBDAT(NDS).TEFF=TEFF
	      IF (BG) THEN

*            Store background object
                OBDAT(NDS).B_ID = BFID(N)

*            Map background data
	        CALL BDI_MAPR( BFID(N), 'Data', 'READ', TPTR, STATUS )

*            Find and map b/g data array
	        IF (SPECSET(N)) THEN
                  CALL ARR_SLCOPR( 2, DIMS, %VAL(TPTR), LDIM, UDIM,
     :                             %VAL(OBDAT(NDS).BPTR), STATUS )
	        ELSE
                  OBDAT(NDS).BPTR = TPTR

	        END IF

*           Scale b/g to give raw counts if it has been exposure corrected
	        IF (BGCOR) THEN
	          PTR=OBDAT(NDS).BPTR
	          CALL DYN_MAPR(1,OBDAT(NDS).NDAT,OBDAT(NDS).BPTR,STATUS)
	          CALL ARR_COP1R(OBDAT(NDS).NDAT,%VAL(PTR),
     :            %VAL(OBDAT(NDS).BPTR),STATUS)
	          IF (STATUS.NE.SAI__OK) GOTO 99
	          CALL ARR_MULTR(TEFF,OBDAT(NDS).NDAT,%VAL(OBDAT(NDS).BPTR))
	        END IF

*            If b/g has been subtracted then add it back into data and SSCALE
	        IF ( BGSUB ) THEN
	          CALL VEC_ADDR(.FALSE.,OBDAT(N).NDAT,%VAL(OBDAT(N).BPTR),
     :            %VAL(OBDAT(N).DPTR),%VAL(OBDAT(N).DPTR),IERR,NERR,
     :            STATUS)
	        END IF

*            Accumulate counts for data in likelihood case. Use quality if
*            present in input data (rather than bgnd)
                IF ( OBDAT(NDS).QFLAG ) THEN
	          CALL FIT_GETDAT_COUNTSQ(OBDAT(NDS).NDAT,
     :                      %VAL(OBDAT(NDS).BPTR),
     :                      %VAL(OBDAT(NDS).QPTR),SSCALE)
                ELSE
	          CALL ARR_SUM1R( OBDAT(NDS).NDAT,
     :                      %VAL(OBDAT(NDS).BPTR), RSUM, STATUS )
                  SSCALE = SSCALE + NINT(RSUM)
                END IF

*         No background data - set up array of zeros
	      ELSE
	        CALL DYN_MAPR(1,OBDAT(NDS).NDAT,OBDAT(NDS).BPTR,STATUS)
	        CALL ARR_INIT1R(0.0,OBDAT(NDS).NDAT,
     :                      %VAL(OBDAT(NDS).BPTR),STATUS)
	      END IF
	    END IF

*............ OBDAT set up ..............................................

*    Hardwire CONVOLVE flag false in cluster fitting.
            IF ( GENUS .EQ. 'CLUS' ) THEN
              PREDDAT(N).CONVOLVE = .FALSE.
            ELSE
*      Look for instrument response, set up INSTR if found, and report
	      CALL FIT_GETINS( OBDAT(NDS).D_ID, SPECNO, 1,
     :               PREDDAT(NDS).CONVOLVE, INSTR(NDS), STATUS )
	      IF (STATUS.NE.SAI__OK) GOTO 99
            END IF

	    IF (PREDDAT(NDS).CONVOLVE) THEN

*      Check that data are 1D
	      IF (OBDAT(NDS).NDIM.GT.1) THEN
	        STATUS=SAI__ERROR
	        CALL ERR_REP(' ','Convolution with instrument response'
     :          //' is only supported for 1D data at present',STATUS)
	        GOTO 99
	      END IF
	    END IF

*      Find remaining components of PREDDAT(NDS)
	  CALL FIT_PREDSET( OBDAT(NDS).D_ID, NDS, WORKSPACE,
     :                      OBDAT(NDS), PREDDAT(NDS), STATUS )

	END DO

      END DO

*  Exit point
 99   IF ( STATUS .NE. SAI__OK ) THEN
        CALL AST_REXIT( 'FIT_GETDAT', STATUS )
      END IF

      END


*+  FIT_GETDAT_COUNTSQ - Sums raw counts in dataset
      SUBROUTINE FIT_GETDAT_COUNTSQ(NDAT,DATA,QUAL,COUNTS)
*    Description :
*     Counts from the (REAL) DATA array are accumulated in COUNTS
*    History :
*     15 Jun 92: Original (TJP)
*    Type definitions :
	IMPLICIT NONE
*    Import :
	INTEGER NDAT		! No of data values
	REAL DATA(*)		! Data array
        LOGICAL QUAL(*)         ! Quality array
*    Import-Export :
	INTEGER COUNTS		! Counts accumulator
*    Export :
*    Local constants :
*    Local variables :
	INTEGER I
*-

	DO I=1,NDAT
          IF ( QUAL(I) ) COUNTS=COUNTS+NINT(DATA(I))
	END DO
	END


*+  FIT_GETDAT_WTS - Sets up array of data weights
      SUBROUTINE FIT_GETDAT_WTS(WEIGHTS,NDAT,VARR,QUAL,QARR,WTARR,
     :                            NGOOD)
*    Description :
*     Array of data weights equal to inverse variance for good data and
*     zero for bad, is set up.
*     Data with errors less than or equal to zero are treated as bad.
*     If WEIGHTS=false then routine only counts the number of good values.
*    History :
*     30 Mar 87: Original (TJP)
*     16 Aug 88: WEIGHTS argument added (TJP)
*     14 Feb 89: ASTERIX88 version, variance and logical quality passed in (TJP)
*    Type Definitions :
	IMPLICIT NONE
*    Import :
	LOGICAL WEIGHTS		! Set up weights?
	INTEGER NDAT		! No of data values
	REAL VARR(*)		! Array of data variances
	LOGICAL QUAL		! Quality info present?
	LOGICAL QARR(*)		! Quality array
*    Import-Export :
*    Export :
	REAL WTARR(*)		! Data weights
	INTEGER NGOOD		! No of good data
*    Local constants :
*    Local variables :
	INTEGER I
*-

	NGOOD=0

* Set up weights
	IF (WEIGHTS) THEN
	  IF (QUAL) THEN
	    DO I=1,NDAT
	      IF (QARR(I).AND.VARR(I).GT.0.0) THEN
	        WTARR(I)=1.0/VARR(I)
	        NGOOD=NGOOD+1
	      ELSE
	        WTARR(I)=0.0
	      END IF
	    END DO
	  ELSE
	    DO I=1,NDAT
	      IF (VARR(I).GT.0.0) THEN
	        WTARR(I)=1.0/VARR(I)
	        NGOOD=NGOOD+1
	      ELSE
	        WTARR(I)=0.0
	      END IF
	    END DO
	  END IF

* No weights to be set up
	ELSE
	  IF ( QUAL ) THEN
	    DO I=1,NDAT
	      IF (QARR(I)) THEN
	        NGOOD=NGOOD+1
	      END IF
	    END DO
	  ELSE
	    NGOOD=NGOOD+NDAT
	  END IF
	END IF

	END
