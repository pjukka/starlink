      SUBROUTINE WCSSHOW( STATUS )
*+
*  Name:
*     WCSSHOW

*  Purpose:
*     Examine the internal structure of an AST Object.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL WCSSHOW( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application allows you to examine an AST Object stored in a
*     specified NDF or HDS object. The structure can be dumped to a text
*     file, or a Graphical User Interface can be used to navigate through 
*     the structure (see parameter LOGFILE). A new FrameSet can also be 
*     stored in the WCS component of the NDF (see parameter NEWWCS). This
*     allows an NDF WCS component to be dumped to a text file, edited, and
*     then restored to the NDF.
*
*     The GUI main window contains the attribute values of the supplied AST 
*     Object. Only those associated with the Object's class are displayed
*     initially, but attributes of the Objects parent classes can be
*     displayed by clicking one of the class button to the top left of the
*     window.
*
*     If the Object contains attributes which are themselves AST Objects
*     (such as the Frames within a FrameSet), then new windows can be
*     created to examine these attributes by clicking over the attribute
*     name.

*  Usage:
*     wcsshow ndf object logfile newwcs full quiet

*  ADAM Parameters:
*     FULL = _INTEGER (Read)
*        This parameter is a three-state flag and takes values of -1, 0 or
*        +1. It controls the amount of information included in the output 
*        generated by this application. If FULL is zero, then a modest 
*        amount of non-essential but useful information will be included 
*        in the output. If FULL is negative, all non-essential information 
*        will be suppressed to minimise the amount of output, while if it is
*        positive, the output will include the maximum amount of detailed 
*        information about the Object being examined. [current value]
*     LOGFILE = FILENAME (Write)
*        The name of the text file in which to store a dump of the
*        specified AST Object. If a null (!) value is supplied, no log
*        file is created. If a log file is given, the Tk browser window
*        is not produced. [!]
*     NDF = NDF (Update)
*        If an NDF is supplied, then its WCS FrameSet is displayed. If a
*        null (!) value is supplied, then the parameter OBJECT is used to
*        specify the AST Object to display.
*     NEWWCS = GROUP (Read)
*        A group expression giving a dump of an AST FrameSet which
*        is to be stored as the WCS component in the NDF given by parameter 
*        NDF. The existing WCS component is unchanged if a null value is
*        supplied. This parameter is only accessed if a non-null value is
*        supplied for parameter NDF. The Base Frame in the FrameSet is
*        assumed to be the GRID Frame. If a value is given for this
*        parameter, then the log file or Tk browser will display the new 
*        FrameSet (after being stored in the NDF and retrieved). [!]
*     OBJECT = LITERAL (Read)
*        The HDS object containing the AST Object to display. Only
*        accessed if parameter NDF is null. It must have an HDS type 
*        of WCS, must be scalar, and must contain a single 1-D array component 
*        with name DATA and type _CHAR.
*     QUIET = _LOGICAL (Read)
*        If TRUE, then the structure of the AST Object is not displayed
*        (using the Tk GUI). Other functions are unaffected. The dynamic
*        default is TRUE if a non-null value is supplied for parameter 
*        LOGFILE or parameter NEWWCS, and FALSE otherwise. []

*  Examples:
*     wcsshow m51
*        Displays the WCS component of the NDF m51 in a Tk GUI.
*     wcsshow m51 logfile=m51.ast
*        Dumps the WCS component of the NDF m51 to text file m51.ast.
*     wcsshow m51 newwcs=^m51.ast
*        Reads a FrameSet from the text file m51.ast and stores it in the
*        WCS component of the NDF m51. For instance, the text file m51.ast
*        could be an edited version of the text file created in the
*        previous example.
*     wcsshow object="~/agi_starprog.agi_3800_1.picture(4).more.ast_plot"
*        Displays the AST Plot stored in the AGI database with X windows
*        picture number 4.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2-APR-1998 (DSB):
*        Original version.
*     5-OCT-1998 (DSB):
*        Added parameter NDF.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! HDS constants 
      INCLUDE 'PAR_ERR'          ! PAR error constants 
      INCLUDE 'GRP_PAR'          ! GRP constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations

*  Global Variables:
      INCLUDE 'KPG_AST'          ! KPG AST common blocks.
*        ASTGRP = INTEGER (Write)
*           GRP identifier for the group.
*        ASTGSP = CHARACTER * 1 (Write)
*           The character to be prepended to the text. Ignored if blank.
*        ASTLN = INTEGER (Write)
*           Index of previous GRP element to be read.

*  Status:
      INTEGER STATUS

*  External References:
      EXTERNAL KPG1_ASGFR        ! Source function for AST Channel
      EXTERNAL KPG1_ASGFW        ! Sink function for AST Channel

*  Local Variables:
      CHARACTER LOC*(DAT__SZLOC)
      CHARACTER LOGFNM*(GRP__SZFNM)
      CHARACTER TITLE*255
      INTEGER CHAN
      INTEGER FULL
      INTEGER IAST
      INTEGER IGRP
      INTEGER INDF
      INTEGER SIZE
      INTEGER TLEN
      LOGICAL QUIET

*  Check inherited status.      
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get the degree of detail required in the output.
      CALL PAR_GET0I( 'FULL', FULL, STATUS )

*  Indicate there is no Object to display yet.
      IAST = AST__NULL

*  Initially assume that the Object should be displayed in the GUI.
      QUIET = .FALSE.

*  Get an NDF identifier.
      CALL NDF_ASSOC( 'NDF', 'UPDATE', INDF, STATUS )

*  If succesful...
      IF( STATUS .EQ. SAI__OK ) THEN

*  Attempt to get a group expression using parameter NEWWCS.
         IGRP = GRP__NOID
         CALL KPG1_GTGRP( 'NEWWCS', IGRP, SIZE, STATUS )

*  If succesful, assume the th eObject is not to be displayed.
         IF( STATUS .EQ. SAI__OK ) THEN
            QUIET = .TRUE.

*  Create an AST Channel which can be used to read AST Objects from the 
*  group. Set the Skip attribute non-zero so that non-AST data which 
*  occur between AST Objects are ignored.
            CHAN = AST_CHANNEL( KPG1_ASGFR, AST_NULL, 'SKIP=1', STATUS )

*  Store the identifier for the group containing the dump in common so
*  that it can be used by the source function KPG1_ASGFR. Also initialise
*  the index of the last group element to have been read.
            ASTGRP = IGRP
            ASTLN = 0

*  Attempt to read an Object from the group.
            IAST = AST_READ( CHAN, STATUS )

*  If FrameSet was read...
            IF( IAST .NE. AST__NULL ) THEN
               IF( AST_ISAFRAMESET( IAST, STATUS ) ) THEN

*  Store it in the NDF. 
                  CALL NDF_PTWCS( IAST, INDF, STATUS )
    
*  Report an error if the Object read is not a FrameSet.
               ELSE 
                  STATUS = SAI__ERROR
                  CALL MSG_SETC( 'CLASS', AST_GETC( IAST, 'CLASS', 
     :                                              STATUS ) )
                  CALL ERR_REP( 'WCSSHOW_ERR', 'An AST ^CLASS has '//
     :                          'been supplied using parameter '//
     :                          '%NEWWCS. A FrameSet must be supplied.',
     :                          STATUS )
               END IF

*  Annul the pointer to the supplied Object.
               CALL AST_ANNUL( IAST, STATUS )

*  Report an error if no Object was read.
            ELSE IF( STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( 'WCSSHOW_ERR', 'Could not read an AST '//
     :                       'Object using parameter %NEWWCS.', STATUS )
            END IF

*  Delete the group.
            CALL GRP_DELET( IGRP, STATUS )

*  If a null value was supplied for NEWWCS, annul the error.
         ELSE IF( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
         END IF

*  Get a pointer to the NDFs WCS FrameSet.
         CALL NDF_GTWCS( INDF, IAST, STATUS )

*  Save the name of the NDF in an MSG token.
         CALL NDF_MSG( 'OBJ', INDF )

*  Annul the NDF identifier.
         CALL NDF_ANNUL( INDF, STATUS )

*  If a null value was supplied for NDF, annull the error and use
*  parameter OBJECT to get the AST Object to display.
      ELSE IF( STATUS .EQ. PAR__NULL ) THEN      
         CALL ERR_ANNUL( STATUS )

*  Get a locator to the HDS object.
         CALL DAT_ASSOC( 'OBJECT', 'READ', LOC, STATUS )

*  Read an AST Object from the HDS object.
         CALL KPG1_WREAD( LOC, ' ', IAST, STATUS )

*  Save the name of the Object in an MSG token.
         CALL DAT_MSG( 'OBJ', LOC )

*  Annul the HDS locator.
         CALL DAT_ANNUL( LOC, STATUS )

      END IF

*  Abort if an error has occurred, or there is no Object to display.
      IF( STATUS .NE. SAI__OK .OR. IAST .EQ. AST__NULL ) GO TO 999

*  See if a logfile is required.
      CALL PAR_GET0C( 'LOGFILE', LOGFNM, STATUS )

*  If so, assume that the Object is not to be displayed in the Tk GUI, and
*  dump the AST Object to a GRP group.
      IF( STATUS .EQ. SAI__OK ) THEN
         QUIET = .TRUE.

*  Create THE GRP to act as a temporary staging post for the file.
         CALL GRP_NEW( ' ', IGRP, STATUS )

*  Create an AST Channel which can be used to write the Object description
*  to the group.
         CHAN = AST_CHANNEL( AST_NULL, KPG1_ASGFW, ' ', STATUS )
         CALL AST_SETI( CHAN, 'FULL', FULL, STATUS )
         ASTGRP = IGRP
         ASTGSP = ' '

*  Write the OBJECT to the group. Report an error if nothing is
*  written.
         IF( AST_WRITE( CHAN, IAST, STATUS ) .EQ. 0 .AND. 
     :       STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'WCSSHOW_ERR', 'WCSSHOW: Failed to write '//
     :                    'an AST Object to a GRP group (possible '//
     :                    'programming error).', STATUS )
         END IF

*  Write the group contents out to a file.
         CALL GRP_LIST( 'LOGFILE', 0, 0, ' ', IGRP, STATUS ) 

*  Delete the group.
         CALL GRP_DELET( IGRP, STATUS )

*  If no log file was supplied, annul the error.
      ELSE IF( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
      END IF

*  See if the Object is to be displayed in the GUI.
      CALL PAR_DEF0L( 'QUIET', QUIET, STATUS )
      CALL PAR_GET0L( 'QUIET', QUIET, STATUS )

*  If so (and we have an Object), display it.
      IF( .NOT. QUIET .AND. IAST .NE. AST__NULL ) THEN

*  Display the AST Object in a TK window.
         CALL MSG_LOAD( ' ', '^OBJ', TITLE, TLEN, STATUS )       
         CALL KPG1_TKAST( IAST, TITLE( : TLEN ), FULL, STATUS )

      END IF

 999  CONTINUE

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'WCSSHOW_ERR', 'Error displaying an AST '//
     :                 'Object.', STATUS )
      END IF

      END
