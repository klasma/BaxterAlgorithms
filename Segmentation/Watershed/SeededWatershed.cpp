#include "mex.h" // Matlab types and functions.
#include <cstddef>  // To get NULL.
#include <map>
#include <vector>

using namespace std;

/* AddTo2DImage adds a constant to a rectangular region of a 2D integer
 * image, which is stored in a single array of concatenated columns.
 *
 * Syntax:
 * void AddTo2DImage(int *im, int val,
 *      int i1, int i2, int iN,
 *      int j1, int j2)
 *
 * Inputs:
 * im - Pointer to the image array.
 *
 * val - Value that will be added to the rectangular region.
 *
 * i1 - First row index of the rectangular region.
 *
 * 12 - Last row index of the rectangular region.
 *
 * iN - Number of rows in the image.
 *
 * j1 - First column index in the rectangular region.
 *
 * j2 - Last column index in the rectangular region.
 */

void AddTo2DImage(int *im, int val,
        int i1, int i2, int iN,
        int j1, int j2) {
    
    for (int i=i1; i<=i2; i++) {  // Rows.
        for (int j=j1; j<=j2; j++) {  // Columns.
            im[i + j*iN] += val;
        }
    }
}

/* AddTo3DImage adds a constant to a box region of a 3D integer image,
 * which is stored in a single array of concatenated columns.
 *
 * Syntax:
 * void AddTo3DImage(int *im, int val,
 *      int i1, int i2, int iN,
 *      int j1, int j2, int jN,
 *      int k1, int k2) {
 *
 * Inputs:
 * im - Pointer to the image array.
 *
 * val - Value that will be added to the box region.
 *
 * i1 - First row index of the box region.
 *
 * 12 - Last row index of the box region.
 *
 * iN - Number of rows in the image.
 *
 * j1 - First column index in the box region.
 *
 * j2 - Last column index in the box region.
 *
 * jN - Number of columns in the box region.
 *
 * k1 - First slice in the box region.
 *
 * k2 - Last slice in the box region.
 */

void AddTo3DImage(int *im, int val,
        int i1, int i2, int iN,
        int j1, int j2, int jN,
        int k1, int k2) {
    
    for (int i=i1; i<=i2; i++) {  // Rows.
        for (int j=j1; j<=j2; j++) {  // Columns.
            for (int k=k1; k<=k2; k++) {  // Slices.
                im[i + j*iN + k*iN*jN] += val;
            }
        }
    }
}

/* SeededWatershed performs a seeded watershed transform.
 *
 * Syntax:
 * oIm = SeededWatershed(aIm, aSeeds)
 * oIm = SeededWatershed(aIm, aSeeds, aForeground)
 *
 * Inputs:
 * aIm - Gray scale double image that the watershed transform will be
 * applied to.
 *
 * aSeeds - Double matrix with labeled seed pixels. The seed labels are
 * should be integers and the background has to be zeros. There will be one
 * segmented object per seed.
 *
 * aForeground - Double matrix where where all foreground pixels are
 * ones and the background pixels are zeros. The waterhseds will not be
 * allowed to grow into the background pixels and seed pixels in the
 * background will disappear.
 *
 * Outputs:
 * oLabels - Label image where the background is zeros and the segmented
 * regions have the same label as the seed that they grew from.
 */

void mexFunction(
        int nlhs,               // Number of outputs.
        mxArray *plhs[],        // Array of output pointers.
        int nrhs,               // Number of inputs.
        const mxArray *prhs[])  // Array of input pointers.
{
    
    // Check the number of input and output arguments.
    if(nrhs != 2 && nrhs != 3) {
        mexErrMsgTxt("SeededWatershed takes either 2 or 3 input arguments.");
    }
    if(nlhs != 1) {
        mexErrMsgTxt("SeededWatershed gives only 1 output argument.");
    }
    
    // Inputs.
    double *aIm = mxGetPr(prhs[0]);
    double *aSeeds = mxGetPr(prhs[1]);
    
    // Number of pixels (or voxels) in the image.
    int n = (int) mxGetNumberOfElements(prhs[0]);
    
    // Background pixels or pixels that have been labeled already.
    bool *taken = new bool[n];
    if(nrhs == 2) {
        // There are no background pixels.
        for(int i=0; i<n; i++) {
            taken[i] = false;
        }
    }
    else {
        // There are background pixels that can not be included in segments.
        double *aForeground = mxGetPr(prhs[2]);
        for(int i=0; i<n; i++) {
            taken[i] = (aForeground[i] == 0.0);
        }
    }
    
    vector<int> **offsets = NULL;  // Offsets to pixel neighbors.
    int *neighborhoods = new int[n];
    for(int i=0; i<n; i++) {
        neighborhoods[i] = 0;
    }
    mwSize numDims = mxGetNumberOfDimensions(prhs[0]);  // Number of image dimensions.
    const mwSize *dims = mxGetDimensions(prhs[0]);  // Array of image dimensions.
    
    /* A pixel in the middle of a 2D image has 8 neighboring pixels, but if
     * the pixel is on the image border, the pixel can have different
     * numbers of neighbors and they can be located in different
     * directions. There are 16 different configurations, since there are
     * 4 independent binary choices of having neighbors above, below, to
     * the left and to the right. To keep track of these possibilities,
     * 16 vectors with pixel offsets are created. The variable OFFSETS
     * keeps pointers to the vectors and NEIGHBORHOODS is a matrix that
     * keeps track of which of the 16 different neighbor-configuration each
     * pixel in the original image has. To enable enumeration of the
     * different configurations, having neighbors above, below, to the left
     * and to the right is assigned the scores 1, 2, 4, and 8 respectively.
     * The configuration of a pixel is then found as the sum of that pixels
     * scores. Configuration P will then include an offset to the left if
     * the label P has a 4 in its binary representation. To find out what
     * offsets to include in each neighborhood, a 3x3 test image (SQUARE)
     * is created and labeled with the appropriate configuration indices.
     * As an example, if 1, 2, 4, and 8 are all included in either P or the
     * label on the top left pixel in SQUARE, then configuration P should
     * include an offset up and to the left. The same reasoning holds for
     * all pixels in SQUARE, except the center pixel. The algorithm is the
     * same in 3D, except that there are 26 neighbors instead of 8.
     */
    
    if(numDims == 2) {  // 2D image.
        // Generate a the image with neighbor-configurations.
        AddTo2DImage(neighborhoods, 1, 1, dims[0]-1, dims[0], 0, dims[1]-1);
        AddTo2DImage(neighborhoods, 2, 0, dims[0]-2, dims[0], 0, dims[1]-1);
        AddTo2DImage(neighborhoods, 4, 0, dims[0]-1, dims[0], 1, dims[1]-1);
        AddTo2DImage(neighborhoods, 8, 0, dims[0]-1, dims[0], 0, dims[1]-2);
        
        // Label a 3x3 test image that will be used to determine what
        // offsets to include in each neighbor-configuration.
        int square [9];
        for(int i=0; i<9; i++) {
            square[i] = 0;
        }
        AddTo2DImage(square, 1, 1, 2, 3, 0, 2);
        AddTo2DImage(square, 2, 0, 1, 3, 0, 2);
        AddTo2DImage(square, 4, 0, 2, 3, 1, 2);
        AddTo2DImage(square, 8, 0, 2, 3, 0, 1);
        
        // Define the 16 different offset configurations.
        offsets = new vector<int>*[16];
        for(int p=0;p<16;p++) {
            offsets[p] = new vector<int>();
            for (int i=-1; i<2; i++) {
                for (int j=-1; j<2; j++) {
                    if ((i!=0) | (j!=0)) {  // 8 connectivity.
//                  if (((i!=0)&&(j==0)) || ((i==0)&&(j!=0))) {  // 4 connectivity.
                        if ((square[(i+1) + (j+1)*3] | p) == 15) {
                            // 1, 2, 4, and 8 must all be present in the
                            // binary representation of p or square[i+j*3].
                            offsets[p]->push_back(i + j*dims[0]);
                        }
                    }
                }
            }
        }
        
//         // Check that the offsets are correct.
//         for(int p=0; p<16; p++) {
//             mexPrintf("Offset configuration %d the following %d offsets:\n", p, offsets[p]->size());
//             for(int j=0; j<(int)offsets[p]->size(); j++) {
//                 mexPrintf("%d ", offsets[p]->at(j));
//             }
//             mexPrintf("\n");
//         }
        
        // Allocate output.
        plhs[0] = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
    }
    else if(numDims == 3) {  // 3D image.
        // Generate a the image with neighbor-configurations.
        AddTo3DImage(neighborhoods, 1,  1, dims[0]-1, dims[0], 0, dims[1]-1, dims[1], 0, dims[2]-1);
        AddTo3DImage(neighborhoods, 2,  0, dims[0]-2, dims[0], 0, dims[1]-1, dims[1], 0, dims[2]-1);
        AddTo3DImage(neighborhoods, 4,  0, dims[0]-1, dims[0], 1, dims[1]-1, dims[1], 0, dims[2]-1);
        AddTo3DImage(neighborhoods, 8,  0, dims[0]-1, dims[0], 0, dims[1]-2, dims[1], 0, dims[2]-1);
        AddTo3DImage(neighborhoods, 16, 0, dims[0]-1, dims[0], 0, dims[1]-1, dims[1], 1, dims[2]-1);
        AddTo3DImage(neighborhoods, 32, 0, dims[0]-1, dims[0], 0, dims[1]-1, dims[1], 0, dims[2]-2);
                
        // Label a 3x3 test image that will be used to determine what
        // offsets to include in each neighbor-configuration.
        int qube [27];
        for(int i=0; i<27; i++) {
            qube[i] = 0;
        }
        AddTo3DImage(qube, 1,  1, 2, 3, 0, 2, 3, 0, 2);
        AddTo3DImage(qube, 2,  0, 1, 3, 0, 2, 3, 0, 2);
        AddTo3DImage(qube, 4,  0, 2, 3, 1, 2, 3, 0, 2);
        AddTo3DImage(qube, 8,  0, 2, 3, 0, 1, 3, 0, 2);
        AddTo3DImage(qube, 16, 0, 2, 3, 0, 2, 3, 1, 2);
        AddTo3DImage(qube, 32, 0, 2, 3, 0, 2, 3, 0, 1);
        
        // Define the 64 different offset configurations.
        offsets = new vector<int>*[64];
        for(int p=0;p<64;p++) {
            offsets[p] = new vector<int>();
            for (int i=-1; i<2; i++) {
                for (int j=-1; j<2; j++) {
                    for (int k=-1; k<2; k++) {
                        if ((i!=0)||(j!=0)||(k!=0)) {  // 27 connectivity.
//                             if (((i!=0)&&(j==0)&&(k==0)) || ((i==0)&&(j!=0)&&(k==0)) || ((i==0)&&(j==0)&&(k!=0))) {  // 6 connectivity.
                            if ((qube[(i+1) + (j+1)*3 + (k+1)*9] | p) == 63) {
                                // 1, 2, 4, 8, 16, and 32 must all be
                                // present in the binary representation of
                                // p or square[i+j*3].
                                offsets[p]->push_back(i + j*dims[0] + k*dims[0]*dims[1]);
                            }
                        }
                    }
                }
            }
        }
        
        // Allocate output.
        plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    }
    else {
        mexErrMsgTxt("SeededWatershed only works on 2D or 3D inputs.");
    }
    
    // Output.
    double *oLabels = mxGetPr(plhs[0]);  // Output image labels (initialized to 0).
    
    multimap<double,int> pixels;
    
    // Initialize the pixel map based on the seeds.
    for(int i=0; i<n; i++) {
        if(aSeeds[i] > 0 && !taken[i]) {  // TODO: Make it possible to have adjacent seeds.
            oLabels[i] = aSeeds[i];
            taken[i] = true;
            vector<int> *iOffsets = offsets[neighborhoods[i]];
            for(int j=0; j<(int)iOffsets->size(); j++) {
                int index = i + iOffsets->at(j);
                if(aSeeds[index] == 0.0 && !taken[index]) {
                    pixels.insert(pair<double,int>(aIm[index], index));
                    taken[index] = true;
                }
            }
        }
    }
    
    while(!pixels.empty()) {
        double neighbor = 0;
        bool isRidge = false;  // True if the pixel is adjacent to mulitple regions.
        multimap<double,int>::iterator it = pixels.begin();
        
        int i = (*it).second;
        pixels.erase(it);
        
        vector<int> *iOffsets = offsets[neighborhoods[i]];
        
        // Find all labeled neighbors.
        for(int j=0; j<(int)iOffsets->size(); j++) {
            int index = i + iOffsets->at(j);
            if(oLabels[index] > 0.0) {
                if(neighbor != 0.0 && neighbor != oLabels[index]) {
                    isRidge = true;
                    break;
                }
                neighbor = oLabels[index];
            }
        }
        
        // Label the pixel and non-labeled neighbors to the pixel map, if
        // if there is only one neighboring segment. Pixels are not put in
        // the pixel map unless they have labeled neighbors.
        if(!isRidge) {
            oLabels[i] = neighbor;
            for(int j=0; j<(int)iOffsets->size(); j++) {
                int index = i + iOffsets->at(j);
                if(!taken[index]) {
                    pixels.insert(pair<double,int>(aIm[index], index));
                    taken[index] = true;
                }
            }
        }
    }
    
    // Free dynamically allocated memory.
    delete[] taken;
    delete[] neighborhoods;
    if(numDims == 2) {  // 2D image.
        for(int p=0;p<16;p++) {
            delete offsets[p];
        }
    }
    else {  // 3D image.
        for(int p=0;p<64;p++) {
            delete offsets[p];
        }
    }
    delete[] offsets;
}