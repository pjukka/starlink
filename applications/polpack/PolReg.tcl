#!/star/bin/awish
#+
#  Name:
#     PolReg.tcl
#
#  Purpose:
#     The main polreg tcl script.
#
#  Invocation:
#     1) From the command line:
#        PolReg.tcl <in> <out_O> [ <out_E> ]
#
#     2) From the polreg A-task. 
#        See the polreg A-task documentation.
#
#  Command Line Arguments:
#     in    - A list of input images.
#     out_O - A list of O-ray output images.
#     out_E - An optional list of E-ray output images. If not supplied,
#             then PolReg functions in single-beam mode.
#  
#  Command Line Examples:
#
#     PolReg.tcl "a b" "a_O b_O" "a_E b_E"
#
#        Extracts O and E ray areas from the two input images "a" and "b",
#        aligns them, and stores the O-ray areas in images "a_O" and "b_O",
#        and the E-ray areas in images "b_O" and "b_E" (dual-beam mode).
#
#     PolReg.tcl "a b" "a_R b_R" 
#
#        Aligns the two input images "a" and "b", and stores them in 
#        images "a_R" and "b_R" (single-beam mode).
#-

# Uncomment this section to see the names of all procedure as they are 
# called...

#rename proc tclproc
#tclproc proc {name args body} {
#   set newbody "puts \"Entering $name...\""
#   append newbody $body
#   tclproc $name $args $newbody
#}

# Display a label asking the user to wait while the main interface is
# constructed.
   set wait [label .wait -text "  Please Wait...  " -bd 3 -relief sunken \
                               -background #c0c0c0]
   pack $wait -ipadx 4m -ipady 4m -padx 4m -pady 2m -fill y -expand 1

# Set the number of digits used by tcl to represent floating point values as
# strings.
   set tcl_precision 15

# Get the operating system
   catch {exec uname -s} OS

# Get the pixels per inch on the screen.
   if { ![info exists dpi] } {
      set dpi [winfo fpixels . "1i"]
   }       

# Set the size of the GWM canvas item.
   set SIZE [expr round( ( 350.0 * $dpi ) / 88.0 ) ]

# Get the process id for the current process.
   set PID [pid]

# Initialise polreg global constants.
   set BACKCOL "#c0c0c0"
   set CB_COL yellow
   set CHAR_LIST {0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ}
   set CHAR_STOP {.}
   set COLOURS 64
   set DEVICE "xw;polreg_$PID"
   set E_RAY_FEATURES 1
   set E_RAY_MASK 3
   set E_RAY_SKY 6
   set GWM_NAME "polreg_$PID"
   set MAPTYPE(0) "<not used in single-beam mode>"
   set MAPTYPE(1) "Shift of origin only" 
   set MAPTYPE(2) "Shift and rotation"
   set MAPTYPE(3) "Shift and magnification"
   set MAPTYPE(4) "Shift, rotation and magnification"
   set MAPTYPE(5) "Full 6 parameter fit"
   set MENUBACK "#b0b0b0"
   set NONE 5
   set O_RAY_FEATURES 0
   set O_RAY_MASK 2
   set O_RAY_SKY 4
   set RB_COL red
   set RTOD 57.29578
   set SKY_AREA 1
   set SKY_FRAME 2

# Store object names.
   set OBJTYPE($E_RAY_FEATURES) "E-ray features" 
   set OBJTYPE($E_RAY_MASK) "E-ray mask"
   set OBJTYPE($NONE) "None"
   set OBJTYPE($O_RAY_FEATURES) "O-ray features" 
   set OBJTYPE($O_RAY_MASK) "O-ray mask"
   set OBJTYPE($O_RAY_SKY) "O-ray sky area"
   set OBJTYPE($E_RAY_SKY) "E-ray sky area"

# Initialise polreg global variables.
   set ADAM_TASKS ""
   set AUTO_MATCH 1
   set ATASK 0
   set BADCOL cyan
   set BASE_SECTION ""
   set CANCEL_WAIT 0
   set CURCOL red
   set CUROBJ_DISP ""
   set CUROBJ_REQ $O_RAY_FEATURES
   set CURRENT_INFO ""
   set CURSOR_STACK ""
   set DEFAULT_INFO ""
   set DOING_DOUBLE 0
   set INFO_TEXT ""
   set F3 ""
   set F4 ""
   set F_OWNER "."
   set HELP ""
   set IFILE 0
   set IFILE_STACK ""
   set IMAGE_DISP ""
   set IMSEC_DISP ""
   set INV 0
   set LABELS ""
   set LOCK_SCALE 0
   set LOGFILE_ID ""
   set MODE 0
   set OLDVIS "VisibilityObscured"
   set PHI_DISP ""
   set PHI_REQ 95.0
   set PLO_DISP ""
   set PLO_REQ 5.0
   set POINTER_PXY ""
   set POINTER_CXY ""
   set REDISPLAY_CANCELLED 0
   set REDISPLAY_REQUESTED 0
   set REFCOL green
   set REFIM_DISP ""
   set REFOBJ_DISP ""
   set REFOBJ_REQ $NONE
   set RESAVE 1
   set ROOTI ""
   set RRB_DISABLED ""
   set SAREA 1
   set SECTION_DISP ""
   set SECTION_REQ ""
   set SECTION_STACK ""
   set SELCOL red
   set SELECTED_AREA ""
   set SEQ_STOP ""
   set STOP_BLINK ""
   set TEST_ID ""
   set V0 ""
   set V1 ""
   set VID0 ""
   set VID1 ""
   set VID2 ""                
   set XHAIR 0
   set XHAIR_IDH ""
   set XHAIR_IDV ""
   set XHRCOL "LemonChiffon"

# Get the name of the directory containing the PolReg files. This TCL
# variable should have been set in the calling ADAM A-task, but if it
# wasn't (for instance if this script is called directly rather than by the
# A-task), then use the environment variable value to set it.
   if { ![info exists POLPACK_DIR] } {
      if { [info exists env(POLPACK_DIR)] } {
         set POLPACK_DIR $env(POLPACK_DIR)
      } {
         set POLPACK_DIR /star/bin/polpack
      }
   }

# Save the path to the directory containing POLPACK hypertext documents.
   set POLPACK_HELP $POLPACK_DIR/../../help/polpack

# Get the paths to the CCDPACK and KAPPA directories from the corresponding
# environment variables.
   if { [info exists env(KAPPA_DIR)] } {
      set KAPPA_DIR $env(KAPPA_DIR)
   } else {
      set KAPPA_DIR /star/bin/kappa
   }

   if { [info exists env(CCDPACK_DIR)] } {
      set CCDPACK_DIR $env(CCDPACK_DIR)
   } else {
      set CCDPACK_DIR /star/bin/ccdpack
   }

   if { $OS == "Linux" } {
      if { [info exists env(IRCAMPACK_DIR)] } {
         set IRCAMPACK_DIR $env(IRCAMPACK_DIR)
      } else {
         set IRCAMPACK_DIR /star/bin/ircampack
      }
   }

#  Name this application (for xresources etc.)
   tk appname PolReg

# Rename the "exit" command so that it calls a procedure which cleans up,
# and then calls the built-in shut-down commands. This new exit command is 
# called even if an exceptional exit occurs.
   rename exit tcl_exit

# Define the procedures which form part of the PolReg application.
   source $POLPACK_DIR/dialog.tcl
   source $POLPACK_DIR/PolReg_procs.tcl
   source $POLPACK_DIR/CCDShowHelp.tcl

# If the variable START_HELP has been defined (by the polreg a-task) then
# start up a hyper-text browser displaying the polreg manual contents page.
   if { [info exists START_HELP] } { ShowHelp POLREG_CONTENTS }

# Quit when control-c is pressed.
   bind . <Control-c> {Finish 0}

# Set the font pixel sizes, so that he fonts are the same physical size
# independant of the screen resolution.
   set px140 [expr round( ( 14.0 * $dpi ) / 88.0 ) ]   
   set px120 [expr round( ( 12.0 * $dpi ) / 88.0 ) ]   
   set px100 [expr round( ( 10.0 * $dpi ) / 88.0 ) ]   

# Attempt to find suitable fonts. Issue a warning and use default fonts
# if the fonts cannot be found.
   set FONT [SelectFont "-*-*-bold-r-*-*-$px140-*-*-*-*-*-*-*"]
   set HLP_FONT [SelectFont "-*-*-medium-r-*-*-$px120-*-*-*-*-*-*-*"]
   set B_FONT [SelectFont "-*-*-bold-r-*-*-$px120-*-*-*-*-*-*-*"]
   set RB_FONT [SelectFont "-*-*-medium-r-*-*-$px120-*-*-*-*-*-*-*"]
   set S_BFONT [SelectFont "-*-*-bold-r-*-*-$px120-*-*-*-*-*-*-*"]
   set S_FONT [SelectFont "-*-*-medium-r-*-*-$px120-*-*-*-*-*-*-*"]

   if { $FONT == "" || $HLP_FONT == "" || $RB_FONT == "" || $S_BFONT == "" || $S_FONT == "" || $B_FONT == "" } {
      set FONT ""
      set HLP_FONT ""
      set B_FONT ""
      set RB_FONT ""
      set S_BFONT ""
      set S_FONT ""
      Message "The preferred fonts for use on a $dpi pixels per inch screen cannot be found. Using default fonts..."
   }

# Try to stop problems with the AMS (ADAM Message System) rendevous files 
# by creating a new directory as ADAM_USER.
   if { [info exists env(ADAM_USER)] } {
      set OLD_ADAM_USER $env(ADAM_USER)
      set ADAM_USER "$OLD_ADAM_USER/polreg_[pid]"
   } {
      set OLD_ADAM_USER ""
      set ADAM_USER "$env(HOME)/adam/polreg_[pid]"
   }
   set env(ADAM_USER) $ADAM_USER

# Make sure this new directory exists (delete any existing version).
   if { [file exists $ADAM_USER] } {
      catch {exec rm -r -f $ADAM_USER}
   }
   catch {exec mkdir -p $ADAM_USER}

# Avoid messing up the main AGI database by using a new AGI database.
# Create it in the ADAM_USER directory created above.
   if { [info exists env(AGI_USER)] } {
      set OLD_AGI_USER $env(AGI_USER)
   } {
      set OLD_AGI_USER ""
   }
   set env(AGI_USER) $ADAM_USER

# Record the process id's of any existing KAPPA processes. All new processes
# are killed on exit, but processes active on entry are not killed.
   if { ![ catch {exec ps | grep kappa | grep -v grep | \
                  awk {{print $1}} } OLDKAPPA ] } { 
      set OLDKAPPA {}
   }

# Do the same for any existing CCDPACK processes.
   if { ![ catch {exec ps | grep ccdpack | grep -v grep | \
                  awk {{print $1}} } OLDCCDPACK ] } { 
      set OLDCCDPACK {}
   }

# Define Startcl procedures (this must be done after the ADAM_USER
# directory has been set up).
   source $POLPACK_DIR/adamtask.tcl

# The adamtask.tcl file creates a binding which causes the application to
# terminate whenever a window is destroyed. This is a pain because it
# causes the polreg A-task to die in an uncontrolled manner! Do away with it.
   bind . <Destroy> ""

# Load the required ADAM monoliths. IRCAMPACK is only needed for SEGMENT.
# When KAPPA:SEGMENT is available under Linux, then IRCAMPACK can be
# removed.
   if { $OS == "Linux" } {
      LoadTask ircampack $IRCAMPACK_DIR/ircampack_mon
   }
   LoadTask kapview  $KAPPA_DIR/kapview_mon
   LoadTask kappa    $KAPPA_DIR/kappa_mon
   LoadTask ndfpack  $KAPPA_DIR/ndfpack_mon
   LoadTask ccdpack  $CCDPACK_DIR/ccdpack_reg
   LoadTask polpack  $POLPACK_DIR/polpack_mon

# Obtain the input and output images specified on the command line.
# Input images are given in the first command line argument, the O-ray
# output images are given next, and finally the E-ray output images are
# given. Each of these 3 command line arguments should be a list, and they
# should all have the same number of elements. The exception to this is
# that if the third (E-ray) list is empty or not supplied, then we assume
# single beam mode (DBEAM==0). The polreg A-task will pass these lists in
# variables in_list, o_list and e_list, so check first if this has been
# done. If not, get the lists from the command line.
   if { ![info exists in_list] } {
      if { $argc == 0 } {
         puts "PolReg: No input images supplied on command line. Aborting..."
         exit 1
      } {
         set in_list [lindex "$argv" 0]

         if { $argc == 1 } {
            puts "PolReg: No output images supplied on command line. Aborting..."
            exit 1
         } {
            set o_list [lindex "$argv" 1]

            if { $argc > 2 } {
               set e_list [lindex "$argv" 2]
           }
         }
      }
   }

   set IMSECS $in_list
   set nin [llength $IMSECS]
   set nout(O) [llength $o_list]
   if { [info exists e_list] } {
      set nout(E) [llength $e_list]
      set DBEAM 1
      set DBEAM_STATE normal
      set DBEAM_TEXT "Dual-beam"
   } {
      set DBEAM 0
      set DBEAM_STATE disabled
      set DBEAM_TEXT "Single-beam"
   }

# Abort if the number of output images does not equal the number of input
# images.
   if { $nin != $nout(O) || $DBEAM && $nin != $nout(E) } {
      puts "PolReg: No of input and output images are different."
      exit 1
   }

# Now get the optional list of input sky images. If any sky frames have
# been supplied, the a-task will pass them in variable sky_list. If this
# variable does not exist then assuem that sky background are to be
# defined within the object frames.
   if { ![info exists sky_list] } {
      set SKY_METHOD $SKY_AREA

   } {
      set SKY_METHOD $SKY_FRAME
      set nsky [llength $sky_list]
      if { $nin != $nsky } {
         puts "PolReg: Number of sky frames ($nsky) does not equal the number of input frames ($nin)."
         exit 1
      }
   }

# >>>>>>>>>>>>>>>>>  SET UP THE SCREEN LAYOUT <<<<<<<<<<<<<<<<<<<<

# Ensure that closing the window from the window manager is like pressing
# the Quit button in the File menu.
   wm protocol . WM_DELETE_WINDOW {Finish 0}

# Set the default colour for all backgrounds.
   . configure -background $BACKCOL
   option add *background $BACKCOL

# Set the default font.
   if { $FONT != "" } { option add *font $FONT }

# Set the default font for radiobuttons and checkbuttons.
   if { $RB_FONT != "" } { 
      option add *Radiobutton.font $RB_FONT 
      option add *Checkbutton.font $RB_FONT 
   }

# Set the default font for buttons and menus.
   if { $B_FONT != "" } { 
      option add *Button.font $B_FONT 
      option add *Menubutton.font $B_FONT 
      option add *Menu.font $B_FONT 
   }

# Menus do not have "tear-off" marks.
   option add *Menu.tearOff 0

# Radiobuttons and Checkbuttons do not have a highlighted border.
   option add *Radiobutton.highlightThickness 0 
   option add *Checkbutton.highlightThickness 0 

# Ensure that listbox entries are white on black when selected.
   option add *Listbox.selectForeground white
   option add *Listbox.selectBackground black

# Create binding which result in the Helper procedure being called
# whenever a widget is entered, left, or destroyed. Helper stores
# the appropriate message for display in the dynamic help area.
   bind all <Enter> "+Helper %X %Y"
   bind all <Leave> "+Helper %X %Y"
   bind all <Destroy> "+Helper %X %Y"

# When the F1 button is pressed, display help on the object under the
# pointer.
   bind all <F1> {ShowHelp [FindHelp %X %Y]}

# When the focus enters the main PolReg window, hand the focus to the window
# which has claimed it by setting the global variable F_OWNER. 
   bind . <FocusIn> "focus -force \$F_OWNER"

# Set up a binding so that the focus window is automatically raised above the
# main PolReg window each time the main window becomes visible.
   bind . <Visibility> "+if { \"%s\" == \"VisibilityUnobscured\" ||
                              \"%s\" == \"VisibilityPartiallyObscured\" &&
                              \$OLDVIS == \"VisibilityObscured\" } {
                            set OLDVIS %s
                            if { \[winfo exists \$F_OWNER\] } {
                               if { \[winfo toplevel \$F_OWNER\] != \".\" &&
                                    \[focus\] != \$F_OWNER } {
                                  raise \$F_OWNER .
                                  focus -force \$F_OWNER
                               }
                            } { 
                               set F_OWNER .
                            }
                         }"


# Create an all encompassing frame. Give it a new colour map if requested.
   if { [info exists NEWCOLMAP] } {
      set usingnewcmap 1
      set TOP [frame .top -relief raised -bd 2 -colormap new]
      wm colormapwindows . "$TOP ."
   } {
      set usingnewcmap 0
      set TOP [frame .top -relief raised -bd 2]
   }
   pack $TOP -padx 2m -pady 2m 

# Create a frame which goes at the top of the screen but contains nothing. 
# X events will be directed to this window during any pauses
# (see procedure WaitFor). The window has no user controls and so is
# "safe" (i.e. it will just ignore any button presses, mouse movements, etc). 
# This ensures that new commands cannot be initiated by the user before 
# previous ones have finished.
   set SAFE [frame $TOP.dummy ]
   pack $SAFE

# Divide the top window into four horizontal frames. The top one is the
# menu bar. The next contains the GWM canvas and controls. The next displays
# status information. The bottom one displays dynamic help on the object
# under the cursor. The bottom two frames may or may not be displayed,
# depending on the options slected by the user. The display of the two
# bottom frames is controlled by procedures HelpArea and StatusArea.
   set F1 [frame $TOP.menubar -relief raised -bd 2 -background $MENUBACK ]
   set F2 [frame $TOP.main ]
   pack $F1 $F2 -fill x -expand 1

# Build the menu bar and menus.
   set file [menubutton $F1.file -text File -menu $F1.file.menu -background $MENUBACK ]
   set filemenu [menu $file.menu]
   SetHelp $file ".  Menu of commands for exiting, saving, loading, etc..." POLREG_FILE_MENU
   lappend LABEL_OFF $file

   set edit [menubutton $F1.edit -text Edit -menu $F1.edit.menu -background $MENUBACK ]
   set editmenu [menu $edit.menu]
   SetHelp $edit ".  Menu of commands for editing mappings, etc." POLREG_EDIT_MENU
   lappend LABEL_OFF $edit

   set opts [menubutton $F1.opts -text Options -menu $F1.opts.menu -background $MENUBACK]
   set OPTSMENU [menu $opts.menu]
   SetHelp $opts ".  Menu of commands to set up various options..." POLREG_OPTIONS_MENU
   lappend LABEL_OFF $opts

   set images [menubutton $F1.images -text Images -menu $F1.images.menu -background $MENUBACK]
   set imagesmenu [menu $images.menu]
   SetHelp $images ".  Menu of images available for display..." POLREG_IMAGES_MENU
   lappend LABEL_OFF $images

   set effects [menubutton $F1.effects -text Effects -menu $F1.effects.menu -background $MENUBACK]
   set EFFECTSMENU [menu $effects.menu]
   SetHelp $effects ".  Menu of effects to apply when displaying images." POLREG_EFFECTS_MENU
   lappend LABEL_OFF $effects

   set help [menubutton $F1.help -text Help -menu $F1.help.menu -background $MENUBACK ]
   set helpmenu [menu $help.menu]
   SetHelp $help ".  Display further help information..." POLREG_HELP_MENU

# If the preferred fonts could not be found, find which font was used
# in the above menubuttons and use that font for everything else.
   if { $FONT == "" } {
      set FONT [$file cget -font]
      set HLP_FONT $FONT
      set RB_FONT $FONT
      set S_BFONT $FONT
      set S_FONT $FONT
      set B_FONT $FONT
   }

# Add menu items to the Help menu.
   $helpmenu add command -label "Contents" -command {ShowHelp "POLREG_CONTENTS"}
   $helpmenu add command -label "Controls" -command {ShowHelp "POLREG_CONTROLS"}
   $helpmenu add command -label "How do I..." -command {ShowHelp "POLREG_HOW_DO_I"}
   $helpmenu add command -label "Tutorial" -command {ShowHelp "POLREG_TUTORIAL"}
   $helpmenu add command -label "Using Help" -command {ShowHelp "POLREG_USING_HELP"}

   $helpmenu add separator
   $helpmenu add command -label "Pointer..." -command {ShowHelp "pointer"}

   MenuHelp $helpmenu "Contents" ".  Display the main table of contents for the PolReg documentation."
   MenuHelp $helpmenu "Menus" ".  Display help on the buttons in the menu-bar."
   MenuHelp $helpmenu "Usage Guide Lines" ".  Display a simple step-by-step guide to the use of PolReg."
   MenuHelp $helpmenu "Using Help" ".  Display help on how to use the PolReg help system."
   MenuHelp $helpmenu "Pointer..." ".  Select this menu item, and then click with the pointer over a widget to see help on the widget."

# Add menu items to the File menu.
   $filemenu add command -label "Save        " -command Save
   $filemenu add command -label "Exit        " -command {Finish 1}
   $filemenu add command -label "Quit        " -command {Finish 0} -accelerator "Ctrl+C"

   MenuHelp $filemenu "Save        " ".  Extract the mask areas from the input images, register them, and save them in the output images."
   MenuHelp $filemenu "Exit        " ".  Store the current image registration information and exit the application."
   MenuHelp $filemenu "Quit        " ".  Quit the application, thowing away the current image registration information."

# Add menu items to the Effects menu.
   foreach effect [list Align Fill Filter Log Maths Negate Smooth Threshold] {
      $EFFECTSMENU add command -label $effect -command "Effects \$IMAGE_DISP $effect 0"
   }
   $EFFECTSMENU add separator
   $EFFECTSMENU add command -label "Show Effects" -command {Effects Show}
   $EFFECTSMENU add command -label "Undo" -command {Effects Undo} -state disabled
   $EFFECTSMENU add command -label "Undo All" -command {Effects "Undo All"} -state disabled
   
   MenuHelp $EFFECTSMENU "Align"     ".  Align the displayed image with another specified image using the current mappings (if available)."
   MenuHelp $EFFECTSMENU "Fill"      ".  Replace any missing pixels with a constant value or smoothly varying surface."
   MenuHelp $EFFECTSMENU "Filter"    ".  Apply a Gaussian high-pass filter to the currently displayed image. The size of the filter is specified by the \"Feature Size\" option in the \"Options\" menu."
   MenuHelp $EFFECTSMENU "Log"       ".  Take the logarithm (base 10) of the currently displayed image (the minimum value in the image is first subtracted from the image to remove negative values)."
   MenuHelp $EFFECTSMENU "Maths"     ".  Apply an arbitrary algebraic expression to one or more of the previously displayed images."
   MenuHelp $EFFECTSMENU "Negate"    ".  Multiply the currently displayed image by -1.0."
   MenuHelp $EFFECTSMENU "Smooth"    ".  Apply Gaussian smoothing to the displayed image."
   MenuHelp $EFFECTSMENU "Threshold" ".  Remove values outside a given range from the displayed image."
   MenuHelp $EFFECTSMENU "Undo"      ".  Undo the most recent effect for the currently diplayed image."
   MenuHelp $EFFECTSMENU "Undo All"  ".  Undo all effects for the currently diplayed image."
   MenuHelp $EFFECTSMENU "Show Effects" ".  Show the effects which have been used on the currently displayed image."

# Add menu items to the Edit menu.
   $editmenu add command -label "Clear All    " -command {Clear "" ""}
   $editmenu add command -label "Clear Current" -command {Clear $IMAGE_DISP $CUROBJ_DISP}
   $editmenu add command -label "Clear Image  " -command {Clear $IMAGE_DISP ""}
   $editmenu add command -label "Delete       " -command Delete
   $editmenu add cascade -label "Mappings     " -menu $editmenu.mappings

   MenuHelp $editmenu "Clear All    "   ".  Clear all mappings, image features and masks for all images."
   MenuHelp $editmenu "Clear Current"   ".  Clear the current objects (as selected using the buttons under the \"Current:\" label) for the displayed image."
   MenuHelp $editmenu "Clear Image  "   ".  Clear the mappings, image features and masks for the displayed image."
   MenuHelp $editmenu "Delete       "   ".  Delete any image features within the selected area.   (Click and drag over the image to select an area)."
   MenuHelp $editmenu "Mappings     "   ".  Edit the mappings between images, and between the E and O rays."

# Create the Mappings sub-menu.
   set edmapmenu [menu $editmenu.mappings]

# Add menu items to options menu.
   $OPTSMENU add cascade -label "Colours" -menu $OPTSMENU.cols
   $OPTSMENU add cascade -label "Feature Size" -menu $OPTSMENU.psf
   $OPTSMENU add cascade -label "Interpolation method" -menu $OPTSMENU.meth
   $OPTSMENU add cascade -label "Mapping Types" -menu $OPTSMENU.map
   $OPTSMENU add command -label "Status Items..." -command GetItems
   $OPTSMENU add cascade -label "View" -menu $OPTSMENU.view
   $OPTSMENU add separator
   $OPTSMENU add checkbutton -label "Use Cross-hair" -variable XHAIR -selectcolor $CB_COL
   $OPTSMENU add checkbutton -label "Display Help Area" -variable HAREA -command HelpArea -selectcolor $CB_COL
   $OPTSMENU add checkbutton -label "Display Status Area" -variable SAREA -command "StatusArea \$SAREA" -selectcolor $CB_COL
   $OPTSMENU add separator
   $OPTSMENU add command -label "Save Options" -command SaveOptions 

   MenuHelp $OPTSMENU "Colours"         ".  Change the colours used for various parts of the display."
   MenuHelp $OPTSMENU "Feature Size"    ".  The typical size of star-like features in the image (in pixels). This is used by the algorithm which locates accurate feature positions. A value of zero results in the raw position being used."
   MenuHelp $OPTSMENU "Interpolation method" ".  The interpolation method to use when finding pixel values in the input images."
   MenuHelp $OPTSMENU "Mapping Types"   ".  The type of mapping to use when aligning images, or when aligning the O and E rays."
   MenuHelp $OPTSMENU "Status Items..."      ".  Select which items of information to display in the status area."
   MenuHelp $OPTSMENU "View"            ".  The section to be displayed when a new image is selected from the \"Images\" menu."
   MenuHelp $OPTSMENU "Display Status Area"  ".  Toggle the display of status information underneath the displayed image."
   MenuHelp $OPTSMENU "Display Help Area"    ".  Toggle the display of help information at the bottom of the main window."
   MenuHelp $OPTSMENU "Use Cross-hair"  ".  Should a cross-hair be used instead of a pointer over the image display area?"
   MenuHelp $OPTSMENU "Save Options"    ".  Save the current option values."

# Add items to the Colours sub-menu.
   set colsmenu [menu $OPTSMENU.cols]
   ColMenu $colsmenu "Cross-hair"        XHRCOL
   ColMenu $colsmenu "Current Objects"   CURCOL
   ColMenu $colsmenu "Missing Pixels"    BADCOL
   ColMenu $colsmenu "Reference Objects" REFCOL
   ColMenu $colsmenu "Selection Box"     SELCOL

# Add items to the View sub-menu.
   set viewmenu [menu $OPTSMENU.view]
   $viewmenu add radiobutton -label Unzoomed -variable VIEW \
                             -value Unzoomed -selectcolor $RB_COL 
   $viewmenu add radiobutton -label Zoomed -variable VIEW \
                             -value Zoomed -selectcolor $RB_COL 

   MenuHelp $viewmenu "Unzoomed"   ".  Display the whole image."
   MenuHelp $viewmenu "Zoomed"     ".  Retain the displayed section, but do not align the new image with the previous image."


# Add items to the Interpolation Method sub-menu.
   set methmenu [menu $OPTSMENU.meth]
   $methmenu add radiobutton -label Linear -variable INTERP \
                             -value Linear -selectcolor $RB_COL 
   $methmenu add radiobutton -label "Nearest neighbour" -variable INTERP \
                             -value "Nearest neighbour" -selectcolor $RB_COL 
   SetHelp $methmenu ".  The interpolation method to use when sampling the input images."

# Add items to the "Feature size" sub-menu.
   set psfmenu [menu $OPTSMENU.psf]
   $psfmenu add radiobutton -label "Zero" -variable PSF_SIZE -selectcolor $RB_COL -value 0 

   foreach s "3 5 9 13 19 29 39 49" {
      $psfmenu add radiobutton -label "$s pixels" -variable PSF_SIZE \
              -selectcolor $RB_COL -value $s 
   }

   SetHelp $psfmenu ".  The typical size of star-like features in the image (in pixels). This is used by the algorithm which locates accurate feature positions. A value of zero results in the raw position being used."

# Add items to the "Mapping Types" sub-menu.
   set mapmenu [menu $OPTSMENU.map]
   for {set type 1} {$type < 6} {incr type} {
      $mapmenu add radiobutton -label $MAPTYPE($type) -variable FITTYPE \
                               -selectcolor $RB_COL -value $MAPTYPE($type)
      MenuHelp $mapmenu $MAPTYPE($type) ".  Align images using \"$MAPTYPE($type)\"."
   }
   $mapmenu add separator
   $mapmenu add cascade -label "O-E Mapping Type" -menu $mapmenu.oe -state $DBEAM_STATE
   MenuHelp $mapmenu "O-E Mapping Type" ".  Select the mapping to use when aligning the O and E rays."

   SetHelp $mapmenu ".  The type of mapping to use in future when aligning images. "

# Add items to the "OE Mapping Type" sub-menu.
   set oemapmenu [menu $mapmenu.oe]
   for {set type 1} {$type < 6} {incr type} {
      $oemapmenu add radiobutton -label $MAPTYPE($type) -variable OEFITTYPE \
                                 -selectcolor $RB_COL -value $MAPTYPE($type)
   }

   SetHelp $oemapmenu ".  The type of mapping to use when aligning the O and E rays. "


# Save the current value of environment variable NDF_FORMATS_OUT (if any),
# and ensure that NDF applications will create output NDFs, rather than
# any other data format.
   if { [info exists env(NDF_FORMATS_OUT)] } {
      set ndf_formats_out $env(NDF_FORMATS_OUT)
   }
   set env(NDF_FORMATS_OUT) "."

# Go through every supplied image section.
   set maximwid 0
   set maxrimwid 0
   set i 0
   foreach imsec $IMSECS {

# Extract the image name (i.e. remove any section specifier), and append
# it to a list of image names.
      GetSec $imsec image section
      lappend IMAGES $image

# Ensure we have a standard NDF section expressed as ranges of pixel indices.
      set stdsec $image
      append stdsec [PixIndSection $imsec]

# Save the standard section for the first image.
      if { ![info exists IMSEC_FIRST] } { set IMSEC_FIRST $stdsec }

# Arrange for the first image in the supplied list to be displayed first.
      if { ![info exists IMSEC_REQ] } { set IMSEC_REQ $stdsec }

# Add it to the Images menu.
      $imagesmenu add radiobutton -label $imsec -variable IMSEC_REQ \
                                  -value $stdsec  -command UpdateDisplay \
                                  -selectcolor $RB_COL 

# Store the names of the O and E ray output image for this input image.
      set OUTIMS($image,O) [lindex $o_list $i]
      if { $DBEAM } { set OUTIMS($image,E) [lindex $e_list $i] }

# Store the names of the SKY frame (if any) to use with this input image.
      if { [info exists sky_list] } {
         set SKYIMS($image) [lindex $sky_list $i]
      }

# Update the length of the longest image section and image name.
      set imwid [string length $imsec]
      if { $imwid > $maximwid } { set maximwid $imwid }

      set rimwid [string length $image]
      if { $rimwid > $maxrimwid } { set maxrimwid $rimwid }

# Add an entry for this image to the Edit-Mappings menu.
      $edmapmenu add command -label $image -command "EditMapping $image im"
      MenuHelp $edmapmenu $image ".  Edit the mappings associated with image \"$image\"."

# Initialise the global variable containing the name of the file holding 
# a logged version of the image.
      set LOGDATA($image) ""

# Indicate that we have no mapping information for any images.
      set RECALC_IMMAP($image) 1
      set RECALC_OEMAP($image) 1

# Initialise the lists holding information about the positions identified
# in the image.
      foreach object [list $O_RAY_FEATURES $E_RAY_FEATURES $O_RAY_MASK $E_RAY_MASK $O_RAY_SKY $E_RAY_SKY] {
         set PNTPX($image,$object) ""
         set PNTPY($image,$object) ""
         set PNTCX($image,$object) ""
         set PNTCY($image,$object) ""
         set PNTID($image,$object) ""
         set PNTVID($image,$object) ""
         set PNTNXT($image,$object) ""
         set PNTLBL($image,$object) ""
         set PNTNW1($image,$object) 0
         set PNTNW2($image,$object) 0
      }

# Make a copy of the supplied image (ensuring it is in NDF format), and
# push it onto the image's IMAGE_STACK.
      set copy [UniqueFile]
      Obey ndfpack ndfcopy "in=$imsec out=$copy" 1
      set IMAGE_STACK($image) $copy
      set EFFECTS_MAPPINGS($image) ""
      set EFFECTS_STACK($image) ""

      incr i   
   }

# Re-instate the original value of environment variable NDF_FORMATS_OUT 
# (if any).
   if { [info exists ndf_formats_out] } {
      set env(NDF_FORMATS_OUT) $ndf_formats_out
   }

# Pack the menu buttons.
   pack $file $edit $opts $images $effects -side left 
   pack $help -side right

# Now deal with the middle horizontal frame ($F2). It is made up from
# the following items arranged horizontally...
   set col1 [frame $F2.col1 -bd 0]   
   set col2 [frame $F2.col2 -bd 0]
   set col3 [frame $F2.col3 -bd 0]   
   pack $col1 $col2 $col3 -side left -fill y -ipadx 2m -ipady 2m -expand 1

# Create the first column...

# The radiobutton array which selects the current object...

# Create and pack the frame containing everything else.
   set cur [frame $col1.cur -bd 2 -relief groove ]
   pack $cur -fill y -expand 1 -padx 3m -pady 3m 

# Create and pack the label containing the title.
   set clab [label $cur.clab -text "Current:"]
   pack $clab -side top -fill both -expand 1

# Create radiobuttons for each object type in turn, packing them
# alternately into the left and right columns...
   set frm ""
   foreach i "$O_RAY_FEATURES $E_RAY_FEATURES $O_RAY_MASK $E_RAY_MASK $O_RAY_SKY $E_RAY_SKY" {
      if { $frm == "" } {
         set frm [frame $cur.$i]
         pack $frm -side top -fill both -expand 1
         set nxtfrm $frm
      } {
         set nxtfrm ""
      }

# In single-beam mode, the radiobuttons for the E-ray objects are disabled.
      if { $DBEAM } {
         set state normal
      } {
         if { $i == $E_RAY_FEATURES || $i == $E_RAY_SKY || $i == $E_RAY_MASK } {
            set state disabled
         } {
            set state normal
         }
      }

# Create and pack the radiobutton.
      set name $OBJTYPE($i)
      set RB_CUR($i) [radiobutton $frm.$i -text $name -command UpdateDisplay \
                                     -anchor nw -value $i -variable CUROBJ_REQ \
                                     -selectcolor $CURCOL -state $state -width 14]
      pack $RB_CUR($i) -side left -fill both -expand 1 -padx 2m

# These buttons are disabled when getting a feature label from the user.
      if { $state == "normal" } { lappend LABEL_OFF $RB_CUR($i) }

      set frm $nxtfrm
   }

   SetHelp $cur ".  Click to select the current objects being entered using the mouse." POLREG_CURRENT

# The radiobutton array which selects the reference object...
# Create and pack the frame.
   set ref [frame $col1.ref -bd 2 -relief groove ]
   pack $ref -fill y -expand 1 -padx 3m -pady 3m 
   SetHelp $ref ".  Click to select the reference objects to be displayed." POLREG_REFERENCE

# Create and pack the label.
   set rlab [label $ref.rlab -text "Reference:"]
   pack $rlab -side top -expand 1

# Create radiobuttons for each object type in turn, packing them
# alternately into the left and right columns...
   set frm ""
   foreach i "$O_RAY_FEATURES $E_RAY_FEATURES $O_RAY_MASK $E_RAY_MASK $O_RAY_SKY $E_RAY_SKY $NONE" {
      if { $frm == "" } {
         set frm [frame $ref.$i]
         pack $frm -side top -fill both -expand 1
         set nxtfrm $frm
      } {
         set nxtfrm ""
      }

# In single-beam mode, the radiobuttons for the E-ray objects are disabled.
      if { $DBEAM } {
         set state normal
      } {
         if { $i == $E_RAY_SKY || $i == $E_RAY_FEATURES || $i == $E_RAY_MASK } {
            set state disabled
         } {
            set state normal
         }
      }

# Create and pack the radiobutton.
      set name $OBJTYPE($i)
      set RB_REF($i) [radiobutton $frm.$i -text $name -command UpdateDisplay \
                                   -anchor nw -value $i -variable REFOBJ_REQ \
                                   -selectcolor $REFCOL -state $state -width 14]
      pack $RB_REF($i) -side left -fill both -expand 1 -padx 2m

      set frm $nxtfrm
   }

# Next is a frame containing the "Draw Aligned and Ref. Image buttons.
   set bfrm [frame $ref.bfrm]

# Create the "Draw Aligned" checkbutton which causes the reference objects to 
# be drawn in registration with the frame of the current objects. The
# associated command ensures that the mappings for this image are up to date
# and then re-configures the reference objects.
   set REFALIGN [checkbutton $bfrm.align -text "Draw Aligned" \
                 -variable REFALN -selectcolor $REFCOL -font $B_FONT \
                 -command DrawRef]

   SetHelp $REFALIGN ".  Should the reference objects be mapped into the coordinate frame of the current objects before being displayed?" POLREG_DRAW_ALIGNED

# The reference image menu. Use a normal "button" (instead of the more
# obvious "menubutton") to post the menu for cosmetic purposes (so that 
# the button looks the same as the following "Register" button).
   set refmenu [menu $bfrm.menu]
   set refim [button $bfrm.image -text "Ref. Image" -width 10 -relief raised -bd 2 ]
   $refim configure -command "tk_popup $refmenu  \
          \[expr \[winfo rootx $refim\] + \[winfo width $refim\] \] \
          \[winfo rooty $refim\]"

   foreach image $IMAGES {
      $refmenu add radiobutton -label $image -variable REFIM_REQ \
                               -value $image -command UpdateDisplay \
                               -selectcolor $RB_COL 
   }
   set REFIM_REQ [lindex $IMAGES 0]
   SetHelp $refim ".  Select the image from which reference objects will be displayed." POLREG_REF_IMAGE

# Pack the "Draw Aligned", and "Ref. Image" "Accept" buttons.
   pack $REFALIGN $refim -side left -pady 1m -expand 1

# Next is a frame containing the Redraw and Accept buttons.
   set cfrm [frame $ref.cfrm]

# Create the button which re-draws the reference objects.
   set REDRAW [button $cfrm.redraw -text "Re-draw" -width 10 -relief raised -bd 2 -command DrawRef -state disabled]
   SetHelp $REDRAW ".  Click to re-draw the reference objects, taking into account any changes in the mappings since they were last drawn." POLREG_REDRAW

# Create the button which searches for current features at the positions
# of the reference features.
   set ACCEPT [button $cfrm.accept -text "Accept" -width 10 -relief raised -bd 2 -command Accept -state disabled]
   SetHelp $ACCEPT ".  Click to search for image features at the positions of the displayed reference features." POLREG_ACCEPT

# Pack the "Redraw" and "Accept" buttons. 
   pack $REDRAW $ACCEPT -side left -pady 1m -expand 1

# Pack the frame holding the buttons.
   pack [Spacer $ref.sp1 2m 1m] $bfrm $cfrm [Spacer $ref.sp2 2m 1m] \
         -side top -fill both -expand 1

# Create the second column...
   set col2f [frame $col2.f -bd 2 -relief groove]
   pack $col2f -pady 3m -fill y -expand 1 -ipadx 2m -ipady 2m

# Create and pack the label containing the title.
   pack [label $col2f.clab -text "Display Controls:"] -side top -fill x \
                                                       -pady 1m -expand 1

# Create the buttons...
   set ZOOM [button $col2f.zoom -text Zoom -width 6 -command Zoom -state disabled ]
   set UNZOOM [button $col2f.unzoom -text Unzoom -width 6 -command {UnZoom1} -state disabled ]
   set CENTRE [button $col2f.recen -text Centre -width 6 -command {SetMode 4} ]
   set DELETE [button $col2f.delete -text Delete -width 6 -command {Delete} -state disabled ]
   set CANCEL [button $col2f.cancel -text Cancel -width 6 -command {Cancel} -state disabled ]

# Pack the buttons.
   pack $ZOOM $UNZOOM $CENTRE $DELETE $CANCEL -padx 5 -pady 2 -expand 1

# Set up the help to be displayed at the bottom of the screen when the
# pointer is over the buttons.
   SetHelp $ZOOM   ".  Click to zoom the image so that only the selected area is displayed.   (Click and drag over the image to select an area)." POLREG_ZOOM
   SetHelp $UNZOOM ".  Single click to undo the previous Zoom or re-centre operation.\n.  Double click to undo all zoom and re-centre operations." POLREG_UNZOOM
   SetHelp $CENTRE ".  Click this button and then point and click with the mouse to re-display the image centred on the pointer position." POLREG_CENTRE
   SetHelp $DELETE ".  Click to delete any image features within the selected area.   (Click and drag over the image to select an area)." POLREG_DELETE
   SetHelp $CANCEL ".  Click to:\n    - cancel an area selection\n    - abort the construction of a mask polygon\n    - cancel the selection of a new image centre" POLREG_CANCEL

# If the Unzoom buton is double clicked, call procedure UnZoom2.
   bind $UNZOOM <Double-ButtonPress-1> {UnZoom2}

# Ensure the Delete button is deactivated when the user is suppling a
# feature label.
   lappend LABEL_OFF $DELETE

# Create the "widgets" for entering the lower (black) and upper (white) 
# percentile values.
   set BLACK [Value $col2f.black "% black" 6 PLO_REQ 100 0 CheckVal]
   set WHITE [Value $col2f.white "% not white" 6 PHI_REQ 100 0 CheckVal]
   pack $WHITE $BLACK -pady 5 -expand 1

   SetHelp $BLACK ".  Specify the percentage of pixels to be displayed black." POLREG_BLACK
   SetHelp $WHITE ".  Specify the percentage of pixels to be displayed black or grey (i.e. not white)." POLREG_NOT_WHITE

# Create a check button which locks the data scaling of displayed images.
   set LOCK [checkbutton $col2f.lock -text "Lock Scaling" \
                 -variable LOCK_SCALE -selectcolor $CB_COL -font $B_FONT \
                 -command \
                 "if { \$LOCK_SCALE } {
                     ${BLACK}.ent configure -state disabled
                     ${WHITE}.ent configure -state disabled
                     set old_image \$IMAGE_DISP
                     set old_section \$SECTION_DISP
                  } {
                     ${BLACK}.ent configure -state normal
                     ${WHITE}.ent configure -state normal
                     UpdateDisplay gwm
                  }"]

   SetHelp $LOCK ".  Check to use the current data limits to display subsequent images. This causes the percentiles entered in the \"% black\" and \"% not white\" entry boxes to be ignored." POLREG_LOCK_SCALING
   pack $LOCK -pady 5 -expand 1

# Create a label displaying a description of the current canvas
# interaction mode.
   set DESC [label $col3.desc -textvariable INFO_TEXT -relief raised -bd 2 -font $RB_FONT -pady 1m]
   pack $DESC -padx 3m -pady 2m -expand 1 -fill x

# Create the canvas in column 3...
   set CAN [canvas $col3.can1 -height $SIZE -width $SIZE]
   pack $CAN -padx 3m -expand 1

# Create a GWM canvas items which fills the canvas.
   if { [catch {set gwm [$CAN create gwm 0 0 -height $SIZE -width $SIZE -name $GWM_NAME -mincolours $COLOURS -tags gwm]} mess] } {
      if { $usingnewcmap } {
         Message "Failed to create the image display.\n\nIt may be possible to overcome this problem by closing down some other X applications, and then re-running polreg."
      } {
         Message "Failed to create the image display.\n\nIt may be possible to overcome this problem by re-running polreg giving a true value for the NEWCOLMAP parameter."
      }
      exit
   }

# Reset the pointer coordinates string to null when the pointer leaves
# the canvas, and ensure any cross hair is lowered below the GWM canvas
# item so that it cannot be seen. Raise it back again when the pointer
# enters the canvas.
   bind $CAN <Leave> "+
      set POINTER_PXY \"\"
      set POINTER_CXY \"\"
      if { \$XHAIR_IDH != \"\" } {
         $CAN lower \$XHAIR_IDH $gwm
         $CAN lower \$XHAIR_IDV $gwm
      }"

   bind $CAN <Enter> "+
      if { \$XHAIR_IDH != \"\" } {
         set cx \[$CAN canvasx %x\]
         set cy \[$CAN canvasy %y\]
         $CAN coords \$XHAIR_IDH 0 \$cy $SIZE \$cy
         $CAN coords \$XHAIR_IDV \$cx 0 \$cx $SIZE
         $CAN raise \$XHAIR_IDH $gwm
         $CAN raise \$XHAIR_IDV $gwm
      }"

# Execute procedure SingleBind when button 1 is clicked over the canvas.
   $CAN bind current <ButtonPress-1> "SingleBind %x %y"

# Execute procedure ReleaseBind when button 1 is released over the canvas.
   $CAN bind current <ButtonRelease-1> "ReleaseBind %x %y"

# Execute procedure B1MotionBind when the pointer is moved over the canvas 
# with button 1 pressed.
   $CAN bind current <B1-Motion> "B1MotionBind %x %y"

# Execute procedure MotionBind when the pointer is moved over the canvas 
# with no buttons pressed.
   $CAN bind current <Motion> "MotionBind %x %y"

# Identify all the status items which can be displayed in the status area.
   StatusItem DBEAM_TEXT   "Mode: "                  "The mode (single-beam or dual-beam) in which PolReg is running. In single-beam mode all the controls related to E-ray objects or O-E mappings are disabled." 11
   StatusItem IMAGE_DISP   "Displayed image: "       "The name of the displayed image.\n(To change the displayed image, use the \"Images\" menu.)" $maximwid
   StatusItem SCALOW       "Black data value: "      "The data value corresponding to black in the displayed image.\n(To change the black and white values, use the \"\% black\" and \"\% not white\" widget.)" 11
   StatusItem SECTION_DISP "Displayed bounds: "      "The bounds of the displayed image.\n(To change the bounds of the displayed image, use the Zoom, Unzoom and Centre buttons.)" 25
   StatusItem SCAHIGH      "White data value: "      "The data value corresponding to white in the displayed image.\n(To change the black and white values, use the \"\% black\" and \"\% not white\" widget.)" 11
   StatusItem REFIM_DISP   "Reference image: "       "Objects from this image can be shown for reference purposes over the displayed image.\n(To change the reference image, use the \"Ref. Image\" button.\n(To select the type of reference object to display, use the \"Reference:\" radio buttons.)" $maxrimwid
   StatusItem ACTION       "Current action: "        "The name of any Starlink program currently being executed." 20
   StatusItem LABEL        "Feature label: "         "The label of any image feature currently under the pointer." 5
   StatusItem PSF_SIZE     "Feature size (pixels): " "The typical size of a star-like feature in the displayed image (in pixels). This is used by the centroiding algorithm which finds accurate feature positions.\n(To change the value use the \"Options\" menu.)" 5
   StatusItem PXY          "Feature coordinates: "   "The pixel coordinates of any image feature currently under the pointer." 20
   StatusItem POINTER_PXY  "Pointer coordinates: "   "The pixel coordinates of the pointer (only displayed while the pointer is over the image)." 20
   StatusItem FITTYPE      "Image mappings: "        "The type of mapping being used to align images.\n(To change the mapping type, use the \"Options\" menu.)" 34
   StatusItem VIEW         "Image view: "            "What section of the image will be displayed when a new image is selected using the \"Images\" menu?\n(To change the value use the \"Options\" menu.)" 9
   StatusItem OEFITTYPE    "O-E mappings: "          "The type of mapping being used to align the O and E rays.\n(To change the mapping type, use the \"Options\" menu.)" 34
   StatusItem INTERP       "Interpolation method: "  "The interpolation method to use when sampling the input images.\n(To change the method, use the \"Options\" menu.)" 20

# Load the options supplied by the polreg atask.
   LoadOptions

# Destroy the "please wait" label, displayed while the main interface is
# being created.
   destroy $wait

# Create the status area if required.
   StatusArea $SAREA

# Create the help area if required.
   HelpArea

# Create a binding which calls MenuMotionBind whenever the pointer moves
# over any menu. This is used to determine the help information to display.
   bind Menu <Motion> {+MenuMotionBind %W %y}

# >>>>>>>>>>>>>>>>>  SET UP THE IMAGE DISPLAY <<<<<<<<<<<<<<<<<<<<<

# Establish the graphics and image display devices.
   Obey kapview lutable "mapping=linear coltab=grey device=$DEVICE" 1
   Obey kapview paldef "device=$DEVICE" 1
   Obey kapview palentry "device=$DEVICE palnum=0 colour=$BADCOL" 1

# Clear the display.
   ClearGwm
  
# Display the first image.
   SetMode 0
   UpdateDisplay

   update idletasks
   wm  title . PolReg
