#!/usr/local/bin/perl -w

package Scb;

#+
#  Name:
#     Scb.pm

#  Purpose:
#     Module containing utility routines for source code browser programs.

#  Language:
#     Perl 5

#  Invocation:
#     use Scb;

#  Description:
#     Utility routines and global variables for source code browser
#     and indexer programs.

#  Notes:
#     This module reports errors using the routine &main::error 
#     (this is to make sensible handling of exceptions easier).
#     Thus such a routine "error", must have been declared in the 
#     main program.  If no special exception handling is required,
#     this can be done with a definition like:
#
#        sub error { die @_ }

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Set up export of names into main:: namespace.

require Exporter;
@ISA = qw/Exporter/;

#  Names of routines and variables defined here to be exported.

@EXPORT = qw/tarxf popd pushd starpack rmrf parsetag
             $incdir $srcdir $bindir 
             $mimetypes_file
             $htxserver
             $func_indexfile $file_indexfile $taskfile
             %tagger/;

#  Map error handler routine to that from the main:: namespace.

sub error { &main::error (@_) }

#  Includes.

use Cwd;

########################################################################
#  Global variables.
########################################################################

#  Directory locations.

# $srcdir = "/local/star/src/from-ussc";  # head of source tree
$srcdir = "/local/star/sources";        # head of source tree
$bindir = "/star/bin";                  # Starlink binaries directory
$incdir = "/star/include";              # Starlink include directory

#  System file locations.

$mimetypes_file = "/etc/mime.types";

#  HTX server base URL

$htxserver = "http://star-www.rl.ac.uk/cgi-bin/htxserver";

#  Index file locations.

$func_indexfile = cwd . "/func";
$file_indexfile = cwd . "/file";
$taskfile  = cwd . "/tasks";

#  Language-specific tagging routines.

use CTag;
use FortranTag;

%tagger = ( 
            c   => \&CTag::tag,
            h   => \&CTag::tag,

            f   => \&FortranTag::tag,
            gen => \&FortranTag::tag,
          );


########################################################################
#  Local variables.
########################################################################

#  Define necessary shell commands.
#  Note: this is used in a CGI program, so you should be sure that these 
#  commands do what they ought to, for security reasons.
#  In the case that this is being used from a CGI program, the path 
#  $ENV{'PATH'} should have been stripped down to a minimum 
#  ('/bin:/usr/bin' is probably sufficient).

   $tar = "tar";
   $cat = "cat";
   $zcat = "uncompress -c";
   $gzcat = "gzip -dc";


########################################################################
#  Subroutines.
########################################################################


########################################################################
sub tarxf {

#+
#  Name:
#     tarxf

#  Purpose:
#     Extract files from a tar archive.

#  Language:
#     Perl 5

#  Invocation:
#     @fextracted = tarxf $tarfile;
#     @fextracted = tarxf $tarfile @files;

#  Description:
#     Extracts either all files, or a list of named files, from the 
#     named tar archive into their archived positions relative to the
#     current directory, just as tar(1).  The tar archive may however
#     be compressed using gzip(1) or compress(1).

#  Arguments:
#     $tarfile = string.
#        Name of the tar archive.  If it ends '.Z' or '.gz' it is 
#        supposed to be compressed using compress(1) or gzip(1) 
#        respectively.
#     @files = list of strings (optional).
#        If present, @files contains a list of filenames to be extracted
#        from the tar archive.  An error results if any cannot be extracted.
#        If absent, all files will be extracted.

#  Return value:
#     @fextracted = list of strings.
#        List of files successfully extracted.

#  Notes:

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameters.

   my ($tarfile, @files) = @_;

#  Define a (possibly null) compression filter.

   $tarfile =~ /\.tar(\.?.*)$/;
   my $ext = $1;
   my %filter = (
                  ''    => $cat,
                  '.Z'  => $zcat,
                  '.gz' => $gzcat,
                );

#  Unpack the tar file, reading the list of file names into a list.

   my $command = "$filter{$ext} $tarfile | $tar xvf - " . join ' ', @files;
   my @extracted;
   open TAR, "$command|" or error "$command failed\n";
   while (<TAR>) {
      chomp;
      push @extracted, $_;
   }
   close TAR             or error "Error executing tar\n";

#  Check we got as many files as were requested (unless none were requested).

   error "Failed to extract all requested files\n"
      if (@files && @files != @extracted);

#  Eliminate any directories from the list.

   my ($file, @fextracted);
   while ($file = shift @extracted) {
      push @fextracted, $file unless (-d $file);
   }

#  Return list.

   return @fextracted;
}


########################################################################
sub starpack {

#+
#  Name:
#     starpack

#  Purpose:
#     Identify the Starlink package name from a logical path.

#  Language:
#     Perl 5

#  Invocation:
#     $package = starpack ($location);

#  Description:
#     Returns the name of the Starlink package into which a logical
#     pathname points.  This is the part before the first '#' sign,
#     so that e.g.:
#
#        starpack ("ndf#ndf_source.tar>ndf_open.f")  eq  'ndf'

#  Arguments:
#     $location = string.
#        Logical pathname of file.

#  Return value:
#     $package = string.
#        Name of the package.  If no package is identified, the empty
#        string (not undef) is returned.

#  Notes:

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $location = shift;

#  Pattern match to find package identifier.

   $location =~ /^(\w+)#/;

#  Return value.

   return $1 || '';
}

########################################################################
sub rmrf {

#+
#  Name:
#     rmrf

#  Purpose:
#     Remove a directory.

#  Language:
#     Perl 5

#  Invocation:
#     rmrf ($dir);

#  Description:
#     This routine deletes a single directory and all its subdirectories.
#     It examines its arguments rather carefully to try to avoid any 
#     unintentional deletions.
#     This is entirely a precautionary measure - it is never expected 
#     that this function will be called with dangerous arguments, but
#     (especially since it may run under CGI control) it seems prudent
#     to be as safe as possible.
#     If anything looks untoward, an error is generated and the user
#     directed to this routine.  Amongst other things, the target
#     directory is checked to see whether it looks like the name of
#     something which has temporary files in it; according to naming
#     conventions this might innocently fail to be the case.  In that
#     case that check can be modified or removed.

#  Arguments:
#     $dir = string.
#        Single word giving the relative or absolute pathname of a 
#        directory.

#  Return value:

#  Notes:
#     If an exception is generated, it is handled using die() rather
#     than error(), since this routine may be called by error, and
#     we don't want to get into an infinite loop.

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $dir = shift;

#  Assemble command (by presenting a list, rather than a string, to
#  system() we guarantee that no shell processing will be done on 
#  the arguments).

   my @cmd = ("/bin/rm", "-rf", "$dir");
   my $cmd = join '', @cmd;

#  Form a very cautious opinion of whether it is safe to proceed.

   my $ok = 1
         && ($dir =~ /te*mp|junk|scratch/i)
         && ($dir !~ /[&|<> ;]/)
         && ($dir !~ /\.\./)
   ;

#  Execute the command or exit with error message.

   if ($ok) {
      system (@cmd) and die "Error in $cmd: $?\n";
   }
   else {
      die "Internal: command $cmd may be dangerous - see Scb::rmrf\n";
   }
}


########################################################################
sub pushd {

#+
#  Name:
#     pushd

#  Purpose:
#     Change directory and push old one to stack.

#  Language:
#     Perl 5

#  Invocation:
#     pushd ($dir);

#  Description:
#     This function does the same as its C shell namesake, changing
#     directory to the value given by its argument and pushing the 
#     current directory onto a stack whence it can be recalled by 
#     a subsequent popd.

#  Arguments:
#     $dir = string.
#        Directory to change to.

#  Return value:

#  Notes:

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $dir = shift;

#  Save current directory.

   push @dirstack, cwd;

#  Change to new directory.

   chdir $dir or error "Failed to change directory to $dir\n";
}

########################################################################
sub popd {

#+
#  Name:
#     popd

#  Purpose:
#     Change to previous directory on stack.

#  Language:
#     Perl 5

#  Invocation:
#     popd;

#  Description:
#     This function does the same as its C shell namesake, popping a
#     directory from the stack and changing to it.

#  Arguments:

#  Return value:

#  Notes:

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get directory name from stack.

   my $dir = pop @dirstack or error "Directory stack is empty\n";

#  Change to directory.

   chdir $dir or error "Failed to change directory to $dir\n";
}


########################################################################
sub parsetag {  

#+
#  Name:
#     parsetag

#  Purpose:
#     Parse an SGML-like tag.

#  Language:
#     Perl 5

#  Invocation:
#     %tag = parsetag ($tag);

#  Description:
#     Examines an SGML-like tag and returns a hash containing the name
#     and attributes.  A start tag will look like
#
#        <tagname att1='val1' att2=val2 att3>  (start tag)
#
#     and will yield a tag hash:
#
#        Start => 'tagname'
#        End   => ''
#        att1  => 'val1'
#        att2  => 'val2'
#        att3  => undef
#
#     and an end tag will look like
#
#        </tagname>
#
#     and will yield a tag hash:
#
#        Start => ''
#        End   => 'tagname'
#
#     Thus one of the hash keys 'Start' and 'End' will have an empty 
#     string value, and the other will have a non-empty string value.
#     End tags can have attributes too but usually don't.  Parsing is
#     as per usual in SGML/HTML, in particular:
#     
#        - Attribute names are case insensitive (always returned lower case)
#        - Attribute value may be ''- or ""-delimited, or be a single
#             alphanumeric word without delimiters, or be nonexistent

#  Arguments:
#     $tag = string.

#  Return value:
#     %tag = hash of strings.
#        Parsed content of tag.  See above.

#  Notes:

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get parameter.

   my $tag = shift;

#  Initialise 'Start' and 'End' pseudo-attributes.

   my %tag = (Start => '', End => '');
  
#  Identify tag name, and whether it is starting or ending.

   $tag =~ m%<(/?)\s*(\w+)\s*%g
      or error "Internal: '$tag' doesn't look like a tag.\n";
   $tag{ $1 ? 'End' : 'Start' } = lc $2;

#  Work through tag, writing attribute-value pairs to %tag hash.

   while ($tag =~ m%(\w+)\s*(?:=\s*(?:(["'])(.*?)\2|(\w*)))?%g) {
      $tag{lc $1} = $3 || $4;
   }

#  Return tag hash.

   return %tag;
}



1;
