/* MergeSegments takes a label image produced by a watershed transform and merges waterhseds
 * where the border between the waterhsheds has a score below a threshold.
 *
 * The score is computed as the average border intensity divided by the minimum of the two
 * mean intensities of the watersheds. The waterhsed borders are removed one by one, starting
 * with the border with the lowest score until all borders have a score above the threshold.
 * All images are stored as int or double arrays with a single index. In a 2D image, the columns
 * are concatenated into an array. In 3D, every z-plane is concatenated in this way, and then the
 * z-planes themselves are concatenated into a single array. This means that higher image
 * image dimensions take precedence over lower image dimensions in the voxel ordering. Zero pixels
 * in the label image must border at least 2 labeled regions. It is not allowed to have continuous
 * background regions of zeros. The new segment labels will be ordered accoring to the lowest
 * original label that were merged into them.
 * 
 * Inputs:
 * aNumDims - Number of dimensions in the image. Can be either 2 or 3.
 *
 * aDims - Array of length aNumDims, with the number of voxels in each dimension.
 *
 * aLabels - Array with region labels. The ridge voxels are 0.
 *
 * aImage - Gray scale image that was used to produce the watershed transform.
 *
 * aMergeThreshold - Score threshold below which the waterhseds will be merged.
 *
 * aNewLabels - Array with region labels for the merged regions. The ridge voxels are 0.
 */


void MergeSegments(int aNumDims, const int *aDims, const int *aLabels, const double *aImage, double aMergeThreshold, int aMinSize, int *aNewLabels);