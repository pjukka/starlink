/*
*+
*  Name:
*     smf_clean_smfArray

*  Purpose:
*     Perform basic data cleaning operations on 3-d data

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_clean_smfArray( smfWorkForce *wf, smfArray *array,
*                         smfArray **noisemaps, AstKeyMap *keymap,
*                         int *status )

*  Arguments:
*     wf = smfWorkForce * (Given)
*        Pointer to a pool of worker threads. Can be NULL.
*     array = smfArray * (Given and Returned)
*        The data that will be cleaned
*     noisemaps = smfArray ** (Returned)
*        Optionally return bolo noise maps for each subarray if noiseclipping
*        is specified. Can be NULL.
*     keymap = AstKeyMap* (Given)
*        keymap containing parameters to control cleaning
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine is a wrapper for a number of basic data cleaning
*     operations which are controlled by parameters stored in the
*     AstKeyMap. The keywords that are understood, the general cleaning
*     procedures to which they apply, and the order in which they are
*     executed are listed here (for a full description of their
*     meaning and defaults values see documentation in
*     dimmconfig.lis):
*
*     Sync Quality : BADFRAC
*     DC steps     : DCFITBOX, DCMAXSTEPS, DCTHRESH, DCSMOOTH, DCLIMCORR
*     Flag spikes  : SPIKETHRESH, SPIKEBOX
*     Slew speed   : FLAGSLOW, FLAGFAST
*     Dark squids  : DKCLEAN
*     Gap filling  : ZEROPAD
*     Baselines    : ORDER
*     Common-Mode  : COMPREPROCESS
*     PCA          : PCATHRESH
*     Filtering    : FILT_EDGELOW, FILT_EDGEHIGH, FILT_NOTCHLOW,
*                    FILT_NOTCHHIGH, APOD, FILT_WLIM, WHITEN
*     Noisy Bolos  : NOISECLIPHIGH, NOISECLIPLOW

*  Notes:
*     The resulting dataOrder of the cube is not guaranteed, so smf_dataOrder
*     should be called upon return if it is important. smf_get_cleanpar does
*     all of the parsing of the key/value pairs in the AstKeyMap.

*  Authors:
*     Edward Chapin (UBC)
*     David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2010-05-31 (EC):
*        Initial Version factored out of smurf_sc2clean and smf_iteratemap
*     2010-06-25 (DSB):
*        Move apodisation to smf_filter_execute.
*     2010-09-10 (DSB):
*        Change smf_fix_steps argument list.
*     2010-09-15 (DSB):
*        Call smf_flag_spikes2 instead of smf_flag_spikes.
*     2010-09-15 (EC):
*        Use smf_fit_poly directly instead of smf_scanfit
*     2010-09-16 (EC):
*        Further simplification since smf_fit_poly can remove the poly as well
*     2010-09-20 (EC):
*        Optionally return noise map
*     2010-09-28 (DSB):
*        Allow data to be padded with artifical data rather than zeros.
*     2010-10-06 (EC):
*        Renamed to smf_clean_smfArray from smf_clean_smfData to reflect change
*        in interface.
*     2010-10-08 (DSB):
*        Move gap filling so that it is done immediately before the
*        filtering.
*     2010-10-13 (EC):
*        Add "compreprocess" option to do common-mode subtraction as an
*        optional pre-processing step.
*     2011-03-22 (EC):
*        Add "pcathresh" option to do PCA cleaning as a pre-processing step
*     2011-03-23 (DSB):
*        Use smf_select_quality to get pointer to quality arrays.
*     2011-03-30 (EC):
*        Only measure/flag slew speeds when telescope moving
*     2011-04-14 (DSB):
*        Remove gap filling since it is now done in smf_filter_execute.
*     2011-06-23 (EC):
*        Now have noisecliphigh and noisecliplow instead of noiseclip.

*  Copyright:
*     Copyright (C) 2010-2011 Univeristy of British Columbia.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_clean_smfArray"

void smf_clean_smfArray( smfWorkForce *wf, smfArray *array,
                         smfArray **noisemaps, AstKeyMap *keymap,
                         int *status ){

  /* Local Variables */
  double badfrac;           /* Fraction of bad samples to flag bad bolo */
  smfData *data=NULL;       /* Pointer to individual smfData */
  int compreprocess;        /* COMmon-mode cleaning as pre-processing step */
  dim_t dcfitbox;           /* width of box for measuring DC steps */
  int dclimcorr;            /* Min number of correlated steps */
  int dcmaxsteps;           /* number of DC steps/min. to flag bolo bad */
  dim_t dcsmooth;           /* median filter width before finding DC steps */
  double dcthresh;          /* n-sigma threshold for primary DC steps */
  int dofft;                /* are we doing a freq.-domain filter? */
  int dkclean;              /* Flag for dark squid cleaning */
  smfFilter *filt=NULL;     /* Frequency domain filter */
  double flagfast;          /* Threshold for flagging slow slews */
  double flagslow;          /* Threshold for flagging slow slews */
  dim_t idx;                /* Index within subgroup */
  size_t nflag;             /* Number of elements flagged */
  double noisecliphigh = 0; /* Sigma clip high-noise outlier bolos */
  double noisecliplow = 0;  /* Sigma clip low-noise outlier bolos */
  smfData *noisemap=NULL;   /* Individual noisemap */
  int order;                /* Order of polynomial for baseline fitting */
  double pcathresh;         /* n-sigma threshold for PCA cleaning */
  double spikethresh;       /* Threshold for finding spikes */
  size_t spikebox=0;        /* Box size for spike finder */
  struct timeval tv1, tv2;  /* Timers */
  int whiten;               /* Apply whitening filter? */
  int zeropad;              /* Pad with zeros? */

  /* Main routine */
  if (*status != SAI__OK) return;

  /*** TIMER ***/
  smf_timerinit( &tv1, &tv2, status );

  /* Check for valid inputs */

  if( !array || (array->ndat < 1) ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": No data supplied", status );
  }

  if( array->sdata[0]->ndims != 3 ) {
    *status = SMF__WDIM;
    errRepf( "", FUNC_NAME ": Supplied smfData has %zu dims, needs 3", status,
             data->ndims );
    return;
  }

  if( !keymap ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": NULL AstKeyMap supplied", status );
    return;
  }

  /* Get cleaning parameters */
  smf_get_cleanpar( keymap, &badfrac, &dcfitbox, &dcmaxsteps,
                    &dcthresh, &dcsmooth, &dclimcorr, &dkclean,
                    NULL, &zeropad, NULL, NULL, NULL, NULL, NULL,
                    NULL, NULL, NULL, &flagslow, &flagfast, &order,
                    &spikethresh, &spikebox, &noisecliphigh, &noisecliplow,
                    NULL, &compreprocess, &pcathresh, NULL, NULL, NULL,
                    status );

  /* Loop over subarray */
  for( idx=0; (idx<array->ndat)&&(*status==SAI__OK); idx++ ) {
    data = array->sdata[idx];

    /* Update quality by synchronizing to the data array VAL__BADD values */
    msgOutif(MSG__VERB,"", FUNC_NAME ": update quality", status);
    smf_update_quality( data, 1, NULL, 0, badfrac, status );

    /*** TIMER ***/
    msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s updating quality",
               status, smf_timerupdate(&tv1,&tv2,status) );

    /* Fix DC steps */
    if( dcthresh && dcfitbox ) {
      msgOutiff(MSG__VERB, "", FUNC_NAME
                ": Flagging bolos with %lf-sigma DC steps in %" DIM_T_FMT " "
                "samples as bad, using %" DIM_T_FMT
                "-sample median filter and max %d "
                "DC steps per min before flagging entire bolo bad...", status,
                dcthresh, dcfitbox, dcsmooth, dcmaxsteps);

      smf_fix_steps( wf, data, dcthresh, dcsmooth, dcfitbox, dcmaxsteps,
                     dclimcorr, &nflag, NULL, NULL, status );

      msgOutiff(MSG__VERB, "", FUNC_NAME": ...%zd flagged\n", status, nflag);

      /*** TIMER ***/
      msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s fixing DC steps",
                 status, smf_timerupdate(&tv1,&tv2,status) );
    }

    /* Flag Spikes */
    if( spikethresh ) {
      msgOutif(MSG__VERB," ", FUNC_NAME ": flag spikes...", status);
      smf_flag_spikes( wf, data, SMF__Q_FIT, spikethresh, spikebox,
                       &nflag, status );
      msgOutiff(MSG__VERB,"", FUNC_NAME ": ...found %zd", status, nflag );

      /*** TIMER ***/
      msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s flagging spikes",
                 status, smf_timerupdate(&tv1,&tv2,status) );
    }

    /*  Flag periods of stationary pointing, and update scanspeed to more
        accurate value */
    if( flagslow || flagfast ) {
      if( data->hdr && data->hdr->allState ) {
        double scanvel=0;

        if( flagslow ) {
          msgOutiff( MSG__VERB, "", FUNC_NAME
                     ": Flagging regions with slew speeds < %.2lf arcsec/sec",
                     status, flagslow );
        }

        if( flagfast ) {
          msgOutiff( MSG__VERB, "", FUNC_NAME
                     ": Flagging regions with slew speeds > %.2lf arcsec/sec",
                     status, flagfast );


          /* Check to see if this was a sequence type that involved
             motion.  If not, skip this section */
          if( data && data->hdr && (
                                    (data->hdr->seqtype==SMF__TYP_SCIENCE) ||
                                    (data->hdr->seqtype==SMF__TYP_POINTING) ||
                                    (data->hdr->seqtype==SMF__TYP_FOCUS) ||
                                    (data->hdr->seqtype==SMF__TYP_SKYDIP)) ) {

            smf_flag_slewspeed( data, flagslow, flagfast, &nflag, &scanvel,
                              status );
            msgOutiff( MSG__VERB,"", "%zu new time slices flagged", status,
                       nflag);

            if( msgIflev( NULL, status ) >= MSG__VERB ) {
              msgOutf( "", FUNC_NAME ": mean SCANVEL=%.2lf arcsec/sec"
                       " (was %.2lf)", status, scanvel, data->hdr->scanvel );
            }

            data->hdr->scanvel = scanvel;

            /*** TIMER ***/
            msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME
                       ":   ** %f s flagging outlier slew speeds",
                       status, smf_timerupdate(&tv1,&tv2,status) );
          } else {
            msgOutif( MSG__VERB, "", FUNC_NAME
                      ": not a moving sequence or missing header, "
                      "skipping slew speed flagging", status );
          }
        }
      } else {
        msgOutif( MSG__DEBUG, "", FUNC_NAME
                  ": Skipping flagslow/flagfast because no header present",
                  status );
      }
    }

    /* Clean out the dark squid signal */
    if( dkclean ) {
      msgOutif(MSG__VERB, "", FUNC_NAME
               ": Cleaning dark squid signals from data.", status);
      smf_clean_dksquid( data, 0, 100, NULL, 0, 0, 0, status );

      /*** TIMER ***/
      msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s DKSquid cleaning",
                 status, smf_timerupdate(&tv1,&tv2,status) );
    }

    /* Remove baselines */
    if( order >= 0 ) {
      msgOutiff( MSG__VERB,"", FUNC_NAME
                 ": Fitting and removing %i-order polynomial baselines",
                 status, order );

      smf_fit_poly( wf, data, order, 1, NULL, status );

      /*** TIMER ***/
      msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME
                 ":   ** %f s removing poly baseline",
                 status, smf_timerupdate(&tv1,&tv2,status) );
    }
  }

  /* Optionally call smf_calcmodel_com to perform a subset of the following
     tasks as a pre-processing step:

       - remove the common-mode
       - flag outlier data using common-mode rejection
       - determine relative flatfields using amplitude of common-mode

     In order to do this we need to set up some temporary model container
     files so that the routine can be called properly. All of the same
     COMmon-mode and GAIn model parameters (e.g. com.* and gai.*) will be
     used here. However, in addition the "compreprocess" flag must be set
     for this operation to be performed. */

  if( compreprocess ) {
    smfArray *comdata = NULL;
    smfGroup *comgroup = NULL;
    smfDIMMData dat;
    smfArray *gaidata = NULL;
    smfGroup *gaigroup = NULL;
    smfArray *quadata = NULL;
    smfData *thisqua=NULL;

    msgOutif(MSG__VERB," ", FUNC_NAME ": Remove common-mode", status);

    /* Create model containers for COM, GAI */
    smf_model_create( wf, NULL, &array, NULL, NULL, NULL, NULL, 1, SMF__COM,
                      0, NULL, 0, NULL, NULL, &comgroup, 1, 1, &comdata, keymap,
                      status );

    smf_model_create( wf, NULL, &array, NULL, NULL, NULL, NULL, 1, SMF__GAI,
                      0, NULL, 0, NULL, NULL, &gaigroup, 1, 1, &gaidata, keymap,
                      status );

    /* Manually create quadata to share memory with the quality already
       stored in array */

    quadata = smf_create_smfArray( status );
    for( idx=0; (*status==SAI__OK) && (idx<array->ndat); idx++ ) {
      /* Create several new smfDatas, but they will all be freed
         properly when we close quadata */
      thisqua = smf_create_smfData( SMF__NOCREATE_DA | SMF__NOCREATE_HEAD |
                                    SMF__NOCREATE_FILE, status );

      /* Probably only need pntr->[0], but fill in the dimensionality
         information to be on the safe side */
      thisqua->dtype = SMF__QUALTYPE;
      thisqua->ndims = array->sdata[idx]->ndims;
      thisqua->isTordered = array->sdata[idx]->isTordered;
      memcpy( thisqua->dims, array->sdata[idx]->dims, sizeof(thisqua->dims) );
      memcpy( thisqua->lbnd, array->sdata[idx]->lbnd, sizeof(thisqua->lbnd) );
      thisqua->pntr[0] = smf_select_qualpntr( array->sdata[idx], NULL, status );

      smf_addto_smfArray( quadata, thisqua, status );
    }

    /* Set up the smfDIMMData and call smf_calcmodel_com */
    memset( &dat, 0, sizeof(dat) );
    dat.res = &array;
    dat.gai = &gaidata;
    dat.qua = &quadata;
    dat.noi = NULL;

    smf_calcmodel_com( wf, &dat, 0, keymap, &comdata, SMF__DIMM_FIRSTITER,
                       status );

    /*** TIMER ***/
    msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME
               ":   ** %f s removing common-mode",
               status, smf_timerupdate(&tv1,&tv2,status) );

    /* Clean up */
    if( comdata ) smf_close_related( &comdata, status );
    if( comgroup ) smf_close_smfGroup( &comgroup, status );
    if( gaidata ) smf_close_related( &gaidata, status );
    if( gaigroup ) smf_close_smfGroup( &gaigroup, status );

    /* Before closing quadata unset all the pntr[0] since this is shared
       memory with the quality associated with array */
    if( quadata ) {
      for( idx=0; idx<quadata->ndat; idx++ ) {
        quadata->sdata[idx]->pntr[0] = NULL;
      }
      if( quadata ) smf_close_related( &quadata, status );
    }
  }

  /* PCA cleaning */
  if( pcathresh ) {
    /* Loop over subarray */
    for( idx=0; (idx<array->ndat)&&(*status==SAI__OK); idx++ ) {
      data = array->sdata[idx];

      smf_clean_pca( wf, data, pcathresh, NULL, NULL, 0, keymap, status );
    }

    /*** TIMER ***/
    msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s PCA cleaning",
               status, smf_timerupdate(&tv1,&tv2,status) );
  }


  /* Allocate space for noisemaps if required */

  if( noisemaps ) {
    *noisemaps = smf_create_smfArray( status );
  }

  /* Loop over subarray */

  for( idx=0; (idx<array->ndat)&&(*status==SAI__OK); idx++ ) {
    data = array->sdata[idx];

    /* Filter the data. Note that we call smf_filter_execute to apply
       a per-bolometer whitening filter even if there is no
       explicitly requested smfFilter (in which case the
       smf_filter_fromkeymap call will leave the real/imaginary parts
       of the filter as NULL pointers and they will get ignored inside
       smf_filter_execute). */

    filt = smf_create_smfFilter( data, status );
    smf_filter_fromkeymap( filt, keymap, data->hdr, &dofft, &whiten, status );

    if( (*status == SAI__OK) && dofft ) {
      msgOutif( MSG__VERB, "", FUNC_NAME ": frequency domain filter", status );
      smf_filter_execute( wf, data, filt, 0, whiten, status );

      /*** TIMER ***/
      msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s filtering data",
                 status, smf_timerupdate(&tv1,&tv2,status) );
    }
    filt = smf_free_smfFilter( filt, status );

    /* Noise mask */
    if( (*status==SAI__OK) && ((noisecliphigh>0.0) || (noisecliplow>0.0)) ) {
      smf_mask_noisy( wf, data,
                      (noisemaps && *noisemaps) ? (&noisemap) : NULL,
                      noisecliphigh, noisecliplow, 1, zeropad, status );

      if( noisemaps && *noisemaps && noisemap ) {
        smf_addto_smfArray( *noisemaps, noisemap, status );
      }

      /*** TIMER ***/
      msgOutiff( SMF__TIMER_MSG, "", FUNC_NAME ":   ** %f s masking noisy",
                 status, smf_timerupdate(&tv1,&tv2,status) );
    }
  }
}
