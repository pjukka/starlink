/*
*+
*  Name:
*     smf_clipped_stats1D

*  Purpose:
*     Calculate mean and standard deviation of data array with sigma clipping

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     void smf_clipped_stats1D( const double *data, size_t nclips,
*                               const float clips[], size_t stride, size_t nsamp,
*                               smf_qual_t *quality, size_t qstride,
*                               smf_qual_t mask, double *mean,
*                               double *sigma, size_t *ngood, int *status );

*  Arguments:
*     data = const double* (Given)
*        Pointer to input data array
*     nclips = size_t (Given)
*        Number of clips to read from the clips[] array.
*     clips[] = const float (Given)
*        Array of sigma-clips to apply to the data before recalculating mean and
*        standard deviation.
*     stride = size_t (Given)
*        Index stride between elements
*     nsamp = size_t (Given)
*        Length of the interval to analyze
*     quality = smf_qual_t* (Given)
*        If specified, use this QUALITY array to decide which samples
*        to use (provided mask). Otherwise data are only ignored if set
*        to VAL__BADD.
*     qstride = size_t (Given)
*        Stride for qual. If 0 assumed to be stride.
*     mask = smf_qual_t (Given)
*        Use with qual to define which bits in quality are relevant to
*        ignore data in the calculation.
*     mean = double* (Given and Returned)
*        Pointer to variable that will contain the mean of the data.
*     sigma = double* (Given and Returned)
*        Pointer to variable that will contain the standard deviation of
*        the data. If NULL this routine will run faster and not calculate
*        the standard deviation.
*     ngood = size_t* (Given and Returned)
*        Pointer to variable that will indicate how many samples were used
*        to calculate the statistics.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Calculates the mean and standard deviation. Then applies a sigma
*     clip to the data and recalculates the mean and standard deviation
*     (if some additional points were removed). This is repeated for
*     each supplied clipping level.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  Notes:
*     - smf_stats1D is run at most nclips+1 times.
*     - if nclips is 0 smf_stats1D will be run and no clipping applied.

*  History:
*     2010-07-02 (TIMJ):
*        Initial version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2010 Science and Technology Facilities Council.
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


#include "smf.h"
#include "sae_par.h"

static size_t smf__flag_clipped_data( const double *data, size_t stride, size_t nsamp,
                                      smf_qual_t *qua, smf_qual_t badqual, double mean,
                                      double sigma, double sigclip, int * status );

void smf_clipped_stats1D( const double *data, size_t nclips,
                          const float clips[], size_t stride, size_t nsamp,
                          const smf_qual_t *quality, size_t qstride,
                          smf_qual_t mask, double *mean,
                          double *sigma, size_t *ngood, int *status ) {

  size_t clip = 0;                /* Clip index */
  size_t i = 0;                   /* Loop counter */
  double lmean = VAL__BADD;       /* Local mean */
  size_t lngood = 0;              /* Local ngood */
  double lsigma = VAL__BADD;      /* Local sigma */
  const smf_qual_t BADQUAL = 1;   /* The value we use for local bad quality */
  smf_qual_t * qua = NULL;        /* Quality we will be using locally */


  /* initialise return values */
  if (sigma) *sigma = VAL__BADD;
  if (ngood) *ngood = 0;
  if (mean) *mean = VAL__BADD;

  /* Check status */
  if (*status != SAI__OK) return;

  /* set up the stride through the quality whilst we copy quality */


  /* We are going to control smf_stats1 by using quality so we have to either
     create our own quality or copy an existing one. We will then use our own
     mask and a qstride that is 1 by definition. */
  qua = astCalloc( nsamp, sizeof(*qua) );

  if ( quality ) {
    size_t j = 0;

    /* make sure we step through properly */
    if (!qstride) qstride = stride;

    /* copy it over. i indexes the output quality */
    for ( i = 0; j < nsamp; i++) {
      if ( quality[j] & mask ) {
        qua[i] |= BADQUAL;
      }
      j += qstride;
    }

  } else {
    size_t j = 0;
    /* fill it from the bad values */
    for (i=0; i<nsamp*stride; i+=stride ) {
      if ( data[i] == VAL__BADD ) {
        qua[j] |= BADQUAL;
      }
      j++;
    }
  }

  /* Run stats and then clip */
  for ( clip = 0; clip < nclips; clip++) {

    /* Calculate stats with our quality and qstride of 1 */
    smf_stats1D( data, stride, nsamp, qua, 1, BADQUAL, &lmean, &lsigma, NULL,
                 &lngood, status );

    /* Flag any values exceeding the specified clip */
    lngood = smf__flag_clipped_data( data, stride, nsamp, qua, BADQUAL, lmean, lsigma,
                                     clips[clip], status );


  }

  /* and one final stats now that all clips have been applied*/
  smf_stats1D( data, stride, nsamp, qua, 1, BADQUAL, &lmean, &lsigma, NULL,
               &lngood, status );

  /* Free quality */
  qua = astFree( qua );

  /* Copy results */
  if (mean) *mean = lmean;
  if (sigma) *sigma = lsigma;
  if (ngood) *ngood = lngood;

}


/* Helper routine to run through the data array and setting quality to the supplied
   value if a data point is out of range. It does recalculate ngood and returns it. */

static size_t smf__flag_clipped_data( const double *data, size_t stride, size_t nsamp,
                                      smf_qual_t *qua, smf_qual_t badqual, double mean,
                                      double sigma, double sigclip, int * status ) {

  size_t i = 0;
  size_t j = 0;
  size_t ngood = 0;
  double dmax;
  double dmin;

  if (*status != SAI__OK) return 0;

  if (mean == VAL__BADD || sigma == VAL__BADD) {
    for ( i = 0; i<nsamp; i++) {
      qua[i] |= badqual;
    }
    return 0;
  }

  /* calculate acceptable bounds */
  dmax = mean + ( sigclip * sigma );
  dmin = mean - ( sigclip * sigma );

  for ( i = 0; i < nsamp*stride; i+=stride ) {
    if ( ! qua[j] ) {   /* any zero quality is good */
      if ( data[i] < dmin || data[i] > dmax ) {
        qua[j] |= badqual;
      } else {
        ngood++;
      }
    }
    j++; /* increment quality index */
  }

  return ngood;
}
