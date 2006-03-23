#include "sae_par.h"
#include "mers.h"
#include "cupid.h"
#include "ast.h"
#include "ndf.h"
#include "prm_par.h"
#include "star/hds.h"
#include <math.h>

HDSLoc *cupidFellWalker( int type, int ndim, int *slbnd, int *subnd, void *ipd,
                      double *ipv, double rms, AstKeyMap *config, int velax,
                      int ilevel, int *nclump ){
/*
*  Name:
*     cupidFellWalker

*  Purpose:
*     Identify clumps of emission within a 1, 2 or 3 dimensional NDF using
*     the FELLWALKER algorithm.

*  Synopsis:
*     HDSLoc *cupidFellWalker( int type, int ndim, int *slbnd, int *subnd, 
*                           void *ipd, double *ipv, double rms, 
*                           AstKeyMap *config, int velax, int *nclump )

*  Description:
*     This function identifies clumps within a 1, 2 or 3 dimensional data
*     array using the FELLWALKER algorithm. This algorithm loops over
*     every data pixel above the threshold which has not already been
*     assigned to a clump. For each such pixel, a route to the nearest
*     peak in the data value is found by moving from pixel to pixel along
*     the line of greatest gradient. When this route arrives at a peak, all
*     pixels within some small neighbourhood are checked to see if there
*     is a higher data value. If there is, the route recommences from the
*     highest pixel in the neighbourhood, again moving up the line of
*     greatest gradient. When a peak is reached which is the highest data
*     value within its neighbourhood, a check is made to see if this peak
*     pixel has already been assigned to a clump. If it has, then all
*     pixels which were traversed in following the route to this peak are 
*     assigned to the same clump. If the peak has not yet been assigned to a
*     clump, then it, and all the traversed pixels, are assigned to a new
*     clump. If the route commences with a low gradient section (average
*     gradient lower than a given value) then the initial section of the
*     route (up to the point where the gradient exceeds the low gradient 
*     limit) is not assigned to the clump, but is instead given a special
*     value which prevents the pixels being re-used as the start point
*     for a new "walk".

*  Parameters:
*     type
*        An integer identifying the data type of the array values pointed to 
*        by "ipd". Must be either CUPID__DOUBLE or CUPID__FLOAT (defined in
*        cupid.h).
*     ndim
*        The number of dimensions in the data array. Must be 2 or 3.
*     slbnd
*        Pointer to an array holding the lower pixel index bound of the
*        data array on each axis.
*     subnd
*        Pointer to an array holding the upper pixel index bound of the
*        data array on each axis.
*     ipd
*        Pointer to the data array. The elements should be stored in
*        Fortran order. The data type of this array is given by "itype".
*     ipv
*        Pointer to the input Variance array, or NULL if there is no Variance
*        array. The elements should be stored in Fortran order. The data 
*        type of this array is "double".
*     rms
*        The global RMS error in the data array.
*     config
*        An AST KeyMap holding tuning parameters for the algorithm.
*     velax
*        The index of the velocity axis in the data array (if any). Only
*        used if "ndim" is 3. 
*     ilevel
*        Amount of screen information to display (in range zero to 6).
*     nclump
*        Pointer to an int to receive the number of clumps found.

*  Retured Value:
*     A locator for a new HDS object which is an array of NDF structures.
*     The number of NDFs in the array is given by the value returned in 
*     "*nclump". Each NDF will hold the data values associated with a single 
*     clump and will be the smallest possible NDF that completely contains 
*     the corresponding clump. Pixels not in the clump will be set bad. The 
*     pixel origin is set to the same value as the supplied NDF.

*  Authors:
*     DSB: David S. Berry
*     {enter_new_authors_here}

*  History:
*     16-JAN-2006 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}
*/      

/* Local Variables: */
   AstKeyMap *fwconfig; /* Configuration parameters for this algorithm */
   HDSLoc *ret;         /* Locator for the returned array of NDFs */
   int *clbnd;          /* Array holding lower axis bounds of all clumps */
   int *cubnd;          /* Array holding upper axis bounds of all clumps */
   int *ipa;            /* Pointer to clump assignment array */
   int *nrem;           /* Pointer to array marking out edge pixels */
   int *pa;             /* Pointer to next element of the ipa array */
   int dims[3];         /* Pointer to array of array dimensions */
   int el;              /* Number of elements in array */
   int i;               /* Loop count */
   int ix;              /* Grid index on 1st axis */
   int iy;              /* Grid index on 2nd axis */
   int iz;              /* Grid index on 3rd axis */
   int maxid;           /* Largest id for any peak (smallest is zero) */
   int minpix;          /* Minimum total size of a clump in pixels */
   int skip[3];         /* Pointer to array of axis skips */

/* Initialise */
   ret = NULL;
   *nclump = 0;

/* Abort if an error has already occurred. */
   if( *status != SAI__OK ) return ret;

/* Say which method is being used. */
   if( ilevel > 0 ) {
      msgBlank( status );
      msgOut( "", "FellWalker:", status );
      if( ilevel > 1 ) msgBlank( status );
   }

/* Get the AST KeyMap holding the configuration parameters for this
   algorithm. */
   if( !astMapGet0A( config, "FELLWALKER", &fwconfig ) ) {     
      fwconfig = astKeyMap( "" );
      astMapPut0A( config, "FELLWALKER", fwconfig, "" );
   }

/* The configuration file can optionally omit the algorithm name. In this
   case the "config" KeyMap may contain values which should really be in
   the "fwconfig" KeyMap. Add a copy of the "config" KeyMap into "fwconfig" 
   so that it can be searched for any value which cannot be found in the
   "fwconfig" KeyMap. */
   astMapPut0A( fwconfig, CUPID__CONFIG, astCopy( config ), NULL );

/* Find the size of each dimension of the data array, and the total number
   of elements in the array, and the skip in 1D vector index needed to
   move by pixel along an axis. We use the memory management functions of the 
   AST library since they provide greater security and functionality than 
   direct use of malloc, etc. */
   el = 1;
   for( i = 0; i < ndim; i++ ) {
      dims[ i ] = subnd[ i ] - slbnd[ i ] + 1;
      el *= dims[ i ];
      skip[ i ] = ( i == 0 ) ? 1 : skip[ i - 1 ]*dims[ i - 1 ];
   }
   for( ; i < 3; i++ ) {
      dims[ i ] = 1;
      skip[ i ] = 0;
   }

/* Assign work array to hold the clump assignments. */
   ipa = astMalloc( sizeof( int )*el );

/* Assign every data pixel to a clump and stores the clumps index in the
   corresponding pixel in "ipa". */
   maxid = cupidFWMain( type, ipd, el, ndim, dims, skip, rms, fwconfig,
                        ipa );

/* Abort if no clumps found. */
   if( maxid < 0 ) {
      if( ilevel > 0 ) {
         msgOut( "", "No usable clumps found", status );
         msgBlank( status );
      }
      goto L10;
   }

/* Allocate an array used to store the number of pixels remaining in each 
   clump. */
   nrem = astMalloc( sizeof( int )*( maxid + 1 ) );

/* Determine the bounding box of every clump. First allocate memory to
   hold the bounding boxes. */
   clbnd = astMalloc( sizeof( int )*( maxid + 1 )*3 );
   cubnd = astMalloc( sizeof( int )*( maxid + 1 )*3 );
   if( cubnd ) {

/* Get the minimum allowed number of pixels in a clump. */
      minpix = cupidConfigI( fwconfig, "MINPIX", 16 );

/* Initialise a list to hold zero for every clump id. These values are
   used to count the number of pixels remaining in each clump. */
      for( i = 0; i <= maxid; i++ ) nrem[ i ] = 0;

/* Initialise the bounding boxes. */
      for( i = 0; i < 3*( maxid + 1 ); i++ ) {
         clbnd[ i ] = VAL__MAXI;
         cubnd[ i ] = VAL__MINI;
      }

/* Loop round every pixel in the final pixel assignment array. */
      pa = ipa;
      for( iz = 1; iz <= dims[ 2 ]; iz++ ){
         for( iy = 1; iy <= dims[ 1 ]; iy++ ){
            for( ix = 1; ix <= dims[ 0 ]; ix++, pa++ ){

/* Skip pixels which are not in any clump. */
               if( *pa >= 0 ) {

/* Increment the number of pixels in this clump. */
                  ++( nrem[ *pa ] );

/* Get the index within the clbnd and cubnd arrays of the current bounds
   on the x axis for this clump. */
                  i = 3*( *pa );

/* Update the bounds for the x axis, then increment to get the index of the y
   axis bounds. */
                  if( ix < clbnd[ i ] ) clbnd[ i ] = ix;
                  if( ix > cubnd[ i ] ) cubnd[ i ] = ix;
                  i++;

/* Update the bounds for the y axis, then increment to get the index of the z
   axis bounds. */
                  if( iy < clbnd[ i ] ) clbnd[ i ] = iy;
                  if( iy > cubnd[ i ] ) cubnd[ i ] = iy;
                  i++;

/* Update the bounds for the z axis. */
                  if( iz < clbnd[ i ] ) clbnd[ i ] = iz;
                  if( iz > cubnd[ i ] ) cubnd[ i ] = iz;
               }
            }
         }
      }

/* Loop round creating an NDF describing each clump with more than "minpix"
   pixels, counting them. */
      for( i = 0; i <= maxid; i++ ) {
         if( nrem[ i ] > minpix ) {
            ret = cupidNdfClump( type, ipd, ipa, el, ndim, dims, skip, slbnd, 
                                 i, clbnd + 3*i, cubnd + 3*i, NULL, ret );
            (*nclump)++;
         }
      }

      if( ilevel > 0 ) {
         if( *nclump == 0 ) {
            msgOut( "", "No usable clumps found", status );
         } else if( *nclump == 1 ){
            msgOut( "", "One usable clump found", status );
         } else {
            msgSeti( "N", *nclump );
            msgOut( "", "^N usable clumps found", status );
         }
         msgBlank( status );
      }         

/* Free resources */
      clbnd = astFree( clbnd );
      cubnd = astFree( cubnd );
   }

L10:;

/* Remove the secondary KeyMap added to the KeyMap containing configuration 
   parameters for this algorithm. This prevents the values in the secondary 
   KeyMap being written out to the CUPID extension when cupidStoreConfig is 
   called. */
   astMapRemove( fwconfig, CUPID__CONFIG );

/* Free resources */
   fwconfig = astAnnul( fwconfig );
   ipa = astFree( ipa );

/* Return the list of clump NDFs. */
   return ret;

}

