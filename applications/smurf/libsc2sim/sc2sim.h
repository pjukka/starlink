/*
*+
*  Name:
*     sc2sim.h

*  Purpose:
*     Prototypes for the libsc2sim library

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Header File

*  Invocation:
*     #include "sc2sim.h"

*  Description:
*     Prototypes used by the libsc2sim functions.

*  Authors:
*     J.Balfour (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-07-21 (JB):
*        Original
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     University of British Columbia.
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
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include "ast.h"
#include "sc2sim_par.h"
#include "sc2da/Dits_Err.h"
#include "sc2da/Ers.h"
#include "jcmt/state.h"

#include "sc2sim_struct.h"
#include "dxml_struct.h"

#ifndef SC2SIM_DEFINED
#define SC2SIM_DEFINED

#define C 299792458.0                  /* speed of light in metres/sec */
#define H 6.626e-34                    /* Planck's constant in joule.sec */
#define COUNTTOSEC 6.28                /* arcsec per pixel */
#define RIZERO 40.0                    /* distortion pattern centre */
#define RJZERO -10.0                   /* distortion pattern centre */
#define PIBY2 (AST__DPI/2.0)           /* math constant */
#define DIAMETER 15.0                  /* Diameter JCMT in metres */
#define MM2SEC 5.144                   /* plate scale at Nasmyth */

#define BOLCOL 32                      /* number of columns in a subarray */
#define BOLROW 40                      /* number of rows in a subarray */

/* -----------------------------------------------------------------------*/
/* Extra defines required for slalib routines */

#ifndef dmod
#define dmod(A,B) ((B)!=0.0?((A)*(B)>0.0?(A)-(B)*floor((A)/(B))\
                                        :(A)+(B)*floor(-(A)/(B))):(A))
#endif

#ifndef DS2R
#define DS2R 7.2722052166430399038487115353692196393452995355905e-5
#endif

#ifndef D2PI
#define D2PI 6.2831853071795864769252867665590057683943387987502
#endif


/* -----------------------------------------------------------------------*/

void sc2sim_addpnoise 
(
double lambda,       /* wavelength in metres (given) */
double bandGHz,      /* bandwidth in GHZ (given) */
double aomega,       /* geometrical optical factor (given) */
double integ_time,   /* Effective integration time in sec (given) */
double *flux,        /* Flux value in pW (given and returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_atmsky 
(
double lambda,       /* wavelength in metres (given) */
double trans,        /* % atmospheric transmission (given) */
double *flux,        /* flux per bolometer in pW (returned) */
int *status          /* global status (given and returned) */ 
); 

void sc2sim_atmtrans
(
double lambda,       /* wavelength in metres (given) */
double flux,         /* flux per bolometer in pW (given) */
double *trans,       /* % atmospheric transmission (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_bolcoords 
(
char *subname,       /* subarray name, s8a-s4d (given) */
double ra,           /* RA of observation in radians (given) */
double dec,          /* Dec of observation in radians (given) */
double elevation,    /* telescope elevation in radians (given) */
double p,            /* parallactic angle in radians (given) */
char *domain,        /* AST domain name to be used (given) */
int *bol,            /* bolometer counter (returned) */
double xbc[],        /* projected X coords of bolometers (returned) */
double ybc[],        /* projected Y coords of bolometers (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_bolnatcoords 
(
double *xbolo,        /* projected X coords of bolometers (returned) */
double *ybolo,        /* projected Y coords of bolometers (returned) */
int *bol,             /* bolometer counter (returned) */
int *status           /* global status (given and returned) */
);

void sc2sim_bousscan ( struct dxml_struct *inx, struct dxml_sim_struct *sinx, 
                       double digcurrent, double digmean, 
                       double digscale, char filter[], 
                       int maxwrite, obsMode mode, int nbol, int numscans,  
                       double pathlength, double *pzero, int rseed, 
		       double samptime, double scanangle, double scanspacing, 
                       double weights[], double *xbc, double *xbolo, 
                       double *ybc, double *ybolo,int *status);
void sc2sim_calctime
( 
double mjdaystart,   /* start time as modified juldate */
double samptime,     /* length of a sample in seconds */
int nsamp,           /* number of samples */
double *ut,          /* returned UT at each sample (mod. juldate) */
double *lst,         /* returned LST at each sample (radians) */
int *status          /* global status (given and returned) */
);

void sc2sim_calctrans
(
double lambda,        /* wavelength in metres (given) */
double *trans,        /* % atmospheric transmission (returned) */
double tauCSO,        /* CSO optical depth (given) */
int *status           /* global status (given and returned) */
);

void sc2sim_digitise 
(
int nvals,            /* number of values (given) */
double current[],     /* signal values in amps (given) */
double digmean,       /* mean digitised level (given) */
double digscale,      /* digitisation scale factor (given) */
double digcurrent,    /* current in amps at digmean (given) */
int digits[],         /* digitised currents (returned) */
int *status           /* global status (given and returned) */
);

double sc2sim_drand
(
double sigma          /* sigma of distribution (given) */
);

void sc2sim_fitheat 
(
int nboll,             /* number of bolometers (given) */
int nframes,           /* number of frames in scan (given) */
double *heat,          /* heater values (given) */
double *inptr,         /* measurement values (given) */
double *coptr,         /* coefficients of fit (returned) */
int *status            /* global status (given and returned) */
);

void sc2sim_four1 
( 
int isign,         /* direction of transform (given) */
int nn,            /* number of complex values (given) */
double data[]      /* complex signal transformed in-place - even indices 
                      real values, odd imaginary (given and returned) */
);

void sc2sim_getast_wcs 
( 
int nboll,                   /* total number of bolometers (given) */
double *xbolo,               /* x-bolometer coordinates for array (given) */
double *ybolo,               /* y-bolometer coordinates for array (given) */
AstCmpMap *bolo2map,         /* mapping bolo->sky image coordinates (given ) */
double *astsim,              /* astronomical image (given) */
int astnaxes[2],             /* dimensions of simulated image (given) */
double *dbuf,                /* pointer to bolo output (returned) */
int *status                  /* global status (given and returned) */
);

void sc2sim_getbilinear 
( 
double xpos,         /* X-coordinate of sample point in arcsec (given) */
double ypos,         /* Y-coordinate of sample point in arcsec (given) */
double scale,        /* scale of image in arcsec per pixel (given) */
int size,            /* size of image (given) */
double *image,       /* astronomical image (given) */
double *value,       /* value sampled from image (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_getbous
(
double angle,        /* angle of pattern relative to telescope
                        axes in radians anticlockwise (given) */
double pathlength,   /* length of scanpath (arcsec) (given) */
int scancount,       /* total number of scans (given) */
double spacing,      /* distance between scans (arcsec) (given) */
double accel[2],     /* telescope accelerations (arcsec) (given) */
double vmax[2],      /* telescope maximum velocities (arcsec) (given) */
double samptime,     /* sample interval in sec (given) */
int *bouscount,      /* number of positions in pattern (returned) */
double **posptr,     /* list of positions (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_getinvf 
( 
double sigma,        /* dispersion of broad-band noise (given) */ 
double corner,       /* corner frequency, where 1/f dispersion=sigma (given)*/
double samptime,     /* time per data sample (given) */
double nterms,       /* number of frequencies calculated (given) */
double *noisecoeffs, /* 1/f spectrum (returned) */
int *status          /* global status (given and returned) */
);

obsMode sc2sim_getobsmode
( 
char *name,         /* string containing name of observing mode */
int *status         /* global status (given and returned) */
);

void sc2sim_getpar
( 
int argc,                /* argument count (given) */
char **argv,             /* argument list (given) */
struct dxml_struct *inx, /* structure for values from XML file (returned) */
struct dxml_sim_struct *sinx, /* structure for values from XML file (returned) */
int *rseed,              /* seed for random number generator (returned)*/
int *savebols,           /* flag for writing bolometer details (returned) */
int *status              /* global status (given and returned) */
);

void sc2sim_getpat
(
int nvert,            /* Number of vertices per pattern (given) */
int smu_samples,      /* number of samples between vertices (given) */
double sample_t,      /* time between data samples in msec (given) */
double smu_offset,    /* smu timing offset in msec (given) */
int conv_shape,       /* choice of convolution function (given) */
double conv_sig,      /* convolution parameter (given) */
int move_code,        /* SMU waveform choice (given) */
double jig_stepx,     /* X interval in arcsec (given) */
double jig_stepy,     /* Y interval in arcsec (given) */
int jig_vert[][2],    /* Array with relative jiggle coordinates in units of
                         jiggle steps in case jiggle positions are 
                         visited (given) */

int *cycle_samples,   /* The number of samples per cycle (returned) */

double pattern[][2],  /* The array to hold the coordinates of the jiggle 
                         offsets in arcsec. There are cycle_samples entries 
                         filled. (returned) */

int *status           /* global status (given and returned) */
);

void sc2sim_getpong
(
double angle,        /* angle of pattern relative to telescope
                        axes in radians anticlockwise (given) */
int gridcount,       /* number of grid lines (odd) (given) */
double spacing,      /* grid spacing in arcsec (given) */
double accel[2],     /* telescope accelerations (arcsec) (given) */
double vmax[2],      /* telescope maximum velocities (arcsec) (given) */
double samptime,     /* sample interval in sec (given) */
double grid[][2],    /* pong grid coordinates (returned) */
int *pongcount,      /* number of positions in pattern (returned) */
double **posptr,     /* list of positions (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_getpongends
( 
int gridcount,           /* number of grid lines (odd) (given) */
double spacing,          /* grid spacing in arcsec (given) */
double grid[][2],        /* coordinates of pong vertices (returned) */
int *status              /* global status (given and returned) */
);

void sc2sim_getscaling
( 
int ncoeffs,          /* number of coefficients describing response curve
                         (given) */
double coeffs[],      /* array to hold response curve coefficients (given) */
double targetpow,     /* target power level in pW (given) */
double photonsigma,   /* photon noise level (given) */
double *digmean,      /* mean digitised level (returned) */
double *digscale,     /* digitisation scale factor (returned) */
double *digcurrent,   /* current in amps at digmean (returned) */
int *status           /* global status (given and returned) */
);

void sc2sim_getscanseg
( 
double samptime,     /* sample time in sec (given) */
double cstart[2],    /* starting coordinates in arcsec (given) */
double cend[2],      /* ending coordinates in arcsec (given) */
double accel[2],     /* telescope accelerations (arcsec) (given) */
double vmax[2],      /* telescope maximum velocities (arcsec) (given) */
int maxoff,          /* maximum total of offsets in pattern (given) */
int *curroff,        /* current offset in pattern (given and returned) */
double *pattern,     /* pointing coordinates in arcsec (given and returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_getscansegsize
( 
double samptime,     /* sample time in sec (given) */
double cstart[2],    /* starting coordinates in arcsec (given) */
double cend[2],      /* ending coordinates in arcsec (given) */
double accel[2],     /* telescope accelerations (arcsec) (given) */
double vmax[2],      /* telescope maximum velocities (arcsec) (given) */
int *size,           /* number of samples in pattern (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_getsigma
( 
double lambda,         /* wavelength in metres (given) */
double bandGHz,        /* bandwidth in GHz (given) */
double aomega,         /* geometrical factor (given) */
double flux,           /* sky power per pixel in pW (given) */
double *sigma,         /* photon noise in pW (returned) */
int *status            /* global status (given and returned) */
);

void sc2sim_getsinglescan
(
double angle,        /* angle of pattern relative to telescope
                        axes in radians anticlockwise (given) */
double pathlength,   /* length of scanpath (arcsec) (given) */
double accel[2],     /* telescope accelerations (arcsec) (given) */
double vmax[2],      /* telescope maximum velocities (arcsec) (given) */
double samptime,     /* sample interval in sec (given) */
int *scancount,      /* number of positions in pattern (returned) */
double **posptr,     /* list of positions (returned) */
int *status          /* global status (given and returned) */
);

void sc2sim_getspread
( 
int numbols,             /* Number of bolometers (given) */
double pzero[],          /* Array to hold response curve offsets 
                            of bolometers in pW (returned) */
double heater[],         /* Array to hold heater factors of bolometers
                            (returned) */
int *status              /* global status (given and returned) */
);

void sc2sim_getweights
( 
double decay,      /* time constant in millisec (given) */
double samptime,   /* sampling time in millisec (given) */
int nweights,      /* number of values to be returned (given) */
double weights[],  /* array to hold returned values (returned) */
int *status        /* global status (given and returned) */
);

void sc2sim_heatrun ( struct dxml_struct *inx, struct dxml_sim_struct *sinx, 
                      double coeffs[], double digcurrent, double digmean, 
                      double digscale, char filter[], double *heater, int nbol,
                      double *pzero, double samptime, int *status );

void sc2sim_hor2eq
( 
double az,          /* Azimuth in radians (given) */
double el,          /* Elevation in radians (given) */
double lst,         /* local sidereal time in radians (given) */
double *ra,         /* Right Ascension in radians (returned) */
double *dec,        /* Declination in radians (returned) */
int *status         /* global status (given and returned) */
);

void sc2sim_instrinit
( 
int argc,                /* argument count (given) */
char **argv,             /* argument list (given) */
struct dxml_struct *inx, /* structure for values from XML file (returned) */
struct dxml_sim_struct *sinx, /* structure for values from XML file(returned) */
int *rseed,              /* seed for random number generator (returned)*/
double coeffs[NCOEFFS],  /* bolometer response coeffs (returned) */
double *digcurrent,      /* digitisation mean current (returned) */
double *digmean,         /* digitisation mean value (returned) */
double *digscale,        /* digitisation scale factore (returned) */
double *elevation,       /* telescope elevation (radians) (returned) */
double weights[],        /* impulse response (returned) */
double **heater,         /* bolometer heater ratios (returned) */
double **pzero,          /* bolometer power offsets (returned) */
double **xbc,            /* X offsets of bolometers in arcsec (returned) */
double **ybc,            /* Y offsets of bolometers in arcsec (returned) */
double **xbolo,          /* Native bolo x-offsets */
double **ybolo,          /* Native bolo x-offsets */
int *status              /* global status (given and returned) */
);

void sc2sim_invf
( 
double sigma,     /* white noise level (given) */
double corner,    /* corner frequency (given) */
double samptime,  /* time in sec between samples (given) */
int nsamples,     /* number of positions in sequence (given) */
double *fnoise,   /* array to hold noise sequence (returned) */
int *status       /* global status (given and returned) * */
);

void sc2sim_lissajousscan( struct dxml_struct *inx, struct dxml_sim_struct *sinx, 
                      double digcurrent, double digmean, double digscale, 
                      char filter[], int maxwrite, obsMode mode, int nbol, 
			   int rseed, double samptime, int *status );

void sc2sim_ndfwrdata
( 
double ra,        /* RA of observation in radians (given) */
double dec,       /* Dec of observation in radians (given) */
int add_atm,      /* flag for adding atmospheric emission (given) */
int add_fnoise,   /* flag for adding 1/f noise (given) */
int add_pns,      /* flag for adding photon noise (given) */
int flux2cur,     /* flag for converting flux to current (given) */
double amstart,   /* Airmass at beginning (given) */
double amend,     /* Airmass at end (given) */
double meanwvm,   /* 225 GHz tau */
double obslam,    /* Wavelength */
char file_name[], /* output file name (given) */
int ncol,         /* number of bolometers in column (given) */
int nrow,         /* number of bolometers in row (given) */
double sample_t,  /* sample interval in msec (given) */
char subarray[],  /* name of the subarray */
int numsamples,   /* number of samples (given) */
int nflat,        /* number of flat coeffs per bol (given) */
char *flatname,   /* name of flatfield algorithm (given) */
JCMTState *head,  /* header data for each frame (given) */
int *dbuf,        /* simulated data (given) */
int *dksquid,     /* dark SQUID time stream data (given) */
double *fcal,     /* flatfield calibration (given) */
double *fpar,     /* flat-field parameters (given) */
char filter[],    /* String representing filter (e.g. "850") (given) */
double atstart,   /* Ambient temperature at start (Celsius) (given) */
double atend,     /* Ambient temperature at end (Celsius) (given) */
double *posptr,   /* Pointing offsets from map centre */
char *obsmode,    /* Observing mode */
int *status       /* global status (given and returned) */
);

void sc2sim_ndfwrheat
( 
int add_atm,       /* flag for adding atmospheric emission (given) */
int add_fnoise,    /* flag for adding 1/f noise (given) */
int add_pns,       /* flag for adding photon noise (given) */
double heatstart,  /* initial heater setting in pW (given) */
double heatstep,   /* increment of heater setting in pW (given) */
char file_name[],  /* output file name (given) */
int ncol,          /* number of bolometers in column (given) */
int nrow,          /* number of bolometers in row (given) */
double sample_t,   /* sample interval in msec (given) */
char subarray[],   /* name of the subarray */
int numsamples,    /* number of samples (given) */
int nflat,         /* number of flat coeffs per bol (given) */
char *flatname,    /* name of flatfield algorithm (given) */
JCMTState *head,   /* header data for each frame (given) */
int *dbuf,         /* time stream data (given) */
int *dksquid,      /* dark SQUID time stream data (given) */
double *fcal,      /* flat-field calibration (given) */
double *fpar,      /* flat-field parameters (given) */
char filter[],     /* String representing filter (e.g. "850") (given) */
double atstart,    /* Ambient temperature at start (Celsius) (given) */
double atend,      /* Ambient temperature at end (Celsius) (given) */
int *status        /* global status (given and returned) */
);

void sc2sim_ptoi
( 
double flux,       /* input flux in pW (given) */
int ncoeffs,       /* number of coefficients describing response curve
                      (given) */
double coeffs[],   /* array to hold response curve coefficients (given) */
double pzero,      /* calibration offset in pW (given) */
double *current,   /* signal from bolometer in amps (returned) */
int *status        /* global status (given and returned) */
);

void sc2sim_response
( 
double lambda,     /* wavelength in metres (given) */
int ncoeffs,       /* number of coefficients to be returned (given) */
double coeffs[],   /* array to hold returned coefficients (returned) */
int *status        /* global status (given and returned) */
);

void sc2sim_simframe
( 
struct dxml_struct inx,      /* structure for values from XML (given) */
struct dxml_sim_struct sinx, /* structure for sim values from XML (given)*/
int astnaxes[2],             /* dimensions of simulated image (given) */
double astscale,             /* pixel size in simulated image (given) */
double *astsim,              /* astronomical sky (given) */
int atmnaxes[2],             /* dimensions of simulated atm background
                                (given) */
double atmscale,             /* pixel size in simulated atm background
                                (given) */
double *atmsim,              /* atmospheric emission (given) */
double coeffs[],             /* bolometer response coeffs (given) */
AstFrameSet *fset,           /* World Coordinate transformations */
double heater[],             /* bolometer heater ratios (given) */
int nboll,                   /* total number of bolometers (given) */
int frame,                   /* number of current frame (given) */
int nterms,                  /* number of 1/f noise coeffs (given) */
double *noisecoeffs,         /* 1/f noise coeffs (given) */
double *pzero,               /* bolometer power offsets (given) */
double samptime,             /* sample time in sec (given) */
double start_time,           /* time at start of scan in sec  (given) */
double telemission,          /* power from telescope emission (given) */
double *weights,             /* impulse response (given) */
AstMapping *sky2map,         /* Mapping celestial->map coordinates */
double *xbolo,               /* native X offsets of bolometers */
double *ybolo,               /* native Y offsets of bolometers */
double *xbc,                 /* nasmyth X offsets of bolometers */
double *ybc,                 /* nasmyth Y offsets of bolometers */
double *position,            /* nasmyth positions of bolometers */
double *dbuf,                /* generated frame (returned) */
int *status                  /* global status (given and returned) */
);

void sc2sim_simhits ( struct dxml_struct *inx, struct dxml_sim_struct *sinx, 
                      double digcurrent, double digmean, double digscale, 
                      char filter[], int maxwrite, obsMode mode, int nbol, 
                      int rseed, double samptime, int *status);

void sc2sim_simplescan ( struct dxml_struct *inx, struct dxml_sim_struct *sinx, 
                         double digcurrent, double digmean, 
                         double digscale, char filter[], 
                         int maxwrite, obsMode mode, int nbol,  
                         double pathlength, double *pzero, int rseed, 
		         double samptime, double scanangle, 
                         double weights[], double *xbc, double *xbolo, 
                         double *ybc, double *ybolo,int *status );

void sc2sim_simulate ( struct dxml_struct *inx, struct dxml_sim_struct *sinx, 
                       double coeffs[], double digcurrent, double digmean, 
                       double digscale, char filter[], double *heater, int maxwrite,
                       obsMode mode, int nbol, double *pzero, int rseed, 
                       double samptime, double weights[], double *xbc, double *xbolo,
                       double *ybc, double *ybolo, int *status );

void sc2sim_telpos
( 
double ra,           /* Right Ascension in radians (given) */
double dec,          /* Declination in radians (given) */
double lst,          /* local sidereal time in radians (given) */
double *az,          /* Azimuth in radians (returned) */
double *el,          /* Elevation in radians (returned) */
double *p,           /* Parallactic angle in radians (returned) */
int *status          /* global status (given and returned) */
);

#endif /* SC2SIM_DEFINED */
