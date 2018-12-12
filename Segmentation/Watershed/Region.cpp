#include "Region.h"

Region::Region() : mMeanUpToDate(false), mMean(0) {}

void Region::AddPixel(int aPixel, double aValue) {
	mPixels.push_back(aPixel);
	mValues.push_back(aValue);
	mMeanUpToDate = false;
}

double Region::Mean() {
	if (!mMeanUpToDate) {
		// If the mean has not been computed before or if new pixels have been added since the last
		// computation, the mean needs to be recomputed.
		double sum = 0;
		for (int i=0; i<GetNumPixels(); i++) {
			sum += GetValue(i);
		}
		mMean = sum / (double) GetNumPixels();
		mMeanUpToDate = true;
	}
	return mMean;
}

void Region::Merge(Region *aRegion) {
	for (int i=0; i<aRegion->GetNumPixels(); i++) {
		AddPixel(aRegion->GetPixel(i), aRegion->GetValue(i));
	}
}