/*+
 *  Name:
 *     MESSGEN

 *  Purpose:
 *     Translate a VMS style error definition file into one or more of:
 *       1) An f77 include file
 *       2) A C header file
 *       3) An error definition file used in backtranslating error codes

 *  Language:
 *     Starlink ANSI C

 *  Invocation:
 *     messgen -[cefFvV] <files>

 *  Description:
 *     This program will process any number of error definition files in
 *     VMS MESSAGE format and will optionally output C and FORTRAN header
 *     files and a special "error definition" file used by EMS and other
 *     utilities to translate error codes to text on Unix systems.
 *     If a the current directory contains a file of the same name
 *     as the new output file but with an "_ext" suffix, the contents
 *     of that file are written to the output file after writing the
 *     error codes.

 *  Parameters:
 *     Options: One or more of:
 *              -c - generate C header file    (<facility name>_err.h)
 *              -f - generate f77 include file (<facility name>_err)
 *              -F - as -f, but with uppercase output (<facility name>_ERR)
 *              -e - generate error definition file
 *                                             (fac_<facility number>_err)
 *              -v - Output diagnostic informations about messgen run
 *              -V - Write names of all generated files to stdout
 *
 *     <files> - any number of message source file in VMS MESSAGE format
 *        The error number as generated by the MESSGEN utility (VMS status
 *        code format).

 *  Authors:
 *     BKM: B.K. McIlwrath (STARLINK)
 *     AJC: A.J. Chipperfield (STARLINK)
 *     NG: Norman Gray (Starlink)
 *     TIMJ: Tim Jenness (JAC, Hawaii)
 *     PWD: Peter W. Draper (Starlink, Durham University)
 *     {enter_new_authors_here}

 *  History:
 *     12-AUG-1994 (BKM):
 *        Prototype version
 *     22-AUG-1994 (BKM)
 *        Released version
 *     20-SEP-1994 (AJC):
 *        Remove \ from end of lines
 *        Use strchr not index
 *        Allow blanks and comments on end of .FACILITY line
 *        MAXCHAR 101 to allow terminator on 100 char input line
 *        Modify `*p++ = ' construct on creating output filename
 *        - it doesn't work on mips
 *      3-NOV-1994 (AJC):
 *        Allow digits in idents
 *      2-AUG-1995 (BKM):
 *        Output conditional include test to C header file
 *     29-APR-2003 (BKM):
 *        Convert from sys_errlist[] to using strerrno()
 *     10-DEC-2003 (NG):
 *        Add -F option
 *     10-FEB-2004 (NG):
 *        Add -V option. Make -f and -F paths independent. Simplify
 *        variable names for fp0, fp1 etc.
 *     23-MAR-2004 (TIMJ):
 *        Add search for _ext external data files to be concatenated
 *        with the MESSGEN error codes.
 *        Allow the error id to have an underscore (eg VD_SAVNOTALL)
 *     05-JAN-2005 (PWD):
 *        Increase identifier buffer to allow 15 characters (match
 *        capabilities of ems/ems1Fcerr.c).
 *     23-SEP-2005 (TIMJ):
 *        C header files now write enum constants rather than
 *        CPP defines.
 *     20-APR-2017 (GSB):
 *        Write end marker before including external data files to
 *        assist cremsg in parsing the generated include files.
 *        Move end of #ifndef block after the included external data file.
 *     18-JUL-2017 (GSB):
 *        Correctly null-terminate facility name while parsing facility line.
 *        Null-terminate facility prefix while parsing facility line.
 *        Initialize error number and severity for each file.
 *     {enter_further_changes_here}

 *  Bugs:
 *     {note_any_bugs_here}

 *- */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

#define MAXLINE 101

unsigned int fac_code=0;
char fac_name[10], fac_prefix[10];

int f77_include=0, f77_INCLUDE=0, c_header=0, c_error=0;
int verify=0, write_filenames=0;

/* prototypes */
void write_external(char *, FILE *, char* );

static int
parse_facility(char buffer[MAXLINE])
{
/*
 * Parse a .FACILITY line in a message file.
 * Returns 1 for success or 0 on error
 */
    char *p, *p1;

    if((int)strlen(buffer) < 10)
	return 0;
    p = &buffer[9];
    while( strchr(" \t", *p) != NULL)
	p++;
    if (!isalpha(*p))
	return 0;
    p1 = p;
    while (isalpha(*p1)) {
	fac_name[p1-p] = *p1;
	p1++;
    }
    fac_name[p1-p] = '\0';
    if ((int)strlen(fac_name) > 9 || *p1 != ',')
	return 0;
    if ( (fac_code = strtol( p1+1, &p, 10)) == 0 )
	return 0;
/*
 * PREFIX is optional, if it is not there only comment is allowed
 */
    if (*p != '/' ){
       while( strchr(" \t", *p) != NULL)
   	  p++;
       if (strchr("!\n", *p) == NULL )
          return 0;
       else {
/*
 *     No PREFIX.
 *    If the facility name was good, use fac_name_ as prefix
 */
 	  if ( (int)strlen(fac_name) + 1 > 9)
	     return 0;
	  else {
	     strcpy(fac_prefix, fac_name);
 	     strcat(fac_prefix, "_");
          }
	}
    } else {
/*
 * PREFIX expected
 */
        if (strncmp(p, "/PREFIX=", 8) == 0) {
	p += 8;
	p1 = p;
	while (isalpha(*p1) || (strchr("_$", *p1)!=NULL) ){
	    fac_prefix[p1-p] = *p1;
	    p1++;
	}
        fac_prefix[p1-p] = '\0';
        while( strchr(" \t", *p1) != NULL)
   	  p1++;
	if ( ((int)strlen(fac_prefix) > 9) || ((*p1 != '\n') && (*p1 != '!')) )
	    return 0;
        }
    }
    return 1;
}

static void
process_file(char *filename)
{
/*
 * Process a message file.
 */
    unsigned int errcode, message_number=1, severity=0;

    FILE *fp; /* , *fp0, *fp1, *fp2; */
    FILE *fp_c = NULL;
    FILE *fp_f = NULL;
    FILE *fp_F = NULL;
    FILE *fp_error = NULL;

    /* store the filenames so that we can append _ext at end */
    char c_inc_outfile[MAXLINE];
    char f_inc_outfile[MAXLINE];
    char F_INC_outfile[MAXLINE];
    char fac_outfile[MAXLINE];

    char buffer[MAXLINE];
    char message_ident[16], *message_text;
    char *p, ch;
    int i, end=0;

    if ((fp = fopen(filename, "r")) == NULL) {
	fprintf(stderr, "Cannot open file %s : %s\n", filename,
		    strerror(errno) );
	return;
    }
    while (!end && fgets(buffer, MAXLINE, fp) != NULL) {
        switch(buffer[0]) {
	  case ' ':
	  case '!':
	  case '\t':
	  case '\n':
	    /* Do nothing */
	    break;
          case '.': /* Directives */
	    if (strncmp(&buffer[1], "TITLE", 5) == 0) /* Just echo to tty */
		printf("%s" , &buffer[1]);
	    else if (strncmp(&buffer[1], "FACILITY", 8) == 0) {
		if(!parse_facility(buffer)) {
		    fprintf(stderr, "Illegal .FACILITY directive\n%s", buffer);
		    return;
		}
		strcpy(buffer, fac_name); /* NB reusing buffer! */
		p = buffer;
		while (*p) {
		    *p = tolower(*p);
                    p++;
                }
		if (c_header) {
		    sprintf(c_inc_outfile, "%s_err.h", buffer);
		    if ((fp_c = fopen( c_inc_outfile, "w")) == NULL ) {
			fprintf(stderr, "Cannot open %s\n", c_inc_outfile);
			return;
		    }
                    if (write_filenames)
                        puts( c_inc_outfile );
		    fprintf(fp_c,
                            "/*\n * C error define file "
                            "for facility %s (%d)\n"
                            " * Generated by the MESSGEN utility\n"
                            " */\n\n",
                            fac_name, fac_code);
		    fprintf(fp_c,
                            "#ifndef %s_ERROR_DEFINED\n"
                            "#define %s_ERROR_DEFINED\n\n",
                            fac_name, fac_name);
		}
		if (f77_include) {
		    sprintf(f_inc_outfile, "%s_err", buffer);
		    if ((fp_f = fopen( f_inc_outfile, "w")) == NULL ) {
			fprintf(stderr, "Cannot open %s\n", f_inc_outfile);
			return;
		    }
                    if (write_filenames)
                        puts( f_inc_outfile );
		    fprintf(fp_f,
                            "* FORTRAN error include file for facility "
                            "%s (Code %d)\n"
                            "* Generated by the MESSGEN utility\n\n",
                            fac_name, fac_code);
		}
		if (f77_INCLUDE) {
                    /* identical to f77_include, but with filename upcased */
                    char *p;
		    sprintf(F_INC_outfile, "%s_err", buffer);
                    for (p=F_INC_outfile; *p!=0; p++)
                        *p = toupper(*p);
		    if ((fp_F = fopen( F_INC_outfile, "w")) == NULL ) {
			fprintf(stderr, "Cannot open %s\n", F_INC_outfile);
			return;
		    }
                    if (write_filenames)
                        puts( F_INC_outfile );
		    fprintf(fp_F,
                            "* FORTRAN error include file for facility "
                            "%s (Code %d)\n"
                            "* Generated by the MESSGEN utility\n\n",
                            fac_name, fac_code);
		}
		if (c_error) {
		    sprintf(fac_outfile, "fac_%d_err", fac_code);
		    if ((fp_error = fopen( fac_outfile, "w")) == NULL ) {
			fprintf(stderr, "Cannot open %s\n", fac_outfile);
			return;
		    }
                    if (write_filenames)
                        puts( fac_outfile );
		    fprintf(fp_error, "FACILITY %s\n", fac_name);
		}
            } else if (strncmp(&buffer[1], "IDENT", 5) == 0) {
		/* Ignore */;
	    } else if (strncmp(&buffer[1], "SEVERITY", 8) == 0) {
		p = &buffer[9];
		while (strchr(" \t", *p) != NULL)
		    p++;
                if (strncmp(p, "SUCCESS", 7) == 0)
		    severity = 1;
		else if (strncmp(p, "INFORMATIONAL", 13) == 0)
		    severity = 3;
                else if (strncmp(p, "WARNING", 7) == 0)
		    severity = 0;
                else if (strncmp(p, "ERROR",   5) == 0)
		    severity = 2;
                else if (strncmp(p, "SEVERE",  6) == 0)
		    severity = 4;
                else if (strncmp(p, "FATAL",   5) == 0)
		    severity = 4;
		else
		    fprintf(stderr, "Illegal .SEVERITY directive\n%s", buffer);
	    } else if (strncmp(&buffer[1], "BASE", 4) == 0) {
		if( ( message_number = strtol(&buffer[5], NULL, 10)) == 0)
		    fprintf(stderr, "Illegal .BASE directive\n%s", buffer);
	    } else if (strncmp(&buffer[1], "END", 3) == 0)
		end = 1;
	    break;
	  default:	/* Normal error message */
	    if (fac_code == 0) {
		fprintf(stderr, "Aborting ... FACILITY code not defined\n");
		return;
	    }
	    p = buffer;
            i = 0;
	    while( ( isalnum(*p) || *p == '_' ) && i < 15 ) {
		message_ident[i] = *p;
		p++;
                i++;
	    }
	    message_ident[i] = '\0';
	    while (strchr(" \t", *p) != NULL)
		p++;
	    ch = *p++;
	    if (ch == '\n')
		message_text = NULL;
	    else if (ch !='<' && ch != '"') {
		fprintf(stderr, "Illegal message definition\n%s", buffer);
		break;
            }
	    if (ch == '<')
		ch = '>';
	    i = strlen(buffer) - 1;
	    while (buffer[i] != ch)
		i--;
	    buffer[i] = '\0';
	    message_text = p;
	    if ((p = strstr(message_text, "/FAO")) != 0) {
		fprintf(stderr, "Cannot process /FAO directives\n%s", buffer);
		break;
	    }
	    errcode = ((fac_code | 0x800)  << 16) +
	      ((message_number | 0x1000) << 3) + severity;
/*
 * Output stage - write the error code to the specified files
 */
	    if (verify)
		printf("%16s\t%x\n", message_ident, errcode);
	    if (fp_c) {
                fprintf(fp_c,
                        "/* %s */\n"
                        "enum { %s%-16s	= %d };	/* messid=%d */\n\n",
			message_text, fac_prefix, message_ident, errcode,
			message_number);
	    }
	    if (fp_f) {
                fprintf(fp_f,
                        "*     %s\n"
                        "      INTEGER %s%s\n"
                        "      PARAMETER ( %s%s = %d )\n\n",
                        message_text, fac_prefix, message_ident,
                        fac_prefix, message_ident, errcode);
	    }
	    if (fp_F) {
                fprintf(fp_F,
                        "*     %s\n"
                        "      INTEGER %s%s\n"
                        "      PARAMETER ( %s%s = %d )\n\n",
                        message_text, fac_prefix, message_ident,
                        fac_prefix, message_ident, errcode);
	    }
	    if (fp_error) {
		fprintf(fp_error, "%d,%s,%s\n", message_number, message_ident,
			message_text);
	    }
	    message_number++;
	}
    }

    /* Append the _ext file contents */
    write_external(c_inc_outfile, fp_c, "\n/* %s */\n\n");
    write_external(f_inc_outfile, fp_f, "\n*  %s\n\n");
    write_external(F_INC_outfile, fp_F, "\n*  %s\n\n");

    if (fp_c) {
        fprintf(fp_c, "\n#endif	/* %s_ERROR_DEFINED */\n", fac_name);
    }

    if (verify)
	printf("MESSAGE file converted successfully\n");
    return;
}


/*
 * Find out whether we have extra header info that should be concatenated
 * with the VMS error code information. This is important for automatically
 * generating some historical error include files that mix messgen
 * error codes with other error codes. (see e.g. CHR and IDI that have
 * __OK constants set to 0, and GWM that mixes internal C error codes with
 * public messgen codes.
 *
 * MESSGEN will look for a file in the current directory with the
 * same name as the new output file but with the string _ext suffix
 * (to indicate external data). ie CHR_ERR will look for CHR_ERR_ext
 * and chr_err.h will look for chr_err.h_ext.

 *  write_external( char * file_name, FILE * fileptr )

*/

void
write_external( char * file_name, FILE * fileptr, char* end_marker_format) {
  const char suffix[5] = "_ext";
  char extdata[MAXLINE + 4];  /* include space for _ext */
  char buffer[MAXLINE];
  FILE * fp_ext = NULL;

  if (fileptr == NULL) return;

  /* add on the _ext suffix */
  strcpy(extdata, file_name);
  strcat(extdata,suffix);

  /* Try to open the file */
  fp_ext = fopen( extdata, "r");
  if (fp_ext == NULL) return;

  fprintf(fileptr, end_marker_format, "Non-MESSGEN error codes.");

  /* copy data to output handle */
  while (fgets(buffer, MAXLINE, fp_ext) != NULL) {
    fputs(buffer, fileptr);
  }
}




int
main(int argc, char *argv[])
{
    char *prog_name;
    int i;

/* Process argument list */
    prog_name = argv[0];
    for (*argv++; *argv; *argv++)
	if (**argv == '-') {
	    i = 1;
	    while ((*argv)[i] != '\0') {
		switch ((*argv)[i]) {
		  case 'f':
		    f77_include = 1;
		    break;
                  case 'F':
                    f77_INCLUDE = 1;
                    break;
		  case 'c':
		    c_header = 1;
		    break;
		  case  'e':
		    c_error = 1;
		    break;
		  case 'v':
		    verify = 1;
		    break;
                  case 'V':
                    write_filenames = 1;
                    break;
		  default:
		    fprintf(stderr,
			"%s - unknown option %s\n", prog_name, *argv);
		    exit(1);
 		}
		i++;
	    }
	} else
	    process_file(*argv);

    exit(0);
}
