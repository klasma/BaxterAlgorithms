#ifndef REGION
#define REGION

#include <vector>

using namespace std;

// The Region class stores the indices and values of pixels in an image region. This is the base
// class for all different region types. The class keeps a cashed value of the the mean pixel
// intensity in the region, and a boolean variable that specifies whether or not the mean is up
// to date. The mean is not considered to be up to date if new pixels have been added since the
// last mean computation.
class Region {

public:
	Region();

	// Adds a pixel to the region.
	//
	// Inputs:
	// aPixel - Index of the pixel in the image.
	//
	// aValue - Intensity value of the pixel in the image.
	//
	// Return value:
	// Index of the pixel in the image.
	void AddPixel(int aPixel, double aValue);

	// Returns the mean pixel intensity in the region.
	double Mean();

	// Merges the region aRegion into the current region by copying the pixels in aRegion and
	// appending them to the pixel list of the current region. The pixels are not removed from
	// aRegion.
	void Merge(Region *aRegion);

	// Returns the number of pixels in the pixel list.
	int GetNumPixels() { return (int) mPixels.size(); }

	// Returns the image index of pixel aIndex in the pixel list.
	//
	// Inputs:
	// aIndex - Index of the pixel in the region.
	//
	// Return value:
	// Index of the pixel in the image.
	int GetPixel(int aIndex) { return mPixels[aIndex]; }

	// Returns the image intensity of pixel aIndex in the region.
	//
	// Inputs:
	// aIndex - Index of the pixel in the region.
	//
	// Return value:
	// Intensity value of the pixel in the image.
	double GetValue(int aIndex) {return mValues[aIndex]; }

private:
	double mMean;				// Cahsed mean value or zero if the mean has not been computed.
								// The chashed value might not be up to date.
	bool mMeanUpToDate;			// True if there is an up to date chashed mean value stored.
	vector<int> mPixels;		// Image indices of all pixels in the region.
	vector<double> mValues;		// Image values of all pixels in the region.
};
#endif