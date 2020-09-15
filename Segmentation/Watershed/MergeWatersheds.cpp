#ifdef MATLAB

#include "MergeSegments.h"

#include "mex.h" // Matlab types and functions.
#include <map>
#include <vector>

using namespace std;

/* MergeWatersheds merges watersheds in a label image created by the watershed transform.
 *
 * Syntax:
 * oNewLabels = MergeWatersheds(aLabels, aImage, aMergeThreshold, aMinSize)
 */

void mexFunction(
        int nlhs,               // Number of outputs.
        mxArray *plhs[],        // Array of output pointers.
        int nrhs,               // Number of inputs.
        const mxArray *prhs[])  // Array of input pointers.
{
    
    // Check the number of input and output arguments.
    if(nrhs != 4) {
        mexErrMsgTxt("MergeWatersheds takes 4 input arguments.");
    }
    if(nlhs != 1) {
        mexErrMsgTxt("MergeWatersheds gives only 1 output argument.");
    }

    // Inputs.

	double *aLabels_double = mxGetPr(prhs[0]);
	int numDims = (int) mxGetNumberOfDimensions(prhs[0]);  // Number of image dimensions.
	const mwSize *dims = mxGetDimensions(prhs[0]);  // Array of image dimensions.
	int *dims_int = new int[numDims];
	for (int i=0; i<numDims; i++) {
		dims_int[i] = (int) dims[i];
	}
	int numElements = (int) mxGetNumberOfElements(prhs[0]);
	
	// Convert double labels to int labels.
	int *aLabels = new int[numElements];
	for (int i=0; i<numElements; i++) {
		aLabels[i] = (int) aLabels_double[i];
	}
    
	double *aImage = mxGetPr(prhs[1]);
	double aMergeThreshold = *mxGetPr(prhs[2]);
	int aMinSize = (int) *mxGetPr(prhs[3]);
	

	// Outputs.
	plhs[0] = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
    double *oNewLabels_double = mxGetPr(plhs[0]);

	int *oNewLabels = new int[numElements];

	// Merge the watersheds.
	MergeSegments(numDims, dims_int, aLabels, aImage, aMergeThreshold, aMinSize, oNewLabels);
	delete[] dims_int;

	// Convert the new int labels to double labels.
	for (int i=0; i<numElements; i++) {
		oNewLabels_double[i] = (double) oNewLabels[i];
	}
}
#endif