      SUBROUTINE ARD1_STWCS( NDIM, PAR, UWCS, STATUS )
*+
*  Name:
*     ARD1_STWCS

*  Purpose:
*     Create a new user FrameSet from a STRETCH statement.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_STWCS( NDIM, PAR, UWCS, STATUS )

*  Description:
*     This routine creates a new user FrameSet (UWCS) from the 
*     supplied parameters.

*  Arguments:
*     NDIM = INTEGER (Given)
*        The number of axes.
*     PAR( * ) = DOUBLE PRECISION (Given)
*        The statement parameters.
*     UWCS = INTEGER (Given)
*        An AST pointer to the User FrameSet. The Current Frame
*        in this FrameSet is user coords.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     12-JUL-2001 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations

*  Arguments Given:
      INTEGER NDIM
      DOUBLE PRECISION PAR( * )

*  Arguments Returned:
      INTEGER UWCS

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER M1                 ! MatrixMap

*.

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Create a matrixmap from old user coords to new user coords.
      M1 = AST_MATRIXMAP( NDIM, NDIM, 1, PAR, ' ', STATUS ) 

*  Remap the user coords Frame (i.e. the current Frame).
      CALL AST_REMAPFRAME( UWCS, AST__CURRENT, M1, STATUS )

*  Annull AST objects.
      CALL AST_ANNUL( M1, STATUS )

      END
