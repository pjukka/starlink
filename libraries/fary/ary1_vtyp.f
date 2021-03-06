      SUBROUTINE ARY1_VTYP( TYPE, VTYPE, STATUS )
*+
*  Name:
*     ARY1_VTYP

*  Purpose:
*     Validate a type specification string.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARY1_VTYP( TYPE, VTYPE, STATUS )

*  Description:
*     The routine checks a data type specification string for validity.
*     To be valid it must specify one of the HDS primitive numeric data
*     types. An error is reported if the string supplied is not valid.

*  Arguments:
*     TYPE = CHARACTER * ( * ) (Given)
*        The data type specification to be checked (case insensitive).
*     VTYPE = CHARACTER * ( * ) (Returned)
*        If valid, this argument returns the data type string in upper
*        case.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  Check the string supplied against each permitted value in turn,
*     setting the returned argument accordingly.
*     -  If the string is not valid, then report an error.

*  Copyright:
*     Copyright (C) 1989 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     9-JUN-1989  (RFWS):
*        Original version.
*     22-AUG-1989 (RFWS):
*        Corrected error in argument list of ARY1_CCPY. Also added more
*        comments.
*     2012-05-07 (TIMJ):
*        Add _INT64 support.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'ARY_ERR'          ! ARY_ error codes

*  Arguments Given:
      CHARACTER * ( * ) TYPE

*  Arguments Returned:
      CHARACTER * ( * ) VTYPE

*  Status:
      INTEGER STATUS             ! Global status

*  External references:
      LOGICAL CHR_SIMLR          ! Case insensitive string comparison

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check the data type string supplied against each permitted value in
*  turn, setting the returned argument accordingly.

*  ...byte data type.
      IF ( CHR_SIMLR( TYPE, '_BYTE' ) ) THEN
         CALL ARY1_CCPY( '_BYTE', VTYPE, STATUS )

*  ...unsigned byte data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_UBYTE' ) ) THEN
         CALL ARY1_CCPY( '_UBYTE', VTYPE, STATUS )

*  ...double precision data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_DOUBLE' ) ) THEN
         CALL ARY1_CCPY( '_DOUBLE', VTYPE, STATUS )

*  ...integer data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_INTEGER' ) ) THEN
         CALL ARY1_CCPY( '_INTEGER', VTYPE, STATUS )

*  ...real data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_REAL' ) ) THEN
         CALL ARY1_CCPY( '_REAL', VTYPE, STATUS )

*  ...word data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_WORD' ) ) THEN
         CALL ARY1_CCPY( '_WORD', VTYPE, STATUS )

*  ...unsigned word data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_UWORD' ) ) THEN
         CALL ARY1_CCPY( '_UWORD', VTYPE, STATUS )

*  ...64-bit integer data type.
      ELSE IF ( CHR_SIMLR( TYPE, '_INT64' ) ) THEN
         CALL ARY1_CCPY( '_INT64', VTYPE, STATUS )

*  If the data type string is invalid, then report an error.
      ELSE
         STATUS = ARY__TYPIN
         CALL MSG_SETC( 'BADTYPE', TYPE )
         CALL ERR_REP( 'ARY1_VTYP_BAD',
     :   'Invalid array data type ''^BADTYPE'' specified (possible ' //
     :   'programming error).', STATUS )
      END IF

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL ARY1_TRACE( 'ARY1_VTYP', STATUS )

      END
