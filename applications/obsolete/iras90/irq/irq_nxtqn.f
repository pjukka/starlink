      SUBROUTINE IRQ_NXTQN( LOCS, CONTXT, QNAME, FIXED, VALUE, BIT,
     :                      COMMNT, DONE, STATUS )
*+
*  Name:
*     IRQ_NXTQN

*  Purpose:
*     Return the next quality name.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_NXTQN( LOCS, CONTXT, QNAME, FIXED, VALUE, BIT,
*                     COMMNT, DONE, STATUS )

*  Description:
*     This routine returns the next quality name defined in the NDF
*     specified by LOCS, together with supplementary information.  The
*     next quality name is determined by the value of CONTXT. If CONTXT
*     is zero on entry then the first quality name is returned.  On
*     exit, CONTXT is set to a value which indicates where the next
*     quality name is stored within the NDF. This value can be passed
*     to a subsequent call to this routine to retrieve information
*     about the next quality name.

*  Arguments:
*     LOCS(5) = CHARACTER * ( * ) (Given)
*        An array of 5 HDS locators. These locators identify the NDF
*        and the associated quality name information.  They should have
*        been obtained using routine IRQ_FIND or routine IRQ_NEW.
*     CONTXT = INTEGER (Given and Returned)
*        The context of the current call. This should be set to zero
*        before the first call to this routine, and then left unchanged
*        between subsequent calls.
*     QNAME = CHARACTER * ( * ) (Returned)
*        The next quality name. The character variable supplied for this
*        argument should have a declared length equal to the symbolic
*        constant IRQ__SZQNM.
*     FIXED = LOGICAL (Returned)
*        If true, then the quality is either held by all pixels, or by
*        no pixels. In this case the quality does not have a
*        corresponding bit in the QUALITY component. If false, then
*        some pixels have the quality and some don't, as indicated by
*        the corresponding bit in the QUALITY component.
*     VALUE = LOGICAL (Returned)
*        If FIXED is true, then VALUE specifies whether all pixels hold
*        the quality ( VALUE = .TRUE. ), or whether no pixels hold the
*        quality ( VALUE = .FALSE. ). If FIXED is false, then VALUE is
*        indeterminate.
*     BIT = INTEGER (Returned)
*        If FIXED is false, then BIT holds the corresponding bit number
*        in the QUALITY component. The least significant bit is called
*        bit 1 (not bit 0). If FIXED is true, then BIT is
*        indeterminate.
*     COMMNT = CHARACTER * ( * ) (Returned)
*        The descriptive comment which was stored with the quality name.
*        The supplied character variable should have a declared length
*        given by symbolic constant IRQ__SZCOM.
*     DONE = LOGICAL (Returned)
*        Returned true if this routine is called when no more names
*        remain to be returned.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Arguments Given:
      CHARACTER LOCS(5)*(*)

*  Arguments Given and Returned:
      INTEGER CONTXT

*  Arguments Returned:
      CHARACTER QNAME*(*)
      LOGICAL FIXED
      LOGICAL VALUE
      INTEGER BIT
      CHARACTER COMMNT*(*)
      LOGICAL DONE

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      LOGICAL BLANK              ! True if the current slot is not in
                                 ! use.
      INTEGER INDF               ! Identifier for the NDF containing the
                                 ! quality names information.
      INTEGER LUSED              ! Index of last used slot.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain the NDF identifier from LOCS, and check it is still valid.
      CALL IRQ1_INDF( LOCS, INDF, STATUS )

*  Initialise DONE to FALSE.
      DONE = .FALSE.

*  If CONTXT is negative, set DONE to TRUE and return immediately.
      IF( CONTXT .LT. 0 ) THEN
         DONE = .TRUE.
         GO TO 999
      END IF

*  Find the index of the last used slot.
      CALL DAT_GET0I( LOCS(3), LUSED, STATUS )

*  Loop until a used name is found, or the end is reached.
      BLANK = .TRUE.
      DO WHILE( ( .NOT. DONE ) .AND. ( BLANK ) .AND.
     :          ( STATUS .EQ. SAI__OK ) )

*  Increment CONTXT.
         CONTXT = CONTXT + 1

*  If CONTXT points beyond the last used slot, set DONE to TRUE, and set
*  CONTXT negative.
         IF( CONTXT .GT. LUSED ) THEN
            DONE = .TRUE.
            CONTXT = -1

*  Otherwise, get quality name from the slot with index equal to CONTXT.
         ELSE

            CALL ERR_MARK

            CALL IRQ1_GET( LOCS, CONTXT, QNAME, FIXED, VALUE, BIT,
     :                     COMMNT, STATUS )

*  If the slot was not in use, annul the error.
            IF( STATUS .EQ. IRQ__BADSL ) THEN
               CALL ERR_ANNUL( STATUS )

*  If a good name was found, flag it.
            ELSE IF( STATUS .EQ. SAI__OK ) THEN
               BLANK = .FALSE.

            END IF

            CALL ERR_RLSE

         END IF

      END DO

*  If an error occur, give context information.
 999  CONTINUE
      IF( STATUS .NE. SAI__OK ) THEN
         CALL NDF_MSG( 'NDF', INDF )
         CALL ERR_REP( 'IRQ_NXTQN_ERR1',
     :       'IRQ_NXTQN: Unable to get next quality name from NDF ^NDF',
     :        STATUS )
      END IF


      END
